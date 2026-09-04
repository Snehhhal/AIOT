from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class IncidentResponse(BaseModel):
    id: str
    pole_id: str
    severity: str
    status: str
    description: str
    created_at: datetime
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class IncidentAssign(BaseModel):
    technician_id: str = Field(..., description="ID or email of assigned technician")
    notes: Optional[str] = Field(None, description="Dispatch instructions or notes")


class IncidentUpdateStatus(BaseModel):
    status: str = Field(..., description="ACKNOWLEDGED, IN_PROGRESS, REPAIR_IN_PROGRESS, RESOLVED, or CLOSED")
    notes: Optional[str] = Field(None, description="Technician repair or inspection notes")


class WorkOrderResponse(BaseModel):
    id: str
    incident_id: str
    technician_id: Optional[str] = None
    status: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CitizenReportCreate(BaseModel):
    pole_id: str = Field(..., description="ID of pole (e.g. P-001) or nearby landmark")
    description: str = Field(..., description="Observed hazard (sparking, leaning, waterlogging, loose wire)")
    contact_phone: Optional[str] = Field(None, description="Optional citizen contact number")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
