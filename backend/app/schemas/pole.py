from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class PoleBase(BaseModel):
    id: str = Field(..., description="Unique pole ID, e.g. POLE-101")
    serial_number: Optional[str] = None
    name: str = Field(..., description="Location name or landmark")
    latitude: float = Field(..., description="WGS84 Latitude")
    longitude: float = Field(..., description="WGS84 Longitude")
    zone: str = Field(default="Sector 1", description="Municipal / utility ward")
    status: str = Field(default="HEALTHY", description="HEALTHY, WARNING, CRITICAL, OFFLINE")
    is_active: bool = True


class PoleCreate(PoleBase):
    pass


class PoleResponse(PoleBase):
    last_heartbeat: Optional[datetime] = None
    last_leakage_current_ma: Optional[float] = None
    last_risk_level: Optional[str] = "NORMAL"
    created_at: Optional[datetime] = None
