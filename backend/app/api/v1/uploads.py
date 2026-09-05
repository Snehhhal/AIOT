import os
import uuid
from pathlib import Path
from fastapi import APIRouter, File, UploadFile, HTTPException, status

router = APIRouter(prefix="/uploads", tags=["File & Image Uploads"])

# Upload directory: backend/uploads
UPLOAD_DIR = Path("backend/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp"
}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


@router.post("/image", response_model=dict, status_code=status.HTTP_201_CREATED, summary="Upload Camera or Gallery Photo")
async def upload_image(file: UploadFile = File(...)):
    """
    Accepts multipart/form-data image from mobile camera or gallery.
    Validates file extension and size, saves to storage, and returns accessible URL.
    """
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Filename is required."
        )

    # Validate file extension
    ext = Path(file.filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported image format '{ext}'. Allowed: {list(ALLOWED_EXTENSIONS)}"
        )

    # Validate content type
    if file.content_type and file.content_type.lower() not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid MIME type '{file.content_type}'. Must be a valid image."
        )

    # Read content and validate size
    content = await file.read()
    if len(content) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File exceeds maximum allowed size of 10 MB."
        )

    if len(content) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty."
        )

    # Generate safe unique filename
    file_id = f"IMG-{uuid.uuid4().hex[:12].upper()}"
    saved_filename = f"{file_id}{ext}"
    dest_path = UPLOAD_DIR / saved_filename

    with open(dest_path, "wb") as f:
        f.write(content)

    image_url = f"/uploads/{saved_filename}"

    return {
        "success": True,
        "image_url": image_url,
        "file_id": file_id,
        "filename": saved_filename,
        "size_bytes": len(content),
        "content_type": file.content_type,
        "message": "Photo uploaded and verified successfully."
    }
