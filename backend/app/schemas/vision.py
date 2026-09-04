from typing import Any, Dict, List, Optional
from pydantic import BaseModel


class DetectedObject(BaseModel):
    label: str
    confidence: float
    box: List[float]  # [x1, y1, x2, y2]


class VisionInspectionResponse(BaseModel):
    inspection_id: str
    pole_id: str
    filename: Optional[str] = None
    waterlogging_detected: bool
    human_proximity_detected: bool
    estimated_distance_meters: Optional[float] = None
    cable_defect_detected: bool = False
    detected_objects: List[DetectedObject] = []
    visual_hazard_score: float
    multi_modal_risk_level: Optional[str] = None
    composite_risk_index: Optional[float] = None
    alert_triggered: bool = False
    alert_message: Optional[str] = None
