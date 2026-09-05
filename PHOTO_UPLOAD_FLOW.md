# PoleGuard — Camera & Photo Evidence Upload Architecture

PoleGuard supports real photographic evidence collection from smartphone cameras and galleries, validated and stored securely by the FastAPI backend.

---

## 1. Step-by-Step Execution Sequence

```text
[Mobile Phone]
   │
   ├─► 1. User taps "Capture Camera" or "Gallery"
   │      - Flutter `image_picker` accesses native camera hardware.
   │
   ├─► 2. Photo is captured / selected as raw image file.
   │
   ├─► 3. `PhotoUploadService.uploadImageFile(imageFile)`
   │      - Streams image bytes via HTTP `POST /api/v1/uploads/image`.
   │      - Encoded as `multipart/form-data` with Bearer auth token.
   │
   ▼
[FastAPI Backend: /api/v1/uploads/image]
   │
   ├─► 4. MIME Type Validation:
   │      - Allowed: `image/jpeg`, `image/png`, `image/webp`.
   │      - Rejects non-image or executable payloads (`400 Bad Request`).
   │
   ├─► 5. File Size Validation:
   │      - Maximum limit: 10,485,760 bytes (10 MB).
   │      - Rejects oversized files (`413 Content Too Large`).
   │
   ├─► 6. Secure Unique Filename Generation:
   │      - `{uuid4}_{clean_filename}` prevents overwrite attacks.
   │
   ├─► 7. Local File Persistence:
   │      - Saved to `backend/uploads/{filename}`.
   │
   ├─► 8. Return Response:
   │      `{"success": true, "image_url": "/uploads/{filename}", "file_id": "{uuid}"}`
   │
   ▼
[Mobile Phone UI]
   │
   ├─► 9. Renders instant image preview with green verification badge.
   ├─► 10. Attaches `image_url` to `HazardReport` or `WorkOrder` submission payload.
   └─► 11. Backend links image URL to the database record for permanent audit tracking.
```

---

## 2. Zero-Dependency Local Storage & Cloud Readiness

- **Local Development / Offline Viva**: Images are served via FastAPI's static file handler mounted at `/uploads`, requiring zero third-party cloud accounts (no AWS S3 or Supabase required to run).
- **Production Scalability**: The storage engine is encapsulated behind `save_upload_file()`. In production environments, this single function can be redirected to Amazon S3, Google Cloud Storage, or Azure Blob Storage by changing one configuration variable without changing any mobile app code.
