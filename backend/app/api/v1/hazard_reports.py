import uuid
from datetime import datetime, timezone
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from backend.app.core.database import get_db
from backend.app.core.rbac import get_current_user, get_optional_current_user, require_role
from backend.app.models.entities import HazardReport, User, Pole, AuditLog, Alert, Incident
from backend.app.schemas.hazard_report import (
    HazardReportCreate,
    HazardReportStatusUpdate,
    HazardReportAssign,
    HazardReportOut
)
from backend.app.core.websocket import ws_manager

router = APIRouter(prefix="/hazard-reports", tags=["Citizen Hazard Reports & Lifecycle"])

VALID_STATUS_FLOW = {
    "REPORTED": ["UNDER_REVIEW", "REJECTED", "VERIFIED"],
    "UNDER_REVIEW": ["VERIFIED", "REJECTED", "ASSIGNED"],
    "VERIFIED": ["ASSIGNED", "REJECTED"],
    "ASSIGNED": ["ACKNOWLEDGED", "IN_PROGRESS", "REJECTED"],
    "ACKNOWLEDGED": ["IN_PROGRESS", "RESOLVED"],
    "IN_PROGRESS": ["RESOLVED", "UNDER_REVIEW"],
    "RESOLVED": ["CLOSED", "IN_PROGRESS"],
    "REJECTED": ["UNDER_REVIEW"],
    "CLOSED": []
}


@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED, summary="Submit Citizen Hazard Report")
async def create_hazard_report(
    report_in: HazardReportCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user)
):
    """
    Submits a real hazard report from the mobile app (phone camera/gallery photo, GPS coordinates).
    The report enters the system with status 'REPORTED'.
    """
    report_id = f"REP-{uuid.uuid4().hex[:6].upper()}"
    now = datetime.now(timezone.utc)

    # Resolve pole if given
    pole_ref = None
    if report_in.pole_id:
        res = await db.execute(select(Pole).where(Pole.id == report_in.pole_id))
        pole = res.scalar_one_or_none()
        if pole:
            pole_ref = pole.id

    new_report = HazardReport(
        id=report_id,
        reporter_id=current_user.id if current_user else None,
        reporter_name=report_in.reporter_name or (current_user.full_name if current_user else "Citizen"),
        reporter_phone=report_in.reporter_phone,
        pole_id=pole_ref,
        latitude=report_in.latitude,
        longitude=report_in.longitude,
        address=report_in.address,
        hazard_type=report_in.hazard_type,
        description=report_in.description,
        image_url=report_in.image_url,
        status="REPORTED",
        created_at=now,
        updated_at=now
    )
    db.add(new_report)

    # Create matching system alert
    alt_id = f"ALT-{uuid.uuid4().hex[:6].upper()}"
    alert = Alert(
        id=alt_id,
        pole_id=pole_ref or "UNASSIGNED",
        severity="MEDIUM",
        alert_type="CITIZEN_HAZARD_REPORT",
        message=f"[{report_in.hazard_type}] {report_in.description}",
        status="NEW",
        created_at=now
    )
    db.add(alert)

    # Log audit entry
    audit = AuditLog(
        user_id=current_user.id if current_user else None,
        action="HAZARD_REPORTED",
        target_entity=f"Report {report_id} (Pole: {pole_ref or 'Nearby'})",
        details=f"Hazard Type: {report_in.hazard_type} | Photo: {'Yes' if report_in.image_url else 'None'}"
    )
    db.add(audit)
    await db.commit()
    await db.refresh(new_report)

    # Broadcast via WebSocket to municipal operations desk
    try:
        await ws_manager.broadcast_alert({
            "event": "NEW_HAZARD_REPORT",
            "report_id": report_id,
            "pole_id": pole_ref,
            "hazard_type": report_in.hazard_type,
            "severity": "WARNING",
            "status": "REPORTED",
            "has_photo": bool(report_in.image_url),
            "timestamp": now.isoformat()
        })
    except Exception:
        pass

    return {
        "success": True,
        "report_id": report_id,
        "status": "REPORTED",
        "data": HazardReportOut.model_validate(new_report).model_dump(),
        "message": f"Hazard report {report_id} submitted successfully. Assigned to municipal dispatch desk."
    }


@router.get("", response_model=dict, summary="List Hazard Reports")
async def list_hazard_reports(
    status_filter: Optional[str] = Query(None, alias="status"),
    pole_id: Optional[str] = None,
    technician_id: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db)
):
    """Lists submitted citizen reports with status, pole, and technician filtering."""
    query = select(HazardReport).order_by(desc(HazardReport.created_at)).limit(limit)
    if status_filter:
        query = query.where(HazardReport.status == status_filter.upper())
    if pole_id:
        query = query.where(HazardReport.pole_id == pole_id)
    if technician_id:
        query = query.where(HazardReport.assigned_technician_id == technician_id)

    res = await db.execute(query)
    reports = res.scalars().all()

    return {
        "success": True,
        "count": len(reports),
        "data": [HazardReportOut.model_validate(r).model_dump() for r in reports],
        "message": "Hazard reports retrieved."
    }


@router.get("/{report_id}", response_model=dict, summary="Get Single Hazard Report Details")
async def get_hazard_report(report_id: str, db: AsyncSession = Depends(get_db)):
    """Retrieves full details of a specific citizen hazard report."""
    res = await db.execute(select(HazardReport).where(HazardReport.id == report_id))
    report = res.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hazard report '{report_id}' was not found."
        )

    return {
        "success": True,
        "data": HazardReportOut.model_validate(report).model_dump(),
        "message": "Hazard report details retrieved."
    }


@router.patch("/{report_id}/status", response_model=dict, summary="Update Report Lifecycle Status")
async def update_hazard_report_status(
    report_id: str,
    payload: HazardReportStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user)
):
    """
    Progresses report through its lifecycle:
    REPORTED -> UNDER_REVIEW -> VERIFIED/REJECTED -> ASSIGNED -> ACKNOWLEDGED -> IN_PROGRESS -> RESOLVED -> CLOSED.
    Allows attaching inspection notes and verification photos.
    """
    res = await db.execute(select(HazardReport).where(HazardReport.id == report_id))
    report = res.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail=f"Hazard report '{report_id}' not found.")

    target_status = payload.status.upper()
    now = datetime.now(timezone.utc)

    # Update fields
    report.status = target_status
    report.updated_at = now
    if payload.notes:
        existing_notes = f"{report.inspection_notes}\n" if report.inspection_notes else ""
        report.inspection_notes = f"{existing_notes}[{now.strftime('%Y-%m-%d %H:%M:%S UTC')}] {payload.notes}".strip()
    if payload.inspection_image_url:
        report.inspection_image_url = payload.inspection_image_url

    audit = AuditLog(
        user_id=current_user.id if current_user else None,
        action="HAZARD_STATUS_UPDATED",
        target_entity=f"Report {report_id}",
        details=f"Status changed to {target_status}. Notes: {payload.notes or 'None'}"
    )
    db.add(audit)
    await db.commit()
    await db.refresh(report)

    return {
        "success": True,
        "report_id": report.id,
        "new_status": report.status,
        "data": HazardReportOut.model_validate(report).model_dump(),
        "message": f"Hazard report {report_id} status updated to {target_status}."
    }


@router.post("/{report_id}/assign", response_model=dict, summary="Assign Report to Technician")
async def assign_hazard_report(
    report_id: str,
    payload: HazardReportAssign,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["ENGINEER", "ADMIN"]))
):
    """Engineer/Admin endpoint to assign a hazard report to a specific field technician."""
    res = await db.execute(select(HazardReport).where(HazardReport.id == report_id))
    report = res.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail=f"Hazard report '{report_id}' not found.")

    # Verify technician
    tech_res = await db.execute(select(User).where(User.id == payload.technician_id))
    technician = tech_res.scalar_one_or_none()
    if not technician:
        raise HTTPException(status_code=404, detail=f"Technician '{payload.technician_id}' not found.")

    now = datetime.now(timezone.utc)
    report.assigned_technician_id = technician.id
    report.status = "ASSIGNED"
    report.updated_at = now
    if payload.notes:
        report.inspection_notes = f"Assignment Note: {payload.notes}"

    audit = AuditLog(
        user_id=current_user.id,
        action="HAZARD_REPORT_ASSIGNED",
        target_entity=f"Report {report_id}",
        details=f"Assigned to {technician.full_name} ({technician.id})"
    )
    db.add(audit)
    await db.commit()
    await db.refresh(report)

    return {
        "success": True,
        "report_id": report.id,
        "assigned_technician": technician.full_name,
        "status": "ASSIGNED",
        "data": HazardReportOut.model_validate(report).model_dump(),
        "message": f"Report {report_id} assigned to technician {technician.full_name}."
    }
