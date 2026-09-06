from datetime import datetime, timezone
import uuid
from typing import List, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from backend.app.core.database import get_db
from backend.app.core.rbac import require_role
from backend.app.models.entities import Incident, WorkOrder, Alert, Pole, AuditLog, User
from backend.app.schemas.incident import (
    IncidentResponse,
    IncidentAssign,
    IncidentUpdateStatus,
    WorkOrderResponse,
    CitizenReportCreate
)
from backend.app.core.websocket import ws_manager

router = APIRouter(tags=["Incidents, Work Orders & Role Operations"])


class GridCutoffIn(BaseModel):
    pole_id: str = Field(..., description="Target utility pole ID")
    reason: str = Field("Emergency grid cutoff ordered due to critical electrical hazard", description="Operational rationale")


@router.get("/incidents", response_model=dict, summary="List Incidents")
async def list_incidents(
    status_filter: Optional[str] = Query(None, alias="status"),
    severity_filter: Optional[str] = Query(None, alias="severity"),
    pole_id: Optional[str] = None,
    limit: int = 50,
    db: AsyncSession = Depends(get_db)
):
    """Fetches operational safety incidents from the database with filtering."""
    query = select(Incident).order_by(desc(Incident.created_at)).limit(limit)
    if status_filter:
        query = query.where(Incident.status == status_filter)
    if severity_filter:
        query = query.where(Incident.severity == severity_filter)
    if pole_id:
        query = query.where(Incident.pole_id == pole_id)

    result = await db.execute(query)
    incidents = result.scalars().all()

    return {
        "success": True,
        "count": len(incidents),
        "data": [IncidentResponse.model_validate(inc).model_dump() for inc in incidents],
        "message": "Incidents fetched successfully."
    }


@router.get("/incidents/escalations", response_model=dict, summary="List Critical & Emergency Escalations (Authority/Admin)")
async def list_escalations(
    current_user: User = Depends(require_role(["AUTHORITY", "ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Authority/Admin endpoint: Returns unresolved CRITICAL and EMERGENCY incidents requiring executive oversight."""
    query = (
        select(Incident)
        .where(
            Incident.severity.in_(["CRITICAL", "EMERGENCY"]),
            Incident.status.notin_(["RESOLVED", "CLOSED"])
        )
        .order_by(desc(Incident.created_at))
    )
    result = await db.execute(query)
    escalations = result.scalars().all()

    return {
        "success": True,
        "count": len(escalations),
        "data": [IncidentResponse.model_validate(e).model_dump() for e in escalations],
        "message": f"Found {len(escalations)} active high-priority escalations."
    }


@router.get("/incidents/{incident_id}", response_model=dict, summary="Get Incident Details")
async def get_incident(incident_id: str, db: AsyncSession = Depends(get_db)):
    """Fetches details of a specific incident and any active work orders."""
    res = await db.execute(select(Incident).where(Incident.id == incident_id))
    inc = res.scalar_one_or_none()
    if not inc:
        raise HTTPException(status_code=404, detail=f"Incident {incident_id} not found.")

    wo_res = await db.execute(select(WorkOrder).where(WorkOrder.incident_id == incident_id))
    work_orders = wo_res.scalars().all()

    return {
        "success": True,
        "data": {
            "incident": IncidentResponse.model_validate(inc).model_dump(),
            "work_orders": [WorkOrderResponse.model_validate(w).model_dump() for w in work_orders]
        },
        "message": "Incident details retrieved."
    }


@router.post("/incidents/{incident_id}/assign", response_model=dict, summary="Assign Incident to Technician (Engineer/Admin)")
async def assign_incident(
    incident_id: str,
    assign_data: IncidentAssign,
    current_user: User = Depends(require_role(["ENGINEER", "ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Engineer/Admin endpoint: Assigns an incident to a technician and creates a tracked work order."""
    res = await db.execute(select(Incident).where(Incident.id == incident_id))
    inc = res.scalar_one_or_none()
    if not inc:
        raise HTTPException(status_code=404, detail=f"Incident {incident_id} not found.")

    inc.status = "ASSIGNED"

    # Create or update WorkOrder
    wo_res = await db.execute(select(WorkOrder).where(WorkOrder.incident_id == incident_id))
    work_order = wo_res.scalar_one_or_none()
    now = datetime.now(timezone.utc)

    if not work_order:
        work_order = WorkOrder(
            id=f"WO-{uuid.uuid4().hex[:8]}",
            incident_id=incident_id,
            technician_id=assign_data.technician_id,
            status="ASSIGNED",
            notes=assign_data.notes,
            created_at=now,
            updated_at=now
        )
        db.add(work_order)
    else:
        work_order.technician_id = assign_data.technician_id
        work_order.status = "ASSIGNED"
        if assign_data.notes:
            work_order.notes = assign_data.notes
        work_order.updated_at = now

    audit = AuditLog(
        user_id=current_user.id,
        action="ASSIGN_INCIDENT",
        target_entity=f"Incident {incident_id}",
        details=f"Assigned by {current_user.email} to technician {assign_data.technician_id}"
    )
    db.add(audit)

    await db.commit()

    return {
        "success": True,
        "data": {
            "incident_id": incident_id,
            "status": "ASSIGNED",
            "technician_id": assign_data.technician_id,
            "work_order_id": work_order.id
        },
        "message": f"Incident {incident_id} successfully assigned to technician {assign_data.technician_id}."
    }


@router.post("/incidents/{incident_id}/acknowledge", response_model=dict, summary="Acknowledge Incident (Technician/Admin)")
async def acknowledge_incident(
    incident_id: str,
    current_user: User = Depends(require_role(["TECHNICIAN", "ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Technician/Admin endpoint: Acknowledges receipt of assigned incident."""
    res = await db.execute(select(Incident).where(Incident.id == incident_id))
    inc = res.scalar_one_or_none()
    if not inc:
        raise HTTPException(status_code=404, detail=f"Incident {incident_id} not found.")

    now = datetime.now(timezone.utc)
    inc.status = "ACKNOWLEDGED"
    inc.acknowledged_at = now

    # Update associated work order
    wo_res = await db.execute(select(WorkOrder).where(WorkOrder.incident_id == incident_id))
    wo = wo_res.scalar_one_or_none()
    if wo:
        wo.status = "ACKNOWLEDGED"
        wo.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        action="ACKNOWLEDGE_INCIDENT",
        target_entity=f"Incident {incident_id}",
        details=f"Acknowledged by {current_user.email}"
    ))

    await db.commit()

    return {
        "success": True,
        "data": {"incident_id": incident_id, "status": "ACKNOWLEDGED", "acknowledged_at": now.isoformat()},
        "message": f"Incident {incident_id} acknowledged."
    }


@router.post("/incidents/{incident_id}/status", response_model=dict, summary="Update Incident Status & Add Notes (Technician/Admin)")
async def update_incident_status(
    incident_id: str,
    status_data: IncidentUpdateStatus,
    current_user: User = Depends(require_role(["TECHNICIAN", "ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Technician/Admin endpoint: Updates repair status (IN_PROGRESS, REPAIR_IN_PROGRESS, RESOLVED, CLOSED) and appends notes."""
    res = await db.execute(select(Incident).where(Incident.id == incident_id))
    inc = res.scalar_one_or_none()
    if not inc:
        raise HTTPException(status_code=404, detail=f"Incident {incident_id} not found.")

    now = datetime.now(timezone.utc)
    inc.status = status_data.status
    if status_data.status in ["RESOLVED", "CLOSED"]:
        inc.resolved_at = now
        inc.resolved_by = current_user.id

    # Update WorkOrder
    wo_res = await db.execute(select(WorkOrder).where(WorkOrder.incident_id == incident_id))
    wo = wo_res.scalar_one_or_none()
    if wo:
        wo.status = status_data.status
        if status_data.notes:
            existing_notes = wo.notes or ""
            wo.notes = f"{existing_notes}\n[{now.strftime('%H:%M:%S')}] {status_data.notes}".strip()
        wo.updated_at = now

    audit = AuditLog(
        user_id=current_user.id,
        action="UPDATE_INCIDENT_STATUS",
        target_entity=f"Incident {incident_id}",
        details=f"Updated to {status_data.status} by {current_user.email} | Notes: {status_data.notes or 'None'}"
    )
    db.add(audit)

    await db.commit()

    return {
        "success": True,
        "data": {
            "incident_id": incident_id,
            "status": inc.status,
            "resolved_at": inc.resolved_at.isoformat() if inc.resolved_at else None
        },
        "message": f"Incident {incident_id} status updated to {inc.status}."
    }


@router.get("/work-orders", response_model=dict, summary="List Work Orders")
async def list_work_orders(
    technician_id: Optional[str] = None,
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db)
):
    """Lists field maintenance work orders."""
    query = select(WorkOrder).order_by(desc(WorkOrder.updated_at))
    if technician_id:
        query = query.where(WorkOrder.technician_id == technician_id)
    if status_filter:
        query = query.where(WorkOrder.status == status_filter)

    result = await db.execute(query)
    work_orders = result.scalars().all()

    return {
        "success": True,
        "count": len(work_orders),
        "data": [WorkOrderResponse.model_validate(w).model_dump() for w in work_orders],
        "message": "Work orders retrieved successfully."
    }


@router.post("/authority/grid-cutoff", response_model=dict, summary="Remote Grid Cutoff (Authority/Admin)")
async def emergency_grid_cutoff(
    payload: GridCutoffIn,
    current_user: User = Depends(require_role(["AUTHORITY", "ADMIN"])),
    db: AsyncSession = Depends(get_db)
):
    """Authority/Admin endpoint: Executes emergency remote circuit isolation for a hazardous pole."""
    res = await db.execute(select(Pole).where(Pole.id == payload.pole_id))
    pole = res.scalar_one_or_none()
    if not pole:
        raise HTTPException(status_code=404, detail=f"Pole {payload.pole_id} not found.")

    # Trip the line: set pole to OFFLINE, risk mitigated
    pole.status = "OFFLINE"
    now = datetime.now(timezone.utc)

    db.add(AuditLog(
        user_id=current_user.id,
        action="EMERGENCY_GRID_CUTOFF",
        target_entity=f"Pole {pole.id}",
        details=f"Cutoff ordered by {current_user.email}. Reason: {payload.reason}"
    ))

    # Broadcast emergency power cutoff event over WebSockets
    try:
        await ws_manager.broadcast_alert({
            "event": "POWER_GRID_CUTOFF",
            "pole_id": pole.id,
            "status": "OFFLINE",
            "ordered_by": current_user.email,
            "reason": payload.reason,
            "timestamp": now.isoformat()
        })
    except Exception:
        pass

    await db.commit()

    return {
        "success": True,
        "data": {
            "pole_id": pole.id,
            "status": "OFFLINE",
            "ordered_by": current_user.email,
            "timestamp": now.isoformat()
        },
        "message": f"Emergency power grid cutoff order executed successfully for pole {pole.id}."
    }


@router.post("/citizen/report", response_model=dict, status_code=status.HTTP_201_CREATED, summary="Report Hazard (Citizen)")
async def citizen_report_hazard(report: CitizenReportCreate, db: AsyncSession = Depends(get_db)):
    """
    Citizen hazard reporting endpoint.
    Creates an incident and alert from public citizen reporting (sparking, leaning, wire down, waterlogging).
    """
    inc_id = f"INC-CIT-{uuid.uuid4().hex[:6].upper()}"
    alt_id = f"ALT-CIT-{uuid.uuid4().hex[:6].upper()}"
    now = datetime.now(timezone.utc)

    pole_res = await db.execute(select(Pole).where(Pole.id == report.pole_id))
    pole = pole_res.scalar_one_or_none()
    pole_ref = pole.id if pole else (report.pole_id or "POLE-CUSTOM")

    incident = Incident(
        id=inc_id,
        pole_id=pole_ref,
        severity="WARNING",
        status="DETECTED",
        description=f"Citizen Report on {report.pole_id}: {report.description} (Contact: {report.contact_phone or 'Anonymous'})",
        created_at=now
    )
    db.add(incident)

    alert = Alert(
        id=alt_id,
        pole_id=pole_ref,
        severity="WARNING",
        alert_type="CITIZEN_REPORT",
        message=incident.description,
        status="NEW",
        created_at=now
    )
    db.add(alert)

    audit = AuditLog(
        action="CITIZEN_REPORT",
        target_entity=f"Pole {pole_ref}",
        details=incident.description
    )
    db.add(audit)

    await db.commit()

    try:
        await ws_manager.broadcast_alert({
            "event": "CITIZEN_ALERT",
            "alert_id": alt_id,
            "incident_id": inc_id,
            "pole_id": pole_ref,
            "severity": "WARNING",
            "message": incident.description,
            "timestamp": now.isoformat()
        })
    except Exception:
        pass

    return {
        "success": True,
        "data": {
            "incident_id": inc_id,
            "alert_id": alt_id,
            "pole_id": pole_ref,
            "status": "DETECTED"
        },
        "message": "Citizen hazard report registered and dispatched to municipal electrical engineers."
    }


@router.get("/citizen/reports", response_model=dict, summary="List Citizen Reports")
async def list_citizen_reports(db: AsyncSession = Depends(get_db)):
    """Fetches public citizen reports logged in the system."""
    query = select(Incident).where(Incident.id.like("INC-CIT-%")).order_by(desc(Incident.created_at))
    result = await db.execute(query)
    reports = result.scalars().all()

    return {
        "success": True,
        "count": len(reports),
        "data": [IncidentResponse.model_validate(r).model_dump() for r in reports],
        "message": "Citizen reports retrieved."
    }
