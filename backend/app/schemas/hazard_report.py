from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class HazardReportCreate(BaseModel):
    pole_id: Optional[str] = Field(None, description="Optional associated pole ID e.g. P-001")
    latitude: float = Field(..., description="GPS Latitude of detected hazard")
    longitude: float = Field(..., description="GPS Longitude of detected hazard")
    address: Optional[str] = Field(None, description="Approximate street or landmark address")
    hazard_type: str = Field(
        ...,
        description="Hazard type (e.g. Electrical leakage suspicion, Damaged pole, Broken wire, Sparking, Water near electrical pole, Fallen wire, Fire/smoke, Human/animal danger, Other)"
    )
    description: str = Field(..., min_length=5, description="Clear description of observed hazard")
    image_url: Optional[str] = Field(None, description="Accessible URL of uploaded hazard photo")
    reporter_name: Optional[str] = Field(None, description="Citizen reporter name or Anonymous")
    reporter_phone: Optional[str] = Field(None, description="Optional contact number for emergency verification")


class HazardReportStatusUpdate(BaseModel):
    status: str = Field(
        ...,
        description="New lifecycle status: UNDER_REVIEW, VERIFIED, REJECTED, ASSIGNED, ACKNOWLEDGED, IN_PROGRESS, RESOLVED, CLOSED"
    )
    notes: Optional[str] = Field(None, description="Inspection or resolution notes")
    inspection_image_url: Optional[str] = Field(None, description="Photo uploaded by technician during inspection or repair")


class HazardReportAssign(BaseModel):
    technician_id: str = Field(..., description="Assigned technician user ID")
    notes: Optional[str] = Field(None, description="Assignment instructions or priority directives")


class HazardReportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    reporter_id: Optional[str] = None
    reporter_name: Optional[str] = None
    reporter_phone: Optional[str] = None
    pole_id: Optional[str] = None
    latitude: float
    longitude: float
    address: Optional[str] = None
    hazard_type: str
    description: str
    image_url: Optional[str] = None
    status: str
    assigned_technician_id: Optional[str] = None
    inspection_notes: Optional[str] = None
    inspection_image_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
