from typing import Any, Dict, List, Optional
from pydantic import BaseModel


class DetectedObject(BaseModel):
    label: str
    confidence: float
    box: List[float]  # [x1, y1, x2, y2]


class VisionInspectionResponse(BaseModel):
    inspection_id: str
    pole_id: str
    waterlogging_detected: bool
    human_proximity_detected: bool
    estimated_distance_meters: Optional[float] = None
    detected_objects: List[DetectedObject] = []
    visual_hazard_score: float
