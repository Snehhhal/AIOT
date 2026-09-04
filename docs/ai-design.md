# AI & Machine Learning Design

## 1. Overview

The intelligence layer combines two distinct AI paradigms:
1. **Tabular Machine Learning:** Real-time multi-sensor classification of electrical and structural stability.
2. **Computer Vision (YOLO):** Object detection and spatial proximity calculation from camera frames.
3. **Sensor-Vision Decision Engine:** A fusion module synthesizing numerical telemetry and visual detections into an actionable Composite Risk Index ($0 - 100$).

---

## 2. Tabular Leakage & Hazard Classifier

### 2.1 Problem Formulation
Classify physical time-series feature snapshots from a pole into four discrete hazard levels to filter out noisy sensor transients while never missing a dangerous leakage event.

### 2.2 Feature Vector Specifications

| Feature Name | Type | Range | Unit | Description |
| :--- | :--- | :--- | :--- | :--- |
| `leakage_current_ma` | Continuous | $0.0 - 500.0$ | $\text{mA}$ | Root Mean Square (RMS) leakage current on grounding line |
| `touch_voltage_v` | Continuous | $0.0 - 250.0$ | $\text{V}$ | Measured/estimated surface potential relative to earth |
| `tilt_angle_deg` | Continuous | $0.0 - 90.0$ | Degrees | Angle deviation from plumb vertical ($0^\circ$) |
| `vibration_g` | Continuous | $0.0 - 5.0$ | $g$ | RMS acceleration from structural impact or wind buffeting |
| `temperature_c` | Continuous | $-10.0 - 65.0$ | $^\circ\text{C}$ | Ambient enclosure temperature |
| `humidity_pct` | Continuous | $0.0 - 100.0$ | $\%$ | Relative ambient humidity |
| `rain_detected` | Binary | $0\text{ or }1$ | Flag | Digital indicator of surface water presence |

### 2.3 Target Classes & Safety Standards (IEC 60479-1 Alignment)

* **Class 0 - Normal (Safe):**
  - Current: $< 10\text{ mA}$
  - Pole upright, dry or mild weather. No physiological shock hazard.
* **Class 1 - Advisory (Insulation Warning):**
  - Current: $10 - 25\text{ mA}$
  - Early insulation degradation or high surface moisture conduction. Mild tingling threshold; requires scheduled inspection.
* **Class 2 - High Risk (Hazardous):**
  - Current: $25 - 50\text{ mA}$
  - "Let-go" threshold exceeded. Sustained contact causes involuntary muscle contraction and respiratory difficulty. Immediate isolation required.
* **Class 3 - Critical Emergency (Life Threatening):**
  - Current: $> 50\text{ mA}$ OR ($> 30\text{ mA}$ in combination with rain or $> 15^\circ$ tilt)
  - Ventricular fibrillation hazard; imminent risk of fatal electrocution. Immediate automated power cutoff & emergency siren dispatch.

### 2.4 Model Architectures & Selection

* **Primary Model:** **Random Forest Classifier** (`n_estimators=100`, `max_depth=12`).
  - *Rationale:* High resilience to sensor noise, non-linear feature interaction (e.g. current $\times$ rain), zero risk of gradient explosion, fast CPU inference ($< 5\text{ ms}$).
* **Alternative Model:** **XGBoost Classifier** (`learning_rate=0.1`, `n_estimators=150`).
  - *Rationale:* Higher precision in edge cases with subtle drift patterns.
* **Preprocessing Pipeline:**
  - Feature normalization via `StandardScaler`.
  - Serialized to disk using `joblib` inside `ai/models/`.

---

## 3. Computer Vision: YOLO Hazard & Proximity Detection

### 3.1 Model Architecture
* **Framework:** Ultralytics YOLOv8 (Nano `yolov8n` for edge or Small `yolov8s` for server-side processing).
* **Input Resolution:** $640 \times 640$ RGB frames.

### 3.2 Detection Classes
1. `human` (person walking or standing near pole)
2. `water_puddle` / `waterlogging` (reflective water accumulation near pole base)
3. `pole_base` (structural grounding point of the electric pole)
4. `sagging_wire` (loose or drooping overhead conductor)

### 3.3 Spatial Proximity Calculation
When both a `human` and `pole_base` are detected:
1. Extract bottom-center ground coordinates:
   $P_{\text{human}} = \left(\frac{x_1 + x_2}{2}, y_2\right)$, $P_{\text{pole}} = \left(\frac{x_1 + x_2}{2}, y_2\right)$.
2. Calculate Euclidean pixel distance $d_{\text{px}}$.
3. Map $d_{\text{px}}$ to approximate metric distance $D_{\text{meters}}$ using camera calibration / reference pole width.
4. If $D_{\text{meters}} < 2.5\text{ m}$ in the presence of waterlogging, set `human_proximity_hazard = True`.

---

## 4. Multi-Layer Decision Engine

The **Decision Engine** fuses tabular sensor predictions with visual inspection data to compute a **Composite Risk Index (CRI)** on a scale of $0 - 100$:

$$\text{CRI} = \min\left(100, \; w_I \cdot S_I + w_V \cdot S_V + w_T \cdot S_T + w_{\text{env}} \cdot S_{\text{env}} + w_{\text{vis}} \cdot S_{\text{vis}}\right)$$

Where:
* $S_I$: Normalized leakage current score ($0 - 100$, non-linear threshold exponential).
* $S_V$: Surface touch voltage score.
* $S_T$: Tilt severity score ($0$ for $< 5^\circ$, escalating to $100$ at $> 20^\circ$).
* $S_{\text{env}}$: Environmental multiplier ($1.5\times$ if rain detected with high humidity).
* $S_{\text{vis}}$: Visual hazard score from YOLO ($0 - 100$ based on human distance and waterlogging).

### Action Dispatch Rules:
* **$\text{CRI} < 30$:** Status **NORMAL**. Log telemetry periodically.
* **$30 \le \text{CRI} < 60$:** Status **ADVISORY**. Flag pole for routine maintenance.
* **$60 \le \text{CRI} < 85$:** Status **HIGH_RISK**. Trigger push notifications to field linemen, enable pole warning LED.
* **$\text{CRI} \ge 85$:** Status **CRITICAL**. Activate local acoustic siren, send instant SMS alert, dispatch emergency crew, and trigger simulated/hardware relay trip.
