from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.core.database import get_db
from backend.app.models.entities import Pole, SensorReading, Alert, Incident
from backend.app.schemas.telemetry import (
    TelemetryIn,
    TelemetryBatchIn,
    TelemetryEvaluationResult
)
from backend.app.services.decision_engine import decision_engine
from backend.app.core.websocket import ws_manager

router = APIRouter(tags=["IoT Ingestion & Telemetry"])


async def _process_single_reading(telemetry: TelemetryIn, db: AsyncSession) -> TelemetryEvaluationResult:
    """Processes a single reading through the Decision Engine and commits records to DB."""
    # 1. Run through Multi-Layer Decision Engine
    evaluation: TelemetryEvaluationResult = decision_engine.evaluate_telemetry(telemetry)

    # 2. Persist SensorReading in DB
    reading_record = SensorReading(
        pole_id=telemetry.pole_id,
        leakage_current=telemetry.leakage_current_ma,
        voltage=telemetry.touch_voltage_v,
        temperature=telemetry.temperature_c,
        humidity=telemetry.humidity_pct,
        rain=telemetry.rain_detected,
        is_simulated=telemetry.is_simulated,
        recorded_at=telemetry.recorded_at or datetime.now(timezone.utc),
    )
    db.add(reading_record)

    # 3. Update Pole Last Heartbeat, Status, and Risk Score
    pole_res = await db.execute(select(Pole).where(Pole.id == telemetry.pole_id))
    pole = pole_res.scalar_one_or_none()
    if pole:
        pole.last_heartbeat = reading_record.recorded_at
        pole.risk_score = int(evaluation.composite_risk_index)
        if evaluation.risk_level in ["CRITICAL", "HIGH_RISK"]:
            pole.status = "CRITICAL"
        elif evaluation.risk_level == "ADVISORY":
            pole.status = "WARNING"
        else:
            pole.status = "HEALTHY"

    # 4. If alert triggered, create Alert and Incident in DB
    if evaluation.alert_triggered and evaluation.alert_id:
        alert_record = Alert(
            id=evaluation.alert_id,
            pole_id=telemetry.pole_id,
            severity=evaluation.risk_level,
            alert_type="CURRENT_LEAKAGE" if telemetry.leakage_current_ma >= 30.0 else "STRUCTURAL_TILT",
            message=evaluation.alert_message or f"Hazardous condition on {telemetry.pole_id}",
            status="NEW",
            created_at=datetime.now(timezone.utc),
        )
        db.add(alert_record)

        incident_record = Incident(
            id=f"INC-{evaluation.alert_id}",
            pole_id=telemetry.pole_id,
            severity=evaluation.risk_level,
            status="DETECTED",
            description=alert_record.message,
            created_at=datetime.now(timezone.utc),
        )
        db.add(incident_record)

    await db.commit()

    # 5. Broadcast to connected WebSocket subscribers in real time
    try:
        await ws_manager.broadcast_telemetry({
            "event": "TELEMETRY_PACKET",
            "pole_id": telemetry.pole_id,
            "leakage_current_ma": telemetry.leakage_current_ma,
            "touch_voltage_v": telemetry.touch_voltage_v,
            "tilt_angle_deg": telemetry.tilt_angle_deg,
            "vibration_g": telemetry.vibration_g,
            "temperature_c": telemetry.temperature_c,
            "humidity_pct": telemetry.humidity_pct,
            "rain_detected": telemetry.rain_detected,
            "risk_level": evaluation.risk_level,
            "composite_risk_index": evaluation.composite_risk_index,
            "alert_triggered": evaluation.alert_triggered,
            "timestamp": (telemetry.recorded_at or datetime.now(timezone.utc)).isoformat()
        })
        if evaluation.alert_triggered:
            await ws_manager.broadcast_alert({
                "event": "NEW_ALERT",
                "alert_id": evaluation.alert_id,
                "pole_id": telemetry.pole_id,
                "severity": evaluation.risk_level,
                "message": evaluation.alert_message,
                "timestamp": datetime.now(timezone.utc).isoformat()
            })
    except Exception:
        pass

    return evaluation


@router.post(
    "/telemetry",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Ingest Telemetry (ESP32 or Simulation)"
)
@router.post(
    "/iot/readings",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Alias: Ingest IoT Sensor Reading"
)
async def ingest_telemetry(telemetry: TelemetryIn, db: AsyncSession = Depends(get_db)):
    """
    Primary ingestion endpoint.
    Accepts standardized sensor readings from either a live ESP32 edge device
    or the telemetry simulator script (scripts/simulate_telemetry.py).
    Persists data to PostgreSQL/SQLite, executes Decision Engine, and manages alerts.
    """
    evaluation = await _process_single_reading(telemetry, db)

    return {
        "success": True,
        "data": evaluation.model_dump(),
        "message": "Telemetry evaluated and stored successfully"
    }


@router.post(
    "/telemetry/batch",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Batch Telemetry Ingestion (Edge Offline Re-sync)"
)
async def ingest_batch_telemetry(batch: TelemetryBatchIn, db: AsyncSession = Depends(get_db)):
    """
    Batch ingestion endpoint for buffered readings uploaded after
    an edge device recovers from an offline network period.
    """
    results: List[TelemetryEvaluationResult] = []
    for item in batch.readings:
        res = await _process_single_reading(item, db)
        results.append(res)

    return {
        "success": True,
        "data": {
            "pole_id": batch.pole_id,
            "processed_count": len(results),
            "critical_alerts_found": any(r.risk_level == "CRITICAL" for r in results)
        },
        "message": f"Successfully ingested and persisted {len(results)} buffered readings."
    }
