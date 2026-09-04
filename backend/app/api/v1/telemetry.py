from typing import List
from fastapi import APIRouter, HTTPException, status
from backend.app.schemas.telemetry import (
    TelemetryIn,
    TelemetryBatchIn,
    TelemetryEvaluationResult
)
from backend.app.services.decision_engine import decision_engine

router = APIRouter(prefix="/telemetry", tags=["Telemetry Ingestion"])


@router.post(
    "",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Ingest Telemetry (ESP32 or Simulation)"
)
async def ingest_telemetry(telemetry: TelemetryIn):
    """
    Primary ingestion endpoint.
    Accepts standardized sensor readings from either a live ESP32 edge device
    or the telemetry simulator script (scripts/simulate_telemetry.py).
    """
    evaluation: TelemetryEvaluationResult = decision_engine.evaluate_telemetry(telemetry)

    return {
        "success": True,
        "data": evaluation.model_dump(),
        "message": "Telemetry evaluated successfully"
    }


@router.post(
    "/batch",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Batch Telemetry Ingestion (Edge Offline Re-sync)"
)
async def ingest_batch_telemetry(batch: TelemetryBatchIn):
    """
    Batch ingestion endpoint for buffered readings uploaded after
    an edge device recovers from an offline network period.
    """
    results: List[TelemetryEvaluationResult] = []
    for item in batch.readings:
        res = decision_engine.evaluate_telemetry(item)
        results.append(res)

    return {
        "success": True,
        "data": {
            "pole_id": batch.pole_id,
            "processed_count": len(results),
            "critical_alerts_found": any(r.risk_level == "CRITICAL" for r in results)
        },
        "message": f"Successfully ingested {len(results)} buffered readings."
    }
