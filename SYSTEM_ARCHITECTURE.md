# PoleGuard — System Architecture & Technical Specifications

PoleGuard is engineered with a multi-tier, modular architecture designed for high availability, sub-second edge response, and strict separation of concerns.

---

## 1. Architectural Topology

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                            │
│  Flutter Mobile App (Android / iOS / Desktop) + Interactive Web Preview │
│  - 5 Unified Roles (Citizen, Technician, Engineer, Authority, Admin)    │
│  - Provider State Management • Live GPS • ImagePicker • Localizations   │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ HTTP REST / WebSockets
┌────────────────────────────────────▼────────────────────────────────────┐
│                        API & INGESTION GATEWAY                          │
│  FastAPI Application Server (Port 8000)                                 │
│  - JWT / PBKDF2 Authentication & Staff Authorization Key Protection     │
│  - Static Uploads Mount (/uploads/) • WebSocket Telemetry Streamer      │
│  - 10 API Routers (Auth, Poles, Telemetry, Uploads, Reports, Incidents) │
└─────────────┬──────────────────────┬──────────────────────┬─────────────┘
              │                      │                      │
┌─────────────▼─────────┐ ┌──────────▼──────────┐ ┌─────────▼─────────────┐
│   PERSISTENCE LAYER   │ │     AI / ML LAYER   │ │   TELEMETRY PIPELINE  │
│ - PostgreSQL / SQLite │ │ - Random Forest Clf │ │ - Mock IoT Simulator  │
│ - SQLAlchemy Async ORM│ │ - YOLOv8 Spatial CV │ │ - ESP32 Firmware (C++)│
│ - 9 Normalized Tables │ │ - ChromaDB RAG Store│ │ - IEC 60479 Cutoff    │
└───────────────────────┘ └─────────────────────┘ └───────────────────────┘
```

---

## 2. Directory Structure & Module Responsibilities

```text
stressdetection/
├── backend/
│   ├── app/
│   │   ├── api/v1/          # 10 API Route Modules
│   │   │   ├── admin.py          # User management, audit logs, config
│   │   │   ├── alerts.py         # Alert listing and acknowledgment
│   │   │   ├── assistant.py      # ChromaDB RAG safety chatbot
│   │   │   ├── auth.py           # Login, staff registration, password reset
│   │   │   ├── hazard_reports.py # Multi-stage hazard report lifecycle
│   │   │   ├── incidents.py      # Work order dispatch, status, grid cutoff
│   │   │   ├── poles.py          # Pole registry, nearby Haversine lookup
│   │   │   ├── telemetry.py      # Telemetry ingestion and WebSocket stream
│   │   │   ├── uploads.py        # Multipart photo upload validation & save
│   │   │   └── vision.py         # CV spatial analysis & cross-modal fusion
│   │   ├── core/            # Config, database engine, RBAC, WebSocket manager
│   │   ├── models/          # SQLAlchemy entity models (9 tables)
│   │   ├── schemas/         # Pydantic validation schemas
│   │   └── services/        # AI classifier, CV detector, decision engine
│   ├── uploads/             # Server-side physical image storage
│   └── main.py              # FastAPI application root & static mount
│
├── frontend-mobile/         # Unified Flutter Mobile Application
│   ├── lib/
│   │   ├── core/            # AppTheme, constants, AppLocalizations (EN/HI/MR)
│   │   ├── models/          # PoleModel, HazardReportModel, IncidentModel, UserModel
│   │   ├── services/        # ApiClient, AuthService, LocationService, PhotoUploadService
│   │   ├── features/
│   │   │   ├── auth/screens/       # Splash, Welcome, RoleSelect, Login, SignUp, ForgotPassword
│   │   │   ├── citizen/screens/    # CitizenHome, CitizenReport, CitizenReports, CitizenChat
│   │   │   ├── technician/screens/ # TechnicianHome, TechnicianIncidents, TechnicianWork
│   │   │   ├── engineer/screens/   # EngineerHome, EngineerPoles, EngineerIncidents
│   │   │   ├── authority/screens/  # AuthorityHome, AuthorityEscalations, AuthorityZones
│   │   │   ├── admin/screens/      # AdminHome, AdminUsers, AdminAudit
│   │   │   ├── monitoring/screens/ # PoleDetailScreen, SensorTrendChart
│   │   │   ├── navigation/screens/ # RoleShellScreen (Dynamic 5-Role Tab Router)
│   │   │   └── common/screens/     # ProfileScreen, ConnectivityBanner, StatusBadge
│   └── pubspec.yaml         # Dependencies: provider, http, geolocator, image_picker
│
├── ai/                      # Machine learning training scripts and pickle artifacts
├── rag/                     # ChromaDB knowledge base and safety regulatory documents
├── esp32/                   # ESP32 firmware (FreeRTOS, dual ADC, local relay failsafe)
└── tests/                   # 60 Automated Pytest verification suites
```

---

## 3. Database Schema (9 Core Tables)

1. `users`: ID, email, hashed_password, full_name, role (`CITIZEN`, `TECHNICIAN`, `ENGINEER`, `AUTHORITY`, `ADMIN`), zone, is_active.
2. `poles`: ID, serial_number, name, address, area, latitude, longitude, zone, pole_type, installation_date, last_inspection_date, status.
3. `telemetry_readings`: ID, pole_id, timestamp, leakage_current_ma, touch_voltage_v, tilt_angle_deg, vibration_g, temperature_c, humidity_pct, rain_detected, is_simulated.
4. `incidents`: ID, pole_id, severity, status, description, created_at, acknowledged_at, resolved_at, resolved_by.
5. `work_orders`: ID, incident_id, technician_id, status, notes, created_at, updated_at.
6. `hazard_reports`: ID, reporter_id, reporter_name, reporter_phone, pole_id, latitude, longitude, address, hazard_type, description, image_url, status, assigned_technician_id, notes.
7. `alerts`: ID, pole_id, incident_id, severity, message, is_acknowledged, timestamp.
8. `audit_logs`: ID, user_id, action, target_entity, details, timestamp.
9. `password_resets`: ID, email, token, expires_at, is_used.
