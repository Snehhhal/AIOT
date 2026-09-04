from typing import List
from fastapi import APIRouter
from backend.app.schemas.pole import PoleResponse

router = APIRouter(prefix="/poles", tags=["Poles"])

# Mock in-memory directory for initial scaffold / demonstration
SAMPLE_POLES = [
    {
        "id": "POLE-101",
        "name": "MG Road - Junction 4",
        "latitude": 18.5204,
        "longitude": 73.8567,
        "zone": "Sector 1",
        "status": "HEALTHY",
        "is_active": True,
        "last_risk_level": "NORMAL"
    },
    {
        "id": "POLE-102",
        "name": "FC Road - Near Metro Station",
        "latitude": 18.5280,
        "longitude": 73.8420,
        "zone": "Sector 1",
        "status": "WARNING",
        "is_active": True,
        "last_risk_level": "HIGH_RISK"
    },
    {
        "id": "POLE-103",
        "name": "Station Road - Waterlogged Zone",
        "latitude": 18.5312,
        "longitude": 73.8745,
        "zone": "Sector 2",
        "status": "CRITICAL",
        "is_active": True,
        "last_risk_level": "CRITICAL"
    }
]


@router.get("", response_model=dict, summary="List Registered Poles")
async def list_poles():
    return {
        "success": True,
        "data": SAMPLE_POLES,
        "message": "Poles fetched successfully"
    }


@router.get("/{pole_id}", response_model=dict, summary="Get Single Pole Details")
async def get_pole(pole_id: str):
    pole = next((p for p in SAMPLE_POLES if p["id"] == pole_id), None)
    if not pole:
        return {"success": False, "message": f"Pole {pole_id} not found"}
    return {"success": True, "data": pole, "message": "Pole found"}
