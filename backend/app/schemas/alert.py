from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class AlertCreate(BaseModel):
    pole_id: str
    telemetry_id: Optional[int] = None
    severity: str = Field(..., description="LOW, MEDIUM, HIGH, or CRITICAL")
    alert_type: str = Field(..., description="CURRENT_LEAKAGE, POLE_TILT, WATERLOG_PROXIMITY")
    message: str
    status: str = "NEW"


class AlertUpdate(BaseModel):
    status: str = Field(..., description="ACKNOWLEDGED, IN_PROGRESS, or RESOLVED")
    resolution_notes: Optional[str] = None


class AlertResponse(BaseModel):
    id: str
    pole_id: str
    telemetry_id: Optional[int] = None
    severity: str
    alert_type: str
    message: str
    status: str
    created_at: datetime
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    resolution_notes: Optional[str] = None
