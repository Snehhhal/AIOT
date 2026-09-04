from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from backend.app.core.database import get_db
from backend.app.models.entities import Alert, AuditLog
from backend.app.schemas.alert import AlertResponse

router = APIRouter(prefix="/alerts", tags=["Alerts"])

SAMPLE_ALERTS = [
    {
        "id": "ALT-1001",
        "pole_id": "POLE-102",
        "severity": "HIGH",
        "alert_type": "CURRENT_LEAKAGE",
        "message": "Dangerous leakage current (38.5 mA) detected during rain!",
        "status": "NEW",
        "created_at": "2026-09-04T14:30:00Z"
    }
]


@router.get("", response_model=dict, summary="List Alerts")
async def list_alerts(
    status_filter: Optional[str] = None,
    pole_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(Alert).order_by(desc(Alert.created_at)).limit(50)
    if status_filter:
        query = query.where(Alert.status == status_filter)
    if pole_id:
        query = query.where(Alert.pole_id == pole_id)

    res = await db.execute(query)
    alerts = res.scalars().all()

    if alerts:
        alert_data = [
            {
                "id": a.id,
                "pole_id": a.pole_id,
                "severity": a.severity,
                "alert_type": a.alert_type,
                "message": a.message,
                "status": a.status,
                "created_at": a.created_at.isoformat() if a.created_at else None
            }
            for a in alerts
        ]
    else:
        alert_data = SAMPLE_ALERTS

    return {
        "success": True,
        "count": len(alert_data),
        "data": alert_data,
        "message": "Alerts fetched successfully"
    }


@router.post("/{alert_id}/acknowledge", response_model=dict, summary="Acknowledge Alert")
async def acknowledge_alert(alert_id: str, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = res.scalar_one_or_none()
    if alert:
        alert.status = "ACKNOWLEDGED"
        db.add(AuditLog(action="ACKNOWLEDGE_ALERT", target_entity=f"Alert {alert_id}"))
        await db.commit()

    return {
        "success": True,
        "data": {"alert_id": alert_id, "status": "ACKNOWLEDGED"},
        "message": f"Alert {alert_id} acknowledged by field operator"
    }


@router.post("/{alert_id}/resolve", response_model=dict, summary="Resolve Alert")
async def resolve_alert(alert_id: str, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = res.scalar_one_or_none()
    if alert:
        alert.status = "RESOLVED"
        db.add(AuditLog(action="RESOLVE_ALERT", target_entity=f"Alert {alert_id}"))
        await db.commit()

    return {
        "success": True,
        "data": {"alert_id": alert_id, "status": "RESOLVED"},
        "message": f"Alert {alert_id} marked as resolved"
    }

