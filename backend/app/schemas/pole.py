from datetime import datetime
from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field, ConfigDict


class PoleBase(BaseModel):
    id: str = Field(..., description="Unique pole ID, e.g. P-001")
    serial_number: Optional[str] = None
    name: str = Field(..., description="Location name or landmark")
    latitude: float = Field(..., description="WGS84 Latitude")
    longitude: float = Field(..., description="WGS84 Longitude")
    zone: str = Field(default="Sector 1", description="Municipal / utility ward")
    status: str = Field(default="HEALTHY", description="HEALTHY, WARNING, CRITICAL, OFFLINE")
    health_score: int = Field(default=95, ge=0, le=100)
    risk_score: int = Field(default=5, ge=0, le=100)
    is_active: bool = True


class PoleCreate(PoleBase):
    pass


class SensorReadingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    pole_id: str
    leakage_current: float
    voltage: float
    temperature: float
    humidity: float
    rain: bool
    is_simulated: bool
    recorded_at: datetime


class PoleResponse(PoleBase):
    model_config = ConfigDict(from_attributes=True)

    connectivity: str = "ONLINE" # ONLINE or OFFLINE
    last_heartbeat: Optional[datetime] = None
    latest_reading: Optional[SensorReadingOut] = None
    created_at: Optional[datetime] = None


class PoleHealthResponse(BaseModel):
    pole_id: str
    health_score: int
    previous_score: int = 95
    trend: str = "STABLE" # STABLE, DEGRADING, IMPROVING
    maintenance_priority: str = "LOW" # LOW, MEDIUM, HIGH, IMMEDIATE
    factors: Dict[str, Any] = {}


class PoleRiskResponse(BaseModel):
    pole_id: str
    risk_score: int
    risk_tier: str # SAFE, WARNING, CRITICAL, EMERGENCY
    decision_reason: str
    contributing_factors: Dict[str, Any] = {}
