from datetime import datetime, timezone
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from backend.app.core.database import get_db
from backend.app.core.websocket import ws_manager
from backend.app.models.entities import Pole, SensorReading, Alert, Incident
from backend.app.schemas.telemetry import TelemetryIn
from backend.app.schemas.vision import VisionInspectionResponse, DetectedObject
from backend.app.services.decision_engine import decision_engine
from ai.src.vision_detector import vision_detector

router = APIRouter(prefix="/vision", tags=["Computer Vision & Multi-Modal Fusion"])


@router.post(
    "/upload",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    summary="Upload Pole Inspection Photo for Vision-Sensor Cross-Modal Fusion"
)
async def upload_inspection_image(
    pole_id: str = Form(..., description="Target Utility Pole ID (e.g. P-001, P-004)"),
    file: UploadFile = File(..., description="Inspection image file (JPEG/PNG)"),
    simulation_hint: Optional[str] = Form(None, description="Optional scene tag: waterlogging, human, cable_defect"),
    db: AsyncSession = Depends(get_db)
):
    """
    Ingests an inspection photo from field inspection or surveillance camera.
    Runs Computer Vision object detection (puddle, pedestrian, loose cable),
    calculates spatial pedestrian distance to pole base, and fuses visual evidence
    with the latest real-time IoT telemetry in the Decision Engine.
    """
    # 1. Read file bytes
    try:
        contents = await file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read image file: {e}")

    # 2. Run Computer Vision Analysis
    hint = simulation_hint or file.filename or ""
    vis_res = vision_detector.analyze_image(
        image_input=contents if len(contents) > 0 else "waterlogging_and_human",
        pole_id=pole_id,
        simulation_hint=hint
    )

    # 3. Retrieve latest telemetry reading for pole from database to execute multi-modal fusion
    reading_res = await db.execute(
        select(SensorReading)
        .where(SensorReading.pole_id == pole_id)
        .order_by(desc(SensorReading.recorded_at))
        .limit(1)
    )
    latest_reading = reading_res.scalar_one_or_none()

    if latest_reading:
        telemetry_in = TelemetryIn(
            pole_id=pole_id,
            leakage_current_ma=latest_reading.leakage_current,
            touch_voltage_v=latest_reading.voltage,
            tilt_angle_deg=0.8,
            vibration_g=0.03,
            temperature_c=latest_reading.temperature,
            humidity_pct=latest_reading.humidity,
            rain_detected=latest_reading.rain,
            is_simulated=latest_reading.is_simulated
        )
    else:
        # Default nominal or hint-based reading for newly created pole
        is_wet = vis_res["waterlogging_detected"]
        telemetry_in = TelemetryIn(
            pole_id=pole_id,
            leakage_current_ma=28.0 if is_wet else 2.5,
            touch_voltage_v=45.0 if is_wet else 1.2,
            tilt_angle_deg=0.8,
            vibration_g=0.02,
            temperature_c=25.0,
            humidity_pct=95.0 if is_wet else 50.0,
            rain_detected=is_wet,
            is_simulated=True
        )

    # 4. Multi-Modal Decision Engine Evaluation
    evaluation = decision_engine.evaluate_telemetry(
        telemetry=telemetry_in,
        visual_hazard_score=vis_res["visual_hazard_score"],
        vision_details=vis_res
    )

    # 5. Update Pole state in DB
    pole_res = await db.execute(select(Pole).where(Pole.id == pole_id))
    pole = pole_res.scalar_one_or_none()
    if pole:
        pole.risk_score = int(evaluation.composite_risk_index)
        pole.status = "CRITICAL" if evaluation.risk_level in ["CRITICAL", "HIGH_RISK"] else ("WARNING" if evaluation.risk_level == "ADVISORY" else "HEALTHY")

    # 6. If critical alert generated, persist Alert & Incident in DB and broadcast via WebSockets
    if evaluation.alert_triggered and evaluation.alert_id:
        alert_record = Alert(
            id=evaluation.alert_id,
            pole_id=pole_id,
            severity=evaluation.risk_level,
            alert_type="MULTI_MODAL_VISION_HAZARD",
            message=evaluation.alert_message or f"Visual hazard confirmed on {pole_id}",
            status="NEW",
            created_at=datetime.now(timezone.utc),
        )
        db.add(alert_record)

        incident_record = Incident(
            id=f"INC-{evaluation.alert_id}",
            pole_id=pole_id,
            severity=evaluation.risk_level,
            status="DETECTED",
            description=alert_record.message,
            created_at=datetime.now(timezone.utc),
        )
        db.add(incident_record)

        # Broadcast instant alert to WebSocket subscribers
        try:
            await ws_manager.broadcast_alert({
                "event": "MULTI_MODAL_ALERT",
                "alert_id": evaluation.alert_id,
                "pole_id": pole_id,
                "severity": evaluation.risk_level,
                "message": evaluation.alert_message,
                "visual_hazard_score": vis_res["visual_hazard_score"],
                "estimated_distance_m": vis_res["estimated_distance_meters"],
                "composite_risk_index": evaluation.composite_risk_index,
                "timestamp": datetime.now(timezone.utc).isoformat()
            })
        except Exception:
            pass

    await db.commit()

    response_data = VisionInspectionResponse(
        inspection_id=vis_res["inspection_id"],
        pole_id=pole_id,
        filename=vis_res["filename"],
        waterlogging_detected=vis_res["waterlogging_detected"],
        human_proximity_detected=vis_res["human_proximity_detected"],
        estimated_distance_meters=vis_res["estimated_distance_meters"],
        cable_defect_detected=vis_res.get("cable_defect_detected", False),
        detected_objects=[DetectedObject(**obj) for obj in vis_res["detected_objects"]],
        visual_hazard_score=vis_res["visual_hazard_score"],
        multi_modal_risk_level=evaluation.risk_level,
        composite_risk_index=evaluation.composite_risk_index,
        alert_triggered=evaluation.alert_triggered,
        alert_message=evaluation.alert_message
    )

    return {
        "success": True,
        "data": response_data.model_dump(),
        "message": "Visual hazard analysis and multi-modal cross-sensor fusion completed successfully."
    }


@router.get(
    "/inspections/{pole_id}",
    response_model=dict,
    summary="Get Latest Visual Inspection Status for Utility Pole"
)
async def get_latest_inspection(pole_id: str, db: AsyncSession = Depends(get_db)):
    """Retrieves latest recorded alerts and incident status resulting from vision analysis."""
    alerts_res = await db.execute(
        select(Alert)
        .where(Alert.pole_id == pole_id)
        .order_by(desc(Alert.created_at))
        .limit(3)
    )
    alerts = alerts_res.scalars().all()

    return {
        "success": True,
        "data": {
            "pole_id": pole_id,
            "has_recent_visual_alerts": any(a.alert_type == "MULTI_MODAL_VISION_HAZARD" for a in alerts),
            "recent_alerts": [
                {
                    "id": a.id,
                    "type": a.alert_type,
                    "severity": a.severity,
                    "message": a.message,
                    "created_at": a.created_at.isoformat() if a.created_at else None
                }
                for a in alerts
            ]
        }
    }
