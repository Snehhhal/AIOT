from typing import List
from fastapi import APIRouter
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
async def list_alerts():
    return {
        "success": True,
        "data": SAMPLE_ALERTS,
        "message": "Alerts fetched successfully"
    }


@router.post("/{alert_id}/acknowledge", response_model=dict, summary="Acknowledge Alert")
async def acknowledge_alert(alert_id: str):
    return {
        "success": True,
        "data": {"alert_id": alert_id, "status": "ACKNOWLEDGED"},
        "message": f"Alert {alert_id} acknowledged by field operator"
    }


@router.post("/{alert_id}/resolve", response_model=dict, summary="Resolve Alert")
async def resolve_alert(alert_id: str):
    return {
        "success": True,
        "data": {"alert_id": alert_id, "status": "RESOLVED"},
        "message": f"Alert {alert_id} marked as resolved"
    }
