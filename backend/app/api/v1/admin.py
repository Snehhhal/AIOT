from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from backend.app.core.database import get_db
from backend.app.core.rbac import require_role
from backend.app.core.config import settings
from backend.app.models.entities import User, AuditLog, Pole
from backend.app.schemas.auth import UserOut

router = APIRouter(prefix="/admin", tags=["Admin Management & System Control"])


@router.get("/users", response_model=dict, summary="List All Users (Admin)")
async def list_users(
    current_user: User = Depends(require_role(["ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Admin endpoint: Fetches all platform users and their assigned RBAC roles."""
    result = await db.execute(select(User).order_by(User.created_at))
    users = result.scalars().all()

    return {
        "success": True,
        "count": len(users),
        "data": [UserOut.model_validate(u).model_dump() for u in users],
        "message": "User registry retrieved successfully."
    }


@router.post("/users/{user_id}/toggle-active", response_model=dict, summary="Activate/Deactivate User (Admin)")
async def toggle_user_active(
    user_id: str,
    current_user: User = Depends(require_role(["ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Admin endpoint: Enables or disables user login access."""
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    if not target_user:
        raise HTTPException(status_code=404, detail=f"User {user_id} not found.")

    target_user.is_active = not target_user.is_active
    db.add(AuditLog(
        user_id=current_user.id,
        action="USER_TOGGLE_ACTIVE",
        target_entity=f"User {target_user.email}",
        details=f"New active status: {target_user.is_active}"
    ))
    await db.commit()

    return {
        "success": True,
        "data": {"user_id": user_id, "is_active": target_user.is_active},
        "message": f"User {target_user.email} is now {'active' if target_user.is_active else 'deactivated'}."
    }


@router.get("/audit-logs", response_model=dict, summary="List System Audit Logs (Admin)")
async def list_audit_logs(
    limit: int = 50,
    current_user: User = Depends(require_role(["ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Admin endpoint: Retrieves security and operational audit trail."""
    result = await db.execute(select(AuditLog).order_by(desc(AuditLog.timestamp)).limit(limit))
    logs = result.scalars().all()

    return {
        "success": True,
        "count": len(logs),
        "data": [
            {
                "id": log.id,
                "user_id": log.user_id,
                "action": log.action,
                "target_entity": log.target_entity,
                "details": log.details,
                "timestamp": log.timestamp.isoformat() if log.timestamp else None
            }
            for log in logs
        ],
        "message": "Audit logs retrieved."
    }


@router.get("/system-config", response_model=dict, summary="Get System Configuration (Admin)")
async def get_system_config(
    current_user: User = Depends(require_role(["ADMIN"]))
):
    """Admin endpoint: Displays core platform settings and safety parameters."""
    return {
        "success": True,
        "data": {
            "app_name": settings.APP_NAME,
            "environment": settings.APP_ENV,
            "simulation_mode": settings.SIMULATION_MODE,
            "leakage_advisory_threshold_ma": 10.0,
            "leakage_critical_threshold_ma": 30.0,
            "tilt_danger_threshold_deg": 15.0,
            "iec_standard": "IEC 60479-1:2018 (Effects of current on human beings)",
            "statutory_sop": "Central Electricity Authority (Safety Requirements) Regulations 2010"
        },
        "message": "System safety configuration parameters."
    }
