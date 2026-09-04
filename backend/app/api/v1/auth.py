import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.core.database import get_db
from backend.app.core.security import hash_password, verify_password, create_access_token
from backend.app.core.rbac import get_current_user
from backend.app.models.entities import User, AuditLog
from backend.app.schemas.auth import UserRegisterIn, UserLoginIn, TokenResponse, UserOut

router = APIRouter(prefix="/auth", tags=["Authentication & RBAC"])


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register New User"
)
async def register(user_in: UserRegisterIn, db: AsyncSession = Depends(get_db)):
    """Registers a new user and returns JWT token with assigned role."""
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
            detail=f"Invalid role. Must be one of: {valid_roles}",
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
    """Authenticates credentials and returns a signed JWT."""
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
            detail="Your account has been deactivated. Contact an administrator.",
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
            {"role": "CITIZEN", "description": "Public hazard alerts, safe/warning status, report hazards"},
            {"role": "TECHNICIAN", "description": "Field inspections, work orders, acknowledge/inspect/resolve"},
            {"role": "ENGINEER", "description": "Pole health monitoring, AI anomaly review, tech dispatching"},
            {"role": "AUTHORITY", "description": "Area safety indices, emergency escalation review"},
            {"role": "ADMIN", "description": "User/pole management, threshold tuning, judge demo mode"},
        ]
    }
