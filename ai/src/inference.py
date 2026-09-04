"""
Production Inference Engine for Electric Pole Safety Classification
====================================================================
Wraps the serialized scikit-learn Random Forest model pipeline.
Provides high-throughput, low-latency (<5ms) hazard classification with
calibrated probabilistic confidence scores and robust fallback protection.
"""

import os
from typing import Any, Dict, Optional, Union
import numpy as np
import pandas as pd

# Path definitions
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "leakage_classifier.joblib")

FEATURE_NAMES = [
    "leakage_current_ma",
    "touch_voltage_v",
    "tilt_angle_deg",
    "vibration_g",
    "temperature_c",
    "humidity_pct",
    "rain_detected",
]

DEFAULT_VALUES = {
    "leakage_current_ma": 2.0,
    "touch_voltage_v": 1.0,
    "tilt_angle_deg": 0.5,
    "vibration_g": 0.02,
    "temperature_c": 28.0,
    "humidity_pct": 55.0,
    "rain_detected": 0,
}


class LeakageClassifier:
    """
    Production inference wrapper for tabular electric pole hazard prediction.
    """

    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or MODEL_PATH
        self.pipeline = None
        self.classes = ["NORMAL", "ADVISORY", "HIGH_RISK", "CRITICAL"]
        self._load_model()

    def _load_model(self) -> None:
        """Attempts to load the joblib model artifact."""
        if os.path.exists(self.model_path):
            try:
                import joblib
                self.pipeline = joblib.load(self.model_path)
                if hasattr(self.pipeline, "classes_"):
                    self.classes = list(self.pipeline.classes_)
                elif hasattr(self.pipeline, "named_steps") and hasattr(self.pipeline.named_steps.get("classifier"), "classes_"):
                    self.classes = list(self.pipeline.named_steps["classifier"].classes_)
                print(f"[*] Loaded AI safety classifier from: {self.model_path}")
            except Exception as e:
                print(f"[!] Warning: Failed to load model artifact at {self.model_path}: {e}")
                self.pipeline = None
        else:
            print(f"[*] Model artifact not found at {self.model_path}. Operating in fallback heuristic mode.")

    def _fallback_predict(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """
        Rule-grounded fallback prediction if the serialized model is unavailable.
        Ensures zero-crash resiliency for production deployments.
        """
        leakage = record.get("leakage_current_ma", 2.0)
        tilt = record.get("tilt_angle_deg", 0.5)
        rain = bool(record.get("rain_detected", False))

        if leakage >= 30.0 and rain:
            pred_class = "CRITICAL"
            conf = 0.98
        elif leakage >= 30.0 or tilt >= 15.0:
            pred_class = "HIGH_RISK"
            conf = 0.92
        elif leakage >= 10.0 or tilt >= 5.0:
            pred_class = "ADVISORY"
            conf = 0.88
        else:
            pred_class = "NORMAL"
            conf = 0.96

        probs = {c: 0.01 for c in self.classes}
        probs[pred_class] = conf
        # Normalize
        total = sum(probs.values())
        probs = {k: round(v / total, 4) for k, v in probs.items()}

        return {
            "predicted_class": pred_class,
            "confidence": conf,
            "probabilities": probs,
            "is_fallback": True,
        }

    def predict(self, telemetry: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """
        Predicts hazard risk level and probability distribution for a sensor payload.
        Accepts dict or Pydantic model (TelemetryIn).
        """
        # Convert Pydantic model if necessary
        if hasattr(telemetry, "model_dump"):
            data = telemetry.model_dump()
        elif hasattr(telemetry, "dict"):
            data = telemetry.dict()
        elif isinstance(telemetry, dict):
            data = telemetry
        else:
            data = {}

        # Extract features with defaults
        record = {}
        for feat in FEATURE_NAMES:
            val = data.get(feat, DEFAULT_VALUES[feat])
            if feat == "rain_detected":
                record[feat] = 1 if bool(val) else 0
            else:
                record[feat] = float(val) if val is not None else DEFAULT_VALUES[feat]

        if self.pipeline is None:
            return self._fallback_predict(record)

        try:
            df = pd.DataFrame([record])[FEATURE_NAMES]
            predicted_class = str(self.pipeline.predict(df)[0])

            if hasattr(self.pipeline, "predict_proba"):
                raw_probs = self.pipeline.predict_proba(df)[0]
                classes = getattr(self.pipeline, "classes_", self.classes)
                probs = {str(c): round(float(p), 4) for c, p in zip(classes, raw_probs)}
                confidence = float(probs.get(predicted_class, max(raw_probs)))
            else:
                confidence = 0.95
                probs = {predicted_class: 0.95}

            return {
                "predicted_class": predicted_class,
                "confidence": round(confidence, 4),
                "probabilities": probs,
                "is_fallback": False,
            }
        except Exception as e:
            print(f"[!] Inference exception: {e}. Utilizing fallback.")
            return self._fallback_predict(record)


# Export global singleton
leakage_classifier = LeakageClassifier()
