from fastapi import APIRouter, File, Form, UploadFile
from backend.app.schemas.vision import VisionInspectionResponse

router = APIRouter(prefix="/vision", tags=["Computer Vision"])


@router.post("/upload", response_model=dict, summary="Upload Pole Photo for YOLO Hazard Inspection")
async def upload_inspection_image(
    pole_id: str = Form(...),
    file: UploadFile = File(...)
):
    """
    Accepts inspection photo from field lineman or surveillance camera.
    In Phase 4, this feeds into the YOLOv8 model for human and waterlogging detection.
    """
    return {
        "success": True,
        "data": {
            "inspection_id": "VIS-SAMPLE-01",
            "pole_id": pole_id,
            "filename": file.filename,
            "waterlogging_detected": True,
            "human_proximity_detected": False,
            "visual_hazard_score": 0.65,
            "note": "Vision scaffold ready. Connects to YOLO weights in Phase 4."
        },
        "message": "Image received and queued for computer vision inference."
    }
