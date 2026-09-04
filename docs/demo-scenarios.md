# Demonstration Scenarios & Evaluation Walkthroughs

## 1. Overview

This document outlines five end-to-end demonstration scenarios for academic presentation, software defense, and hardware validation. Each scenario can be executed using either **Simulation Mode** (`scripts/simulate_telemetry.py`) or **Real Hardware Mode** (ESP32).

---

## 2. Scenario 1: Baseline Normal Operational State

### 2.1 Objective
Demonstrate steady-state telemetry streaming, dashboard map visualization, and zero false-positive alert behavior under benign conditions.

### 2.2 Input Parameters
* **Pole ID:** `POLE-101`
* **Leakage Current:** $2.4\,\text{mA}$ (Well below $10\,\text{mA}$ threshold)
* **Touch Voltage:** $1.2\,\text{V}$
* **Tilt Angle:** $0.4^\circ$
* **Rain Detected:** `False`
* **Humidity:** $45\%$

### 2.3 System Behavior
1. Ingestion endpoint `/api/v1/telemetry` logs entry to `telemetry_logs`.
2. Decision Engine computes Composite Risk Index $\text{CRI} = 4.2 / 100$.
3. AI Classifier outputs `NORMAL` (Confidence: $99.4\%$).
4. Dashboard shows green status badge; zero alerts emitted.

---

## 3. Scenario 2: Monsoon Rain & Insulation Breakdown (High Risk Alert)

### 3.1 Objective
Demonstrate real-time detection of weather-induced electrical leakage, automated classification, and instant alert dispatch.

### 3.2 Input Parameters
* **Pole ID:** `POLE-102`
* **Leakage Current:** $38.5\,\text{mA}$ (Dangerous threshold exceeded)
* **Touch Voltage:** $62.0\,\text{V}$
* **Tilt Angle:** $1.1^\circ$
* **Rain Detected:** `True`
* **Humidity:** $96\%$

### 3.3 System Behavior
1. Decision Engine flags deterministic rule breach ($I > 30\,\text{mA}$ with rain).
2. AI Classifier predicts `HIGH_RISK` (Confidence: $96.8\%$).
3. Decision Engine computes $\text{CRI} = 81.5 / 100$.
4. New alert created in PostgreSQL: `SEVERITY: HIGH`, `TYPE: CURRENT_LEAKAGE`.
5. WebSocket `/ws/alerts` instantly pushes alert to React dashboard, sounding audible notification and highlighting pole marker in pulsing orange.
6. Push notification queued for registered sector linemen.

---

## 4. Scenario 3: Vehicular Collision & Structural Pole Tilt

### 4.1 Objective
Demonstrate multi-sensor detection of physical infrastructure damage independently of electrical leakage.

### 4.2 Input Parameters
* **Pole ID:** `POLE-103`
* **Leakage Current:** $5.1\,\text{mA}$ (Normal)
* **Touch Voltage:** $3.0\,\text{V}$
* **Tilt Angle:** $24.5^\circ$ (Severe tilt $> 15^\circ$)
* **Vibration:** $2.8\,g$ (Impact spike)
* **Rain Detected:** `False`

### 4.3 System Behavior
1. Decision Engine identifies structural impact: $\theta_{\text{tilt}} > 15^\circ$ and $\text{vibration} > 1.5\,g$.
2. Calculated $\text{CRI} = 88.0 / 100$.
3. Alert generated: `SEVERITY: CRITICAL`, `TYPE: POLE_TILT_STRUCTURAL_HAZARD`.
4. Dashboard map marks pole with red warning icon; system flags overhead wire collapse hazard.

---

## 5. Scenario 4: Computer Vision Fusion (Waterlogging + Human Proximity)

### 5.1 Objective
Demonstrate AI cross-modal sensor-vision fusion, where a visual detection escalates a moderate electrical fault into an emergency alert.

### 5.2 Sequence
1. Pole `POLE-104` reports moderate leakage ($28\,\text{mA}$) during rain.
2. Field inspection camera or CCTV stream uploads frame to `/api/v1/vision/upload`.
3. YOLOv8 model detects:
   - `human` at ground coordinates $[x=250, y=580]$ (Confidence: $94\%$).
   - `waterlogging` puddle at base $[x=100, y=600]$ (Confidence: $89\%$).
   - Estimated human distance to energized pole base: $1.2\,\text{meters}$.
4. Decision Engine fuses sensor reading ($28\,\text{mA}$) + visual evidence (waterlogging + human at $1.2\,\text{m}$).
5. Composite Risk Index surges from $55$ to **$98 / 100$** (`CRITICAL EMERGENCY`).
6. Simulated/Hardware trip signal issued; emergency perimeter alert broadcast.

---

## 6. Scenario 5: Lineman Safety RAG Query & Emergency SOP

### 6.1 Objective
Demonstrate how field workers use natural language to retrieve statutory safety operating procedures before entering a hazardous zone.

### 6.2 Sequence
1. Lineman on mobile app navigates to Safety Assistant tab for pole `POLE-102` (in alarm).
2. Lineman enters query:
   > *"What mandatory precautions must I take before isolating pole P-102 showing 38mA leakage in standing water?"*
3. Endpoint `/api/v1/assistant/query` retrieves top relevant chunks from ChromaDB (CEA Regulations 2010 + Lineman Monsoon SOP).
4. Configured LLM synthesizes actionable response:
   - Mandatory PPE: Class 0 (1000V) gloves + dielectric overshoes.
   - Prohibited actions: Do not step directly into the puddle; shuffle feet to avoid step-potential.
   - Verification: Use certified high-voltage detector stick; request upstream feeder isolation.
   - Exact citations displayed to user.
