# API Design & Specifications

## 1. Conventions & Principles

* **Base URL:** `/api/v1`
* **Transport:** HTTPS for production; HTTP for local development and edge prototyping.
* **Payload Encoding:** `application/json` (Multipart form-data for image uploads).
* **Date-Time Format:** ISO 8601 UTC (`YYYY-MM-DDTHH:MM:SSZ`).
* **Authentication:**
  - Client Applications (Web/Mobile): `Authorization: Bearer <jwt_token>`
  - Edge IoT Devices / Simulators: `X-Device-Key: <api_key>` (or shared secret header).

---

## 2. Standard Response Envelope

All REST endpoints follow a standardized JSON envelope structure:

```json
{
  "success": true,
  "data": {},
  "message": "Operation completed successfully",
  "timestamp": "2026-09-04T14:45:00Z"
}
```

In case of error:
```json
{
  "success": false,
  "error": {
    "code": "POLE_NOT_FOUND",
    "detail": "Pole with ID 'POLE-999' was not found in the registry."
  },
  "timestamp": "2026-09-04T14:45:00Z"
}
```

---

## 3. Endpoints Overview

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/telemetry` | Ingest single telemetry reading (ESP32 or Simulator) | Device Key / Open (Dev) |
| `POST` | `/api/v1/telemetry/batch` | Ingest buffered telemetry batch from offline edge sync | Device Key |
| `GET` | `/api/v1/poles` | List registered poles with status & latest telemetry | User |
| `GET` | `/api/v1/poles/{id}` | Retrieve single pole profile and hardware details | User |
| `POST` | `/api/v1/poles` | Register a new pole asset | Admin |
| `GET` | `/api/v1/poles/{id}/telemetry` | Retrieve time-series telemetry for charts | User |
| `POST` | `/api/v1/vision/upload` | Upload field photo for YOLO hazard detection | User / Public |
| `GET` | `/api/v1/alerts` | Query active or historical alerts | User |
| `POST` | `/api/v1/alerts/{id}/acknowledge` | Acknowledge active alert | Lineman / Admin |
| `POST` | `/api/v1/alerts/{id}/resolve` | Mark alert resolved with corrective action notes | Lineman / Admin |
| `POST` | `/api/v1/ai/predict` | Manual feature evaluation against ML risk model | User |
| `POST` | `/api/v1/assistant/query` | RAG-grounded safety query to LLM | User |
| `WS` | `/ws/telemetry` | WebSocket stream of live telemetry packets | Open / User |
| `WS` | `/ws/alerts` | WebSocket broadcast of active hazard alerts | Open / User |

---

## 4. Key Request & Response Payloads

### 4.1 Ingest Telemetry (`POST /api/v1/telemetry`)
*Shared by both physical ESP32 and simulation script.*

#### Request Body
```json
{
  "pole_id": "POLE-101",
  "leakage_current_ma": 42.5,
  "touch_voltage_v": 68.2,
  "tilt_angle_deg": 3.1,
  "vibration_g": 0.08,
  "temperature_c": 29.4,
  "humidity_pct": 88.0,
  "rain_detected": true,
  "is_simulated": false
}
```

#### Response Body (`201 Created`)
```json
{
  "success": true,
  "data": {
    "telemetry_id": 14029,
    "pole_id": "POLE-101",
    "risk_level": "HIGH_RISK",
    "composite_risk_index": 82.4,
    "alert_triggered": true,
    "alert_id": "ALT-550e8400-e29b-41d4-a716-446655440000"
  },
  "message": "Telemetry processed and evaluated",
  "timestamp": "2026-09-04T14:45:00Z"
}
```

---

### 4.2 Computer Vision Upload (`POST /api/v1/vision/upload`)
*Uploads an inspection photo (e.g., from lineman phone or pole-mounted camera) for YOLO object detection.*

#### Request
* Content-Type: `multipart/form-data`
* Form fields:
  - `file`: image file (JPEG, PNG)
  - `pole_id`: `POLE-101`

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "data": {
    "inspection_id": "VIS-a8f3b491-11b0-4f90-88ef-230948924011",
    "pole_id": "POLE-101",
    "waterlogging_detected": true,
    "human_proximity_detected": true,
    "estimated_distance_meters": 1.4,
    "detected_objects": [
      {
        "class": "human",
        "confidence": 0.94,
        "box": [120, 310, 240, 680]
      },
      {
        "class": "water_puddle",
        "confidence": 0.88,
        "box": [50, 550, 780, 920]
      }
    ],
    "visual_hazard_score": 0.91
  },
  "message": "Vision inference complete",
  "timestamp": "2026-09-04T14:45:05Z"
}
```

---

### 4.3 RAG Safety Assistant (`POST /api/v1/assistant/query`)
*Queries safety rules and emergency SOPs using ChromaDB embeddings and the configured LLM.*

#### Request Body
```json
{
  "query": "What are the mandatory isolation safety steps before touching pole #POLE-101 reporting 45mA leakage in heavy rain?",
  "pole_id": "POLE-101",
  "user_role": "LINEMAN"
}
```

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "data": {
    "answer": "1. Do NOT touch the pole barehanded or step into surrounding puddles.\n2. Ensure Class 0 (1000V rated) insulating rubber gloves and dielectric boots are worn.\n3. Verify pole de-energization using a certified non-contact AC voltage detector.\n4. Request upstream sub-station feeder shutdown for Sector 4.\n5. Establish a 5-meter safety perimeter and apply a temporary discharge earthing rod before physical inspection.",
    "citations": [
      {
        "source": "CEA_Safety_Regulations_2010.pdf",
        "section": "Regulation 43: Isolation and Grounding Procedures",
        "relevance_score": 0.91
      },
      {
        "source": "Lineman_Field_SOP_Monsoon.pdf",
        "section": "Section 4.2: High Leakage Current Protocol in Waterlogged Areas",
        "relevance_score": 0.87
      }
    ]
  },
  "message": "Safety guidance generated",
  "timestamp": "2026-09-04T14:45:08Z"
}
```

---

## 5. WebSockets Specifications

### 5.1 `/ws/telemetry`
Streams live telemetry packets to connected web dashboards.
* **Format:** JSON object matching `TelemetryIn` + `risk_level` on every ingested packet.

### 5.2 `/ws/alerts`
Pushes real-time alerts immediately when the Decision Engine identifies `HIGH_RISK` or `CRITICAL` conditions.
* **Payload:**
  ```json
  {
    "event": "NEW_ALERT",
    "alert_id": "ALT-550e8400",
    "pole_id": "POLE-101",
    "severity": "CRITICAL",
    "message": "Hazardous touch voltage (68V) with human in waterlogged zone",
    "created_at": "2026-09-04T14:45:00Z"
  }
  ```
