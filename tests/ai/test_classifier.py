import json
import os
import pytest
import pandas as pd
from ai.src.generate_dataset import generate_synthetic_data
from ai.src.inference import LeakageClassifier, leakage_classifier
from backend.app.schemas.telemetry import TelemetryIn
from backend.app.services.decision_engine import decision_engine

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_PATH = os.path.join(BASE_DIR, "ai", "models", "leakage_classifier.joblib")
METADATA_PATH = os.path.join(BASE_DIR, "ai", "models", "model_metadata.json")


def test_synthetic_dataset_generation():
    df = generate_synthetic_data(num_samples=200, random_seed=123)
    assert isinstance(df, pd.DataFrame)
    assert len(df) == 200
    assert df["risk_class"].nunique() == 4
    assert df.isnull().sum().sum() == 0

    expected_cols = [
        "leakage_current_ma",
        "touch_voltage_v",
        "tilt_angle_deg",
        "vibration_g",
        "temperature_c",
        "humidity_pct",
        "rain_detected",
        "risk_label",
        "risk_class"
    ]
    for col in expected_cols:
        assert col in df.columns


def test_model_artifacts_and_metrics():
    if not os.path.exists(MODEL_PATH) or not os.path.exists(METADATA_PATH):
        from ai.src.train_classifier import main as train_main
        train_main()

    assert os.path.exists(MODEL_PATH), f"Model binary missing at {MODEL_PATH}"
    assert os.path.exists(METADATA_PATH), f"Metadata missing at {METADATA_PATH}"

    with open(METADATA_PATH, "r", encoding="utf-8") as f:
        meta = json.load(f)

    assert meta["model_type"] == "RandomForestClassifier"
    assert meta["test_accuracy"] >= 0.95
    assert meta["cv_mean_accuracy"] >= 0.95
    assert "leakage_current_ma" in meta["feature_importances"]


def test_inference_normal_telemetry():
    result = leakage_classifier.predict({
        "leakage_current_ma": 2.1,
        "touch_voltage_v": 1.2,
        "tilt_angle_deg": 0.5,
        "vibration_g": 0.02,
        "temperature_c": 29.0,
        "humidity_pct": 50.0,
        "rain_detected": False
    })
    assert result["predicted_class"] == "NORMAL"
    assert result["confidence"] >= 0.90
    assert result["is_fallback"] is False


def test_inference_monsoon_leakage_critical():
    result = leakage_classifier.predict({
        "leakage_current_ma": 52.0,
        "touch_voltage_v": 78.0,
        "tilt_angle_deg": 1.5,
        "vibration_g": 0.08,
        "temperature_c": 24.0,
        "humidity_pct": 96.0,
        "rain_detected": True
    })
    assert result["predicted_class"] == "CRITICAL"
    assert result["confidence"] >= 0.85
    assert "CRITICAL" in result["probabilities"]


def test_inference_collision_hazard():
    result = leakage_classifier.predict({
        "leakage_current_ma": 4.5,
        "touch_voltage_v": 3.0,
        "tilt_angle_deg": 26.0,
        "vibration_g": 2.8,
        "temperature_c": 28.0,
        "humidity_pct": 55.0,
        "rain_detected": False
    })
    assert result["predicted_class"] in ["CRITICAL", "HIGH_RISK"]
    assert result["confidence"] >= 0.50


def test_decision_engine_ai_integration():
    telemetry = TelemetryIn(
        pole_id="P-001",
        leakage_current_ma=2.2,
        touch_voltage_v=1.1,
        tilt_angle_deg=0.4,
        vibration_g=0.01,
        temperature_c=28.0,
        humidity_pct=48.0,
        rain_detected=False,
        is_simulated=True
    )

    evaluation = decision_engine.evaluate_telemetry(telemetry)
    assert evaluation.pole_id == "P-001"
    assert evaluation.risk_level == "NORMAL"
    assert evaluation.ai_predicted_class == "NORMAL"
    assert isinstance(evaluation.ai_confidence, float)
    assert 0.0 <= evaluation.ai_confidence <= 1.0
    assert evaluation.composite_risk_index < 25.0
