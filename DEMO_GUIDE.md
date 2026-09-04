# PoleGuard — Capstone Project Demonstration & Viva Presentation Guide

> **Final-Year B.Tech Capstone Project Defense**  
> **Project Title:** PoleGuard — AI & IoT Based Leakage Detection in Electric Pole and Life Safety  
> **Repository:** `https://github.com/Snehhhal/AIOT.git`

---

## 1. Executive Summary & 2-Minute Pitch

> *"Good morning, respected examiners. Across India, dozens of innocent citizens, children, and cattle lose their lives every monsoon due to invisible electric currents leaking into flooded roads and utility poles. Conventional circuit breakers fail to detect lethal low-level leakage ($50\text{ mA}\text{--}2\text{ A}$).*
>
> *Today, we present **PoleGuard**—a comprehensive cyber-physical life preservation system that combines real-time IoT sensing, an autonomous edge failsafe relay tripping in under 50 milliseconds, Random Forest machine learning with 98.3% classification accuracy, Computer Vision hazard fusion, an auditable mathematical Decision Engine computing a Composite Risk Index ($0-100$), a ChromaDB-grounded RAG safety assistant, and a single, unified Flutter mobile application dynamically serving five user roles with strict Role-Based Access Control."*

---

## 2. Pre-Demo Setup & Verification Checklist

Before inviting the evaluation panel, run the automated health check to confirm all services are operational:

1. **Terminal 1 — Run Automated Test Suite**:
   ```bash
   .venv\Scripts\activate
   pytest tests/ -v -o pythonpath=.
   ```
   *Verify:* **54 passed (100% pass rate)**. Show this terminal directly to the external examiner to prove system robustness.

2. **Terminal 2 — Start FastAPI Backend**:
   ```bash
   .venv\Scripts\activate
   uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   *Verify:* Navigating to `http://localhost:8000/health` returns `{"status":"ok","timestamp":...}`.  
   Interactive API docs: `http://localhost:8000/docs`.

3. **Open Mobile Application Preview**:
   - Open `app_preview.html` in Google Chrome or Microsoft Edge.
   - Or run Flutter mobile client on Android emulator / physical device:
     ```bash
     cd frontend-mobile
     flutter run
     ```

---

## 3. Demo Persona Credentials

| Role | Email | Password | Primary Mission during Demo |
| :--- | :--- | :--- | :--- |
| **Citizen** | `citizen@poleguard.gov` | `Citizen@123` | Demonstrates public safety: Green/Red map, 1-tap SOS hazard reporting with photo & GPS, multilingual voice alerts. |
| **Technician** | `tech@poleguard.gov` | `Tech@123` | Demonstrates field maintenance: Work orders, electrical isolation checklists, live sensor graphs, offline sync. |
| **Engineer** | `engineer@poleguard.gov` | `Engineer@123` | Demonstrates grid intelligence: Anomaly detection, fleet health telemetry, technician dispatch, AI diagnostics. |
| **Authority** | `authority@poleguard.gov` | `Authority@123` | Demonstrates disaster management: Escalation monitoring ($>15$ min delays), municipal risk map, authorized zone grid cutoff. |
| **Admin** | `admin@poleguard.gov` | `Admin@123` | Demonstrates governance: User lifecycle, sensor token provisioning, audit logs, interactive simulation controls. |

---

## 4. Step-by-Step Scenario Walkthrough for Evaluators

### Scenario A: Baseline Normal Operation
* **Objective:** Show the platform in nominal steady state.
* **Steps:**
  1. Login as **Technician** or view Pole `P-001` (Indiranagar Junction).
  2. Observe live sensor telemetry: Leakage Current: $2.1\text{ mA}$, Voltage: $1.2\text{ V}$, Tilt: $0.4^\circ$, Temperature: $29^\circ\text{C}$.
  3. Show the **Composite Risk Index (CRI)** is $<15$ (**NORMAL — Safe** with green status badge).
  4. Show the live **SensorTrendChart** displaying smooth, stable historical curves.

### Scenario B: Incipient Monsoon Leakage & Warning Tier
* **Objective:** Demonstrate early detection before public danger manifests.
* **Steps:**
  1. In the simulator or demo panel, trigger the **Monsoon Rain & Moisture Ingress** scenario on Pole `P-002`.
  2. Telemetry shifts: Humidity: $96\%$, Waterlogging Base: Detected, Leakage Current climbs to $38.4\text{ mA}$.
  3. The AI Random Forest classifier flags abnormal conductivity.
  4. Decision Engine raises CRI to $55$ (**WARNING — Attention Required** with yellow badge).
  5. An automatic preventive work order is generated in the system.

### Scenario C: Severe Leakage & Structural Tilt (Critical Tier)
* **Objective:** Demonstrate multi-sensor threshold escalation.
* **Steps:**
  1. Trigger **Severe Leakage & Tilt** on Pole `P-003` (Leakage: $85\text{ mA}$, Tilt: $14.2^\circ$).
  2. Decision Engine recalculates CRI to $78$ (**CRITICAL — Immediate Attention** with orange/red badge).
  3. The local buzzer alarm activates; high-priority push notification arrives on the Technician's mobile device with haptic vibration.
  4. Show the Technician's screen displaying the **Verified Electrical Isolation Checklist** (PPE verification, rubber insulating mat, circuit de-energization).

### Scenario D: Catastrophic Breakdown & Sub-50ms Edge Relay Failsafe
* **Objective:** Prove the autonomous physical edge protection mechanism.
* **Steps:**
  1. In the simulator or ESP32 firmware, inject catastrophic surge: Leakage Current: $185\text{ mA}$, Contact Voltage: $72\text{ V}$.
  2. **Sub-50ms Local Trip:** Even without waiting for backend cloud confirmation, the ESP32 hardware interrupt fires the isolation relay to sever supply to the pole.
  3. Status escalates to **EMERGENCY — Immediate Action Required** ($\text{CRI} \ge 95$).
  4. Switch to **Authority** role: Demonstrate that unacknowledged alerts escalate to the municipal disaster dashboard, where the commissioner can trigger a 1-tap **Authorized Zone Grid Cutoff**.

### Scenario E: Computer Vision & Multi-Modal Fusion
* **Objective:** Demonstrate visual defect verification and human proximity detection.
* **Steps:**
  1. In the inspection panel, upload or inspect a field image showing a damaged porcelain insulator and a pedestrian standing $<2\text{ meters}$ from a leaking pole base.
  2. The Computer Vision detector detects:
     - `human_present: true`, `distance_m: 1.4`
     - `waterlogged_surface: true`
     - `structural_defect: true`
  3. The Decision Engine fuses CV confidence with electrical telemetry, executing an emergency risk surge that elevates CRI to **98/100**.

### Scenario F: Offline Resilience & Cloud Synchronization
* **Objective:** Prove the mobile application functions during severe tropical storms with severed cellular data.
* **Steps:**
  1. In the mobile app, toggle the **"Offline Mode Simulation"** switch in the demo drawer.
  2. Note the yellow banner: *"Offline Mode Active — Queuing actions locally"*.
  3. Submit an incident hazard report with GPS and camera notes as a Citizen or complete an inspection as a Technician.
  4. Verify the action is saved locally in SQLite (`action_outbox` / `offline_reports`).
  5. Toggle Offline Mode OFF: Watch the automatic background sync engine transmit pending reports to the FastAPI backend with toast confirmation: *"Sync Complete — 1 local reports uploaded"*.

---

## 5. Demonstrating the RAG Safety Assistant

Click on the **"Safety RAG Assistant"** icon in the mobile app or web preview. Ask the following questions to showcase grounded technical retrieval:

1. **Query 1:** *"What are the safety clearance distances for 415V low-voltage distribution poles under the Indian Electricity Rules 1956?"*
   - *Expected Answer:* Detailed citation of Rule 77 (ground clearance $\ge 5.8\text{ meters}$) and Rule 79 (horizontal/vertical clearance from buildings).
2. **Query 2:** *"What is the maximum permissible touch voltage under IEEE 80 standards during wet monsoon conditions?"*
   - *Expected Answer:* Citation of IEEE Std 80 calculation of permissible touch voltage $V_{\text{touch}}$ based on body weight ($50\text{ kg} / 70\text{ kg}$) and surface gravel/pavement resistivity.
3. **Query 3:** *"What is the mandatory SOP before a technician touches a leaking pole?"*
   - *Expected Answer:* High-voltage insulating gloves ($1000\text{V}$ rated), rubber safety boots, visual arc-flash check, and verified upstream breaker tag-out.

---

## 6. Technical Viva Q&A — Defense Preparation

| Anticipated Examiner Question | Recommended Technical Defense |
| :--- | :--- |
| **Q1: Why did you use Random Forest instead of a Deep Neural Network (DNN) for sensor data?** | *"Tabular sensor data has low feature cardinality (7 key variables) and distinct physical boundary conditions. Random Forest requires negligible training overhead, is immune to overfitting on small sample sizes, provides deterministic feature importance, and executes inference in $<1.2\text{ ms}$, whereas DNNs introduce unnecessary inference latency and lack explainability."* |
| **Q2: Why not allow an LLM or ChatGPT to directly control the relay switch?** | *"Safety-critical systems must adhere to IEC 61508 / ISO 26262 functional safety standards. Generative LLMs are probabilistic, prone to hallucinations, and nondeterministic. In PoleGuard, all trip and cutoff actions are governed by hardware interrupts and mathematical decision rules. The LLM/RAG layer is strictly restricted to diagnostic explanation and SOP guidance."* |
| **Q3: How does the system prevent false alarms caused by rain or capacitive coupling?** | *"Capacitive coupling in rain produces micro-leakage ($<5\text{ mA}$) with zero contact voltage potential. PoleGuard uses multi-sensor correlation: leakage current is cross-checked with contact voltage (ZMPT101B) and phase angle. A warning is only triggered when both voltage and current cross verified thresholds."* |
| **Q4: Why build ONE unified Flutter application instead of separate apps for citizens and utility staff?** | *"Deploying, maintaining, and updating multiple APKs creates administrative overhead and version drift. With a single Flutter codebase and dynamic Role-Based Access Control (RBAC), authentication securely determines navigation routes and feature sets, while backend JWT verification guarantees that unauthorized roles receive HTTP 403 Forbidden."* |
| **Q5: What happens if the cellular network goes down during a cyclone?** | *"The system is designed with dual-layer offline autonomy: First, the ESP32 edge node makes instantaneous local relay decisions without internet. Second, the Flutter mobile app utilizes a local SQLite database and action outbox to cache citizen reports and technician logs, auto-syncing when connectivity resumes."* |
