# AI and IoT Based Leakage Detection in Electric Pole and Life Safety

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791.svg?logo=postgresql)](https://www.postgresql.org)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B.svg?logo=flutter)](https://flutter.dev)
[![ESP32](https://img.shields.io/badge/IoT-ESP32-E7352C.svg)](https://www.espressif.com/en/products/socs/esp32)
[![YOLO](https://img.shields.io/badge/Vision-YOLO-00FFFF.svg)](https://github.com/ultralytics/ultralytics)

---

## 1. Project Overview & Core Mandate

The **AI & IoT Based Leakage Detection in Electric Pole and Life Safety Platform** is a proactive, multi-tier cyber-physical safety network designed to detect, evaluate, isolate, and warn against electrical leakage in utility poles in real time.

> [!IMPORTANT]
> **Single User-Facing Application:** The entire platform uses **ONE unified Flutter mobile application** serving five distinct user roles with Role-Based Access Control (RBAC):
> 1. **Citizen:** Simplified, non-technical interface with Green/Yellow/Red status, Report Hazard SOS, and multilingual guidance.
> 2. **Technician:** Action-oriented interface for Active Incidents, Work Orders, Acknowledge/Inspect/Resolve workflow, and Offline sync.
> 3. **Engineer / Supervisor:** Technical operations, fleet-wide pole health monitoring, AI anomaly insights, and technician assignment.
> 4. **Authority:** Municipal safety oversight, emergency escalation tracking (technician non-response), and area risk trends.
> 5. **Admin:** Platform asset management, user administration, threshold configuration, and Judge Demo Simulation Controls.

---

## 2. Core Architecture

```
                        ONE UNIFIED FLUTTER MOBILE APP
                                       |
    -----------------------------------------------------------------------
    |              |               |                 |                    |
 CITIZEN       TECHNICIAN      ENGINEER          AUTHORITY              ADMIN
(Safe/Hazard) (Work Orders)  (Health & Anomaly) (Escalation & Area) (Config & Demo)
    |              |               |                 |                    |
    ---------------------------- FLUTTER ----------------------------------
                                       |
                                FASTAPI BACKEND
                                       |
     ------------------------------------------------------------------
     |                  |                      |                      |
 PostgreSQL        Modular AI/CV       Decision Engine             RAG/LLM
(Relational/Logs) (Scikit-Learn/YOLO)  (Deterministic Rules) (ChromaDB + Citations)
     |                  |                      |                      |
     ------------------------------------------------------------------
                                       |
                              NOTIFICATION ENGINE
                                       |
                                     ESP32
                                       |
                           SENSORS (CT, MPU6050, Rain)
```

---

## 3. Safety Decision Flow Principle

$$\text{IoT Sensors} \longrightarrow \text{AI (Tabular)} \longrightarrow \text{Computer Vision} \longrightarrow \mathbf{Decision\;Engine} \longrightarrow \text{Risk Tier (0-100)} \longrightarrow \text{LLM Explanation}$$

* **Deterministic & Auditable:** The Decision Engine executes deterministic mathematical and rule-based thresholding to compute the Composite Risk Index ($0-100$) and assign the risk tier (`SAFE`, `WARNING`, `CRITICAL`, `EMERGENCY`).
* **LLM Role:** The LLM + RAG layer is strictly an explainer and safety assistant; it **never** makes safety-critical decisions.

---

## 4. Repository Layout

```text
.
├── frontend-mobile/        # The Single Unified Flutter Mobile Application (all 5 roles)
│   ├── lib/
│   │   ├── core/           # Constants, themes, accessibility & multilingual utilities
│   │   ├── models/         # User, Pole, Telemetry, and Alert domain models
│   │   ├── services/       # Authentication, API client, Local storage (SQLite)
│   │   └── features/       # Screens & components segregated by role (Citizen, Tech, etc.)
│   └── pubspec.yaml
├── backend/                # FastAPI backend, services, schemas, and models
├── esp32/                  # ESP32 firmware (PlatformIO / Arduino C++) with local failsafe
├── ai/                     # ML training, feature extraction, and YOLO vision models
├── rag/                    # ChromaDB vector store, document loaders, and SOP index
├── docs/                   # Architectural blueprints, database & API specifications
├── scripts/                # Telemetry simulator (simulate_telemetry.py)
├── tests/                  # Backend unit, integration, and AI validation tests
├── docker/                 # Docker Compose and container definitions
├── .env.example            # Environment configuration template (zero secrets)
├── .gitignore              # Multi-framework git exclusion rules
└── README.md               # Root project documentation
```

---

## 5. Development Phases

* **Phase 1 (Completed):** Single Flutter Mobile Application foundation, Theme, Navigation Shell, Role-Based Authentication UI, and 1-Tap Quick Demo Role Switcher.
* **Phase 2 (Next):** FastAPI backend core, PostgreSQL async database schemas, JWT authentication, and backend RBAC middleware.
* **Phase 3:** Pole registry & IoT sensor ingestion API (`P-001` through `P-004`).
* **Phase 4:** Flutter ↔ FastAPI network integration with Provider state management.
* **Phase 5:** Sensor monitoring screens, interactive trend charts, and real-time polling/WebSockets.
* **Phase 6:** IoT Telemetry Simulator (`simulate_telemetry.py`) supporting normal, leakage, rain, and collision scenarios.
* **Phase 7:** Real ESP32 C++ firmware with local hardware failsafe (buzzer/LED/relay trip).
* **Phase 8:** Tabular AI model (Random Forest / XGBoost) for leakage severity & Pole Health Score.
* **Phase 9:** Computer Vision service (YOLOv8) detecting humans, animals, and standing water.
* **Phase 10:** Deterministic Multi-Layer Decision Engine computing Composite Risk Index ($0-100$) and risk tiers (`NORMAL`, `WARNING`, `CRITICAL`, `EMERGENCY`).
* **Phase 11:** RAG safety assistant using ChromaDB + configurable LLM with grounded citations.
* **Phase 12:** Work order lifecycle management, technician non-response timer, and supervisor/authority escalation.
* **Phase 13:** Offline-first mobile mode (SQLite local cache, action outbox) and ESP32 offline resilience.
* **Phase 14:** Incident report generation (PDF), audit logging, and judge-friendly Demo Control Panel.
* **Phase 15:** Final UI polish, end-to-end integration testing, and project defense preparation.
