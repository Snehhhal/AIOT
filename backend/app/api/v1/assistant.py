from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from backend.app.core.database import get_db
from backend.app.models.entities import SensorReading
from backend.app.schemas.assistant import AssistantQuery, AssistantResponse, Citation
from rag.src.retriever import safety_assistant

router = APIRouter(prefix="/assistant", tags=["Safety RAG Assistant"])


@router.post(
    "/query",
    response_model=dict,
    summary="Query Safety Regulations and Standard Operating Procedures (RAG)"
)
async def query_safety_assistant(query_in: AssistantQuery, db: AsyncSession = Depends(get_db)):
    """
    RAG Assistant endpoint.
    Performs semantic vector search against ChromaDB safety knowledge base
    (CEA Regulations 2010 + Lineman Monsoon SOP + PPE Specifications).
    Fuses statutory regulations with real-time physical telemetry for the requested pole.
    """
    telemetry_ctx = None
    if query_in.pole_id:
        reading_res = await db.execute(
            select(SensorReading)
            .where(SensorReading.pole_id == query_in.pole_id)
            .order_by(desc(SensorReading.recorded_at))
            .limit(1)
        )
        latest = reading_res.scalar_one_or_none()
        if latest:
            telemetry_ctx = {
                "leakage_current_ma": latest.leakage_current,
                "touch_voltage_v": latest.voltage,
                "rain_detected": latest.rain,
                "temperature_c": latest.temperature,
                "humidity_pct": latest.humidity
            }

    # Execute vector retrieval & response synthesis
    rag_result = safety_assistant.answer_query(
        query=query_in.query,
        pole_id=query_in.pole_id,
        telemetry_context=telemetry_ctx
    )

    response_data = AssistantResponse(
        answer=rag_result["answer"],
        citations=[Citation(**c) for c in rag_result["citations"]],
        safety_level=rag_result["safety_level"],
        recommended_ppe=rag_result["recommended_ppe"]
    )

    return {
        "success": True,
        "data": response_data.model_dump(),
        "message": "Statutory safety guidance and citations retrieved successfully."
    }
