# PoleGuard — End-to-End Real Data Flow Architecture

PoleGuard guarantees genuine data persistence and cross-system communication across all modules.

---

## 1. High-Level Data Flow Diagram

```mermaid
sequenceDiagram
    autonumber
    actor C as Citizen / Phone
    actor T as Technician
    actor A as Authority
    participant M as Flutter Mobile App
    participant F as FastAPI Ingestion Engine
    participant DB as PostgreSQL / SQLite
    participant AI as Random Forest & CV Models
    participant DE as Decision Engine (CRI 0-100)
    participant WS as WebSocket Manager

    %% Telemetry Stream
    Note over F,DE: Telemetry Pipeline (Mock Simulator or ESP32)
    F->>DB: Ingest Telemetry (leakage_current, voltage, tilt, rain)
    F->>AI: Predict Fault Class (Normal, Warning, Critical, Emergency)
    F->>DE: Compute Composite Risk Index (CRI 0-100)
    DE->>DB: Persist Incident / Alert if CRI >= 50
    DE->>WS: Broadcast Telemetry & Alert Stream

    %% Mobile App Interaction
    M->>F: GET /api/v1/poles/nearby?latitude=18.52&longitude=73.85
    F-->>M: Return Registered Poles sorted by Haversine Distance

    %% Photo Upload & Citizen Reporting
    C->>M: Snap Camera Photo of Leaning / Sparking Pole
    M->>F: POST /api/v1/uploads/image (Multipart Form-Data)
    F->>F: Validate MIME (image/jpeg) & Size (<10MB)
    F-->>M: Return Static URL: /uploads/img_9a12.jpg
    M->>F: POST /api/v1/hazard-reports (Report ID: REP-000124)
    F->>DB: Insert HazardReport (status: REPORTED)
    F->>WS: Broadcast New Hazard Report Alert

    %% Technician Lifecycle
    T->>M: Open Incidents Tab (GET /api/v1/hazard-reports)
    M->>F: PATCH /api/v1/hazard-reports/REP-000124/status (ACKNOWLEDGED)
    T->>M: Upload Post-Repair Photo + Insulation Readings (120MΩ)
    M->>F: PATCH /api/v1/hazard-reports/REP-000124/status (RESOLVED)
    F->>DB: Update Status & Log Audit Record

    %% Authority Intervention
    A->>M: View Overdue Escalations
    A->>M: Order Remote Power Grid Cutoff
    M->>F: POST /api/v1/authority/grid-cutoff (Pole: P-001)
    F->>DB: Set Pole Status to OFFLINE, Trip Breaker
    F->>WS: Broadcast GRID_CUTOFF Event
```

---

## 2. Granular Data Lifecycles

### A. Phone GPS Discovery Pipeline
1. Phone opens `CitizenHomeScreen`.
2. `LocationService` queries native hardware via `geolocator`.
3. If GPS is available, device coordinates (e.g. `lat: 18.5204, lng: 73.8567`) are read. If running on desktop/emulator without GPS, the user can toggle **"Test Location Mode"** to use pre-configured substation landmarks (MG Road, FC Road, Station Road, Paud Road).
4. `ApiClient.getNearbyPoles(lat, lng, radiusKm: 15.0)` sends coordinates to `GET /api/v1/poles/nearby`.
5. The backend executes Haversine great-circle distance calculations against all poles in the database:
   $$\text{distance} = 2 R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
6. Poles are sorted ascending by distance and returned with `distance_meters`, current safety status, health score, and risk tier.

---

### B. Multipart Photo Upload & Storage Pipeline
1. In `CitizenReportScreen` or `TechnicianWorkScreen`, user selects **Camera** or **Gallery**.
2. `PhotoUploadService` calls `image_picker` to capture the image.
3. Image bytes are streamed via HTTP `POST /api/v1/uploads/image` as `multipart/form-data`.
4. Backend `uploads.py`:
   - Validates MIME type (`image/jpeg`, `image/png`, `image/webp`).
   - Validates file size ($\le 10$ MB).
   - Generates a collision-free UUID filename: `{uuid4}_{clean_name}`.
   - Saves file to disk under `backend/uploads/`.
   - Returns JSON: `{"success": true, "image_url": "/uploads/{filename}", "file_id": "{uuid}"}`.
5. The frontend immediately displays a preview of the uploaded photo with its server URL.

---

### C. Citizen Hazard Report Lifecycle States
Reports progress through a verifiable audit-tracked state machine:
```text
REPORTED  ──►  UNDER_REVIEW  ──►  VERIFIED / REJECTED  ──►  ASSIGNED
                                                               │
CLOSED    ◄──    RESOLVED    ◄──   IN_PROGRESS   ◄──  ACKNOWLEDGED
```

---

### D. RAG Safety Assistant Pipeline
1. Citizen or Technician submits a query (e.g. *"Is it safe to touch a pole standing in rain water?"*).
2. `POST /api/v1/assistant/chat` intercepts the query.
3. Query embedding is generated and compared against ChromaDB containing:
   - Central Electricity Authority (CEA) Safety Regulations 2010
   - Lineman Monsoon Standard Operating Procedures (SOP)
   - Personal Protective Equipment (PPE) Specifications
4. The most relevant statutory safety clauses are retrieved and synthesized into an authoritative, actionable response.
