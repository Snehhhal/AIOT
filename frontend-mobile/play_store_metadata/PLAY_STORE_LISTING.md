# PoleGuard — Google Play Store Listing Specification

## Application Metadata

* **App Title**: PoleGuard: AI & IoT Electric Safety
* **Short Description** (Max 80 chars):
  Real-time AI & IoT electric pole leakage detection, hazard alerts & life safety.
* **Category**: Utilities / Productivity / Safety
* **Content Rating**: Everyone (PEGI 3 / ESRB Everyone)
* **Target Audience**: Field Technicians, Distribution Engineers, Municipal Disaster Authorities, and Citizens
* **Default Language**: English (United States)
* **Supported Localizations**: English (`en`), Hindi (`hi`), Marathi (`mr`)

---

## Full Description (Max 4000 characters)

**PoleGuard** is an advanced AI and IoT-powered electrical safety and life preservation mobile platform engineered to eliminate electrocution hazards from urban and rural electricity distribution poles.

During monsoons, severe storms, or physical infrastructure degradation, damaged insulation and broken grounding can energize metallic utility poles and the surrounding waterlogged soil—creating invisible, lethal hazards for pedestrians, children, and stray animals. PoleGuard bridges physical edge sensors, machine learning, computer vision, and municipal disaster coordination into a unified, life-saving mobile platform.

### Key Capabilities & Features:

⚡ **Real-Time IoT Telemetry Streaming**
- Live monitoring of pole leakage current ($mA$), contact voltage ($V$), ultrasonic vibration, tilt/inclination, ambient humidity, and waterlogging level.
- High-frequency WebSocket streaming with dynamic interactive trend charts.
- Sub-50 millisecond edge relay failsafe triggering during catastrophic insulation breakdown.

🧠 **AI/ML & Computer Vision Multi-Modal Fusion**
- Multi-tier Random Forest ML classifier detecting structural faults, monsoon leakage, and vehicle collision impacts before catastrophic failure occurs.
- Computer vision detection of physical pole defects, insulator flashover, hanging conductor lines, and human proximity within hazardous shock radii.
- Real-time Composite Risk Index (CRI, 0–100) combining sensor analytics with visual evidence.

👥 **Dynamic Role-Based Access Control (RBAC) in a Single Unified App**
PoleGuard dynamically reconfigures its navigation and toolset depending on the authenticated user:
1. **Citizen**: One-tap emergency SOS reporting with camera evidence and GPS location; live safety map of nearby poles with clear green/yellow/red indicators; immediate multilingual voice and text alerts.
2. **Field Technician**: Work order assignment, step-by-step verified electrical isolation workflows, real-time pole telemetry feeds, and maintenance log completion.
3. **Distribution Engineer**: Grid zone monitoring, predictive failure trends, sensor calibration, AI model diagnostics, and work order delegation.
4. **Disaster Management Authority**: Municipal crisis dashboard, high-level risk overview, emergency service dispatch, and authorized zone-wide grid cutoff controls.
5. **System Administrator**: User lifecycle management, RBAC permission auditing, edge sensor provisioning, and immutable system audit logs.

🤖 **RAG-Powered Electrical Safety Assistant**
- Built-in retrieval-augmented safety chatbot trained on Indian Electricity Rules (1956), IEEE 80 grounding regulations, and OSHA distribution safety protocols.
- Instant, verified safety guidelines and grounding checklists tailored to current pole risk factors.

🌐 **Offline-First Resilience & Multilingual Support**
- Full offline SQLite local caching with automatic background synchronization when cellular or Wi-Fi connectivity resumes.
- Native instant toggle between English, हिन्दी (Hindi), and मराठी (Marathi).

---

## What's New in Version 1.0.0
- Initial stable production release of the PoleGuard safety platform.
- Full 5-role dynamic interface in a single lightweight application.
- Real-time WebSocket telemetry with interactive multi-sensor graphs.
- AI Decision Engine with Composite Risk Index (0–100) scoring.
- Multilingual safety guidance (English, Hindi, Marathi).
- Offline-first local SQLite cache with automatic cloud reconciliation.

---

## Contact & Support
* **Developer**: Department of Computer Engineering
* **Project**: Capstone B.Tech Engineering Project — PoleGuard
* **Website / Repo**: https://github.com/Snehhhal/AIOT.git
