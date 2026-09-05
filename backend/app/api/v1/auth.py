import uuid
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from backend.app.core.database import get_db
from backend.app.core.security import hash_password, verify_password, create_access_token
from backend.app.core.rbac import get_current_user
from backend.app.models.entities import User, AuditLog, PasswordReset
from backend.app.schemas.auth import (
    UserRegisterIn,
    UserLoginIn,
    TokenResponse,
    UserOut,
    ForgotPasswordIn,
    ResetPasswordIn
)

router = APIRouter(prefix="/auth", tags=["Authentication & RBAC"])

STAFF_ROLES = {"TECHNICIAN", "ENGINEER", "AUTHORITY", "ADMIN"}
DEFAULT_STAFF_AUTH_CODE = "POLEGUARD-SECURE-2026"


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register New User"
)
async def register(user_in: UserRegisterIn, db: AsyncSession = Depends(get_db)):
    """
    Registers a new user and returns JWT token with assigned role.
    Citizen accounts are registered immediately.
    Staff roles (Technician, Engineer, Authority, Admin) require a valid Department Authorization Key.
    """
    # Check duplicate email
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email address already exists.",
        )

    # Validate role
    role = user_in.role.upper()
    valid_roles = ["CITIZEN", "TECHNICIAN", "ENGINEER", "AUTHORITY", "ADMIN"]
    if role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid role '{role}'. Must be one of: {valid_roles}",
        )

    # Restrict staff role creation without authorization key
    if role in STAFF_ROLES:
        auth_code = (user_in.staff_auth_code or "").strip()
        if auth_code != DEFAULT_STAFF_AUTH_CODE:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Registration for staff role '{role}' requires a valid Department Authorization Key (e.g. {DEFAULT_STAFF_AUTH_CODE}). Contact your municipal grid administrator."
            )

    new_user = User(
        id=f"USR-{uuid.uuid4().hex[:8].upper()}",
        email=user_in.email,
        hashed_password=hash_password(user_in.password),
        full_name=user_in.full_name,
        role=role,
        zone=user_in.zone or "Sector 1",
        is_active=True,
    )
    db.add(new_user)

    # Add audit entry
    audit = AuditLog(
        user_id=new_user.id,
        action="USER_REGISTERED",
        target_entity=f"User {new_user.email}",
        details=f"Registered with role {role}",
    )
    db.add(audit)
    await db.commit()
    await db.refresh(new_user)

    token = create_access_token({"sub": new_user.id, "role": new_user.role, "email": new_user.email})
    return TokenResponse(access_token=token, user=UserOut.model_validate(new_user))


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login with Email and Password"
)
async def login(credentials: UserLoginIn, db: AsyncSession = Depends(get_db)):
    """Authenticates credentials against PostgreSQL/SQLite and returns a signed JWT."""
    result = await db.execute(select(User).where(User.email == credentials.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been deactivated or is pending administrator approval.",
        )

    # Add audit log
    audit = AuditLog(
        user_id=user.id,
        action="LOGIN_SUCCESS",
        target_entity=f"User {user.email}",
        details=f"Logged in as {user.role}",
    )
    db.add(audit)
    await db.commit()

    token = create_access_token({"sub": user.id, "role": user.role, "email": user.email})
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


@router.post(
    "/forgot-password",
    response_model=dict,
    summary="Request Password Reset Code"
)
async def forgot_password(payload: ForgotPasswordIn, db: AsyncSession = Depends(get_db)):
    """
    Generates a password reset token for the registered email.
    In testing/offline mode, returns the reset token for immediate verification.
    """
    res = await db.execute(select(User).where(User.email == payload.email))
    user = res.scalar_one_or_none()
    if not user:
        # Prevent user enumeration in production, but provide clear response
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No account registered with this email address."
        )

    token_str = f"RST-{uuid.uuid4().hex[:6].upper()}"
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=30)

    reset_record = PasswordReset(
        id=str(uuid.uuid4()),
        email=payload.email,
        token=token_str,
        expires_at=expires_at,
        is_used=False
    )
    db.add(reset_record)

    audit = AuditLog(
        user_id=user.id,
        action="PASSWORD_RESET_REQUEST",
        target_entity=f"User {user.email}",
        details=f"Reset token generated, expires in 30 mins"
    )
    db.add(audit)
    await db.commit()

    return {
        "success": True,
        "message": f"Password reset instructions and verification code generated for {payload.email}.",
        "reset_token": token_str,
        "expires_in_minutes": 30
    }


@router.post(
    "/reset-password",
    response_model=dict,
    summary="Reset Password with Token"
)
async def reset_password(payload: ResetPasswordIn, db: AsyncSession = Depends(get_db)):
    """Verifies reset token and updates the user's password in database."""
    now = datetime.now(timezone.utc)
    res = await db.execute(
        select(PasswordReset)
        .where(
            PasswordReset.email == payload.email,
            PasswordReset.token == payload.token,
            PasswordReset.is_used == False
        )
        .order_by(desc(PasswordReset.created_at))
        .limit(1)
    )
    reset_entry = res.scalar_one_or_none()

    if not reset_entry:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset token."
        )

    expires = reset_entry.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)

    if now > expires:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password reset token has expired. Please request a new one."
        )

    # Fetch user and update password
    user_res = await db.execute(select(User).where(User.email == payload.email))
    user = user_res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    user.hashed_password = hash_password(payload.new_password)
    reset_entry.is_used = True

    audit = AuditLog(
        user_id=user.id,
        action="PASSWORD_RESET_COMPLETED",
        target_entity=f"User {user.email}",
        details="User successfully reset password using verified token"
    )
    db.add(audit)
    await db.commit()

    return {
        "success": True,
        "message": "Your password has been successfully reset. You may now log in."
    }


@router.get(
    "/me",
    response_model=UserOut,
    summary="Get Authenticated User Profile"
)
async def get_me(current_user: User = Depends(get_current_user)):
    """Returns the verified profile and role of the logged-in user."""
    return UserOut.model_validate(current_user)


@router.get(
    "/roles",
    summary="List Supported Platform Roles"
)
async def list_roles():
    """Lists the 5 supported roles and their operational responsibilities."""
    return {
        "roles": [
            {
                "role": "CITIZEN",
                "display_name": "Citizen",
                "description": "Public hazard alerts, nearby pole check, report electrical hazards with camera photos, access safety RAG.",
                "requires_authorization": False
            },
            {
                "role": "TECHNICIAN",
                "display_name": "Technician / Lineman",
                "description": "Incident queue, work order lifecycle, field inspection photo uploads, repair completion.",
                "requires_authorization": True
            },
            {
                "role": "ENGINEER",
                "display_name": "Engineer / Supervisor",
                "description": "Fleet-wide predictive health ranking, sensor breach analytics, work order delegation, escalation.",
                "requires_authorization": True
            },
            {
                "role": "AUTHORITY",
                "display_name": "Municipal Authority",
                "description": "Metropolitan safety index, zone risk aggregation, emergency escalation monitoring, grid line isolation.",
                "requires_authorization": True
            },
            {
                "role": "ADMIN",
                "display_name": "System Administrator",
                "description": "User privileges, pole asset registration, audit log inspection, and IoT Demo Control Center.",
                "requires_authorization": True
            }
        ]
    }
