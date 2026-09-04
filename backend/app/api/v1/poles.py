from datetime import datetime, timezone, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from backend.app.core.database import get_db
from backend.app.core.rbac import require_role
from backend.app.models.entities import Pole, SensorReading, User
from backend.app.schemas.pole import (
    PoleCreate,
    PoleResponse,
    SensorReadingOut,
    PoleHealthResponse,
    PoleRiskResponse
)

router = APIRouter(prefix="/poles", tags=["Pole Management & Sensor API"])


def _calculate_connectivity(last_heartbeat: datetime | None) -> str:
    """Considers a pole ONLINE if a reading was logged within the last 15 minutes."""
    if not last_heartbeat:
        return "OFFLINE"
    now = datetime.now(timezone.utc)
    if last_heartbeat.tzinfo is None:
        last_heartbeat = last_heartbeat.replace(tzinfo=timezone.utc)
    return "ONLINE" if (now - last_heartbeat) < timedelta(minutes=15) else "OFFLINE"


@router.get("", response_model=dict, summary="List All Registered Electric Poles")
async def list_poles(db: AsyncSession = Depends(get_db)):
    """Fetches all electric poles along with their latest sensor readings and connectivity."""
    result = await db.execute(select(Pole).order_by(Pole.id))
    poles = result.scalars().all()

    pole_list = []
    for p in poles:
        # Fetch latest reading for this pole
        r_result = await db.execute(
            select(SensorReading)
            .where(SensorReading.pole_id == p.id)
            .order_by(desc(SensorReading.recorded_at))
            .limit(1)
        )
        latest_reading = r_result.scalar_one_or_none()

        p_dict = {
            "id": p.id,
            "serial_number": p.serial_number,
            "name": p.name,
            "latitude": p.latitude,
            "longitude": p.longitude,
            "zone": p.zone,
            "status": p.status,
            "health_score": p.health_score,
            "risk_score": p.risk_score,
            "is_active": p.is_active,
            "connectivity": _calculate_connectivity(p.last_heartbeat),
            "last_heartbeat": p.last_heartbeat,
            "latest_reading": SensorReadingOut.model_validate(latest_reading) if latest_reading else None,
            "created_at": p.created_at,
        }
        pole_list.append(p_dict)

    return {
        "success": True,
        "count": len(pole_list),
        "data": pole_list,
        "message": "Poles fetched successfully"
    }


@router.get("/{pole_id}", response_model=dict, summary="Get Single Pole Details")
async def get_pole(pole_id: str, db: AsyncSession = Depends(get_db)):
    """Retrieves full specification, connectivity, and telemetry state for a specific pole."""
    result = await db.execute(select(Pole).where(Pole.id == pole_id))
    pole = result.scalar_one_or_none()
    if not pole:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pole '{pole_id}' was not found in the infrastructure registry."
        )

    r_result = await db.execute(
        select(SensorReading)
        .where(SensorReading.pole_id == pole.id)
        .order_by(desc(SensorReading.recorded_at))
        .limit(1)
    )
    latest_reading = r_result.scalar_one_or_none()

    data = {
        "id": pole.id,
        "serial_number": pole.serial_number,
        "name": pole.name,
        "latitude": pole.latitude,
        "longitude": pole.longitude,
        "zone": pole.zone,
        "status": pole.status,
        "health_score": pole.health_score,
        "risk_score": pole.risk_score,
        "is_active": pole.is_active,
        "connectivity": _calculate_connectivity(pole.last_heartbeat),
        "last_heartbeat": pole.last_heartbeat,
        "latest_reading": SensorReadingOut.model_validate(latest_reading) if latest_reading else None,
        "created_at": pole.created_at,
    }
    return {"success": True, "data": data, "message": "Pole found"}


@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED, summary="Register New Pole Asset")
async def create_pole(
    pole_in: PoleCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["ADMIN", "ENGINEER"]))
):
    """Admin/Engineer endpoint to register a new electric pole asset."""
    result = await db.execute(select(Pole).where(Pole.id == pole_in.id))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"A pole with ID '{pole_in.id}' already exists."
        )

    new_pole = Pole(
        id=pole_in.id,
        serial_number=pole_in.serial_number or f"PL-{pole_in.id}",
        name=pole_in.name,
        latitude=pole_in.latitude,
        longitude=pole_in.longitude,
        zone=pole_in.zone,
        status=pole_in.status,
        health_score=pole_in.health_score,
        risk_score=pole_in.risk_score,
        is_active=pole_in.is_active,
        last_heartbeat=datetime.now(timezone.utc),
    )
    db.add(new_pole)
    await db.commit()
    await db.refresh(new_pole)

    return {"success": True, "data": {"id": new_pole.id, "name": new_pole.name}, "message": f"Pole {new_pole.id} registered."}


@router.get("/{pole_id}/readings", response_model=dict, summary="Get Latest Sensor Reading for Pole")
async def get_latest_reading(pole_id: str, db: AsyncSession = Depends(get_db)):
    """Fetches the most recent sensor reading packet received for this pole."""
    result = await db.execute(
        select(SensorReading)
        .where(SensorReading.pole_id == pole_id)
        .order_by(desc(SensorReading.recorded_at))
        .limit(1)
    )
    reading = result.scalar_one_or_none()
    if not reading:
        return {
            "success": True,
            "data": None,
            "message": f"No telemetry readings recorded yet for pole {pole_id}."
        }
    return {
        "success": True,
        "data": SensorReadingOut.model_validate(reading).model_dump(),
        "message": "Latest reading retrieved."
    }


@router.get("/{pole_id}/history", response_model=dict, summary="Get Telemetry History for Trend Charts")
async def get_pole_history(
    pole_id: str,
    limit: int = 50,
    db: AsyncSession = Depends(get_db)
):
    """Returns sequential historical sensor readings for rendering mobile trend charts (Leakage, Voltage, Temp)."""
    result = await db.execute(
        select(SensorReading)
        .where(SensorReading.pole_id == pole_id)
        .order_by(desc(SensorReading.recorded_at))
        .limit(limit)
    )
    readings = result.scalars().all()
    # Reverse to chronological order (earliest to latest) for charts
    ordered = [SensorReadingOut.model_validate(r).model_dump() for r in reversed(readings)]

    return {
        "success": True,
        "pole_id": pole_id,
        "count": len(ordered),
        "data": ordered,
        "message": "Historical telemetry retrieved."
    }


@router.get("/{pole_id}/health", response_model=dict, summary="Get Pole Health Score & Maintenance Priority")
async def get_pole_health(pole_id: str, db: AsyncSession = Depends(get_db)):
    """Returns the composite health score (0-100) and factors affecting maintenance urgency."""
    result = await db.execute(select(Pole).where(Pole.id == pole_id))
    pole = result.scalar_one_or_none()
    if not pole:
        raise HTTPException(status_code=404, detail=f"Pole {pole_id} not found")

    score = pole.health_score
    priority = "IMMEDIATE" if score < 60 else ("HIGH" if score < 75 else ("MEDIUM" if score < 85 else "LOW"))
    trend = "DEGRADING" if score < 75 else "STABLE"

    resp = PoleHealthResponse(
        pole_id=pole.id,
        health_score=score,
        previous_score=min(100, score + 4),
        trend=trend,
        maintenance_priority=priority,
        factors={
            "insulation_integrity": f"{score}%",
            "grounding_resistance_status": "NORMAL" if score >= 75 else "DEGRADED",
            "weather_impact": "ELEVATED" if pole.status == "CRITICAL" else "LOW",
        }
    )
    return {"success": True, "data": resp.model_dump(), "message": "Health evaluation fetched."}


@router.get("/{pole_id}/risk", response_model=dict, summary="Get Decision Engine Risk Assessment")
async def get_pole_risk(pole_id: str, db: AsyncSession = Depends(get_db)):
    """Returns the deterministic Decision Engine safety risk assessment and factors."""
    result = await db.execute(select(Pole).where(Pole.id == pole_id))
    pole = result.scalar_one_or_none()
    if not pole:
        raise HTTPException(status_code=404, detail=f"Pole {pole_id} not found")

    risk_score = pole.risk_score
    tier = "EMERGENCY" if risk_score >= 85 else ("CRITICAL" if risk_score >= 60 else ("WARNING" if risk_score >= 30 else "SAFE"))

    resp = PoleRiskResponse(
        pole_id=pole.id,
        risk_score=risk_score,
        risk_tier=tier,
        decision_reason=f"Status is {pole.status}. Risk score is {risk_score}/100.",
        contributing_factors={
            "leakage_severity": "CRITICAL" if risk_score >= 70 else "NORMAL",
            "weather_multiplier": 1.35 if pole.status == "CRITICAL" else 1.0,
            "decision_engine_mode": "DETERMINISTIC_RULES_v1"
        }
    )
    return {"success": True, "data": resp.model_dump(), "message": "Risk evaluation fetched."}
