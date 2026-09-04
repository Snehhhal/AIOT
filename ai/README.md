# AI & Machine Learning Subsystem

This subsystem implements:
1. **Tabular Hazard Classifier:** Multi-sensor risk classification model (Random Forest) trained on physics-grounded telemetry.
2. **Computer Vision (YOLOv8):** Detects standing waterlogging puddles around pole bases, human proximity distance, and physical cable defects.

---

## 1. Tabular Hazard Classifier

### 1.1 Architecture & Problem Formulation
Classifies incoming multi-sensor telemetry into four discrete hazard states:
* `0: NORMAL` (Steady-state operation, $I < 10\,\text{mA}$, $\theta_{\text{tilt}} < 5^\circ$)
* `1: ADVISORY` (Early insulation fatigue $10\text{--}28\,\text{mA}$, or moderate tilt $5\text{--}14^\circ$)
* `2: HIGH_RISK` (Severe leakage $>30\,\text{mA}$, or hazardous tilt $>15^\circ$)
* `3: CRITICAL` (Compound monsoon leakage $>30\,\text{mA}$ with rain, or structural collision $>20^\circ$ with vibration $>1.5\,g$)

### 1.2 Training Methodology (Strict ML Best Practices)
* **Strict Featurization Ordering:** 80/20 train/test partition performed **before** fitting the `StandardScaler` ColumnTransformer to prevent data leakage.
* **Model Selection:**
  - Baseline: Logistic Regression (CV Accuracy: $99.47\%$)
  - Production Model: Random Forest Classifier ($100$ estimators, `max_depth=12`, CV Accuracy: $100.0\%$)
* **Validation:** Stratified 5-Fold Cross-Validation on training split.
* **Held-out Test Performance:** $100.0\%$ Accuracy across $800$ test samples ($200$ per class).

### 1.3 Feature Importances
| Feature | Importance | Physical Rationale |
| :--- | :--- | :--- |
| `touch_voltage_v` | **$22.16\%$** | Direct indicator of chassis touch potential hazard |
| `leakage_current_ma` | **$21.51\%$** | Primary IEC 60479 let-go threshold indicator |
| `vibration_g` | **$21.05\%$** | Distinguishes physical impact / collision shock from steady states |
| `tilt_angle_deg` | **$20.69\%$** | Indicates structural foundation fatigue or pole toppling |
| `humidity_pct` | **$8.94\%$** | Environmental breakdown catalyst |
| `temperature_c` | **$3.19\%$** | Cable insulation thermal fatigue |
| `rain_detected` | **$2.46\%$** | Binary multiplier elevating touch contact danger |

---

## 2. Directory Layout

* `data/`:
  - `pole_safety_dataset.csv`: 4,000 balanced synthetic samples across all 4 hazard classes.
* `models/`:
  - `leakage_classifier.joblib`: Serialized scikit-learn Pipeline (Preprocessor + Classifier).
  - `model_metadata.json`: Provenance metadata, confusion matrix, and feature importances.
* `src/`:
  - `generate_dataset.py`: Physics-grounded synthetic telemetry generator.
  - `train_classifier.py`: Training pipeline with cross-validation and evaluation metrics.
  - `inference.py`: High-throughput production inference class (`LeakageClassifier`).

---

## 3. Python Usage & Inference Example

```python
from ai.src.inference import leakage_classifier

# Example 1: Nominal steady reading
res = leakage_classifier.predict({
    "leakage_current_ma": 2.1,
    "touch_voltage_v": 1.2,
    "tilt_angle_deg": 0.4,
    "vibration_g": 0.02,
    "temperature_c": 28.5,
    "humidity_pct": 52.0,
    "rain_detected": False
})
print(res)
# Output: {'predicted_class': 'NORMAL', 'confidence': 1.0, ...}

# Example 2: Monsoon breakdown alert
res = leakage_classifier.predict({
    "leakage_current_ma": 48.0,
    "touch_voltage_v": 72.0,
    "tilt_angle_deg": 1.5,
    "vibration_g": 0.08,
    "temperature_c": 24.0,
    "humidity_pct": 96.0,
    "rain_detected": True
})
print(res)
# Output: {'predicted_class': 'CRITICAL', 'confidence': 0.94, ...}
```

---

## 4. Integration with Decision Engine

The trained model is directly wired into **Layer 2** of the FastAPI Decision Engine (`backend/app/services/decision_engine.py`):
1. **Layer 1 (Deterministic Hard Constraints):** Immediate hardware failsafe trip if $I \ge 30\,\text{mA}$ or $\theta \ge 15^\circ$.
2. **Layer 2 (Machine Learning Inference):** Random Forest evaluates multi-sensor telemetry to assign hazard class and confidence score.
3. **Layer 3 (Composite Risk Index - CRI):** Fuses physical leakage ($40\%$), touch voltage ($15\%$), structural tilt ($15\%$), AI risk probability ($15\%$), and computer vision ($15\%$), scaled by environmental multipliers.
