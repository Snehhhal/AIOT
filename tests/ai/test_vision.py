import io
import os
import pytest
from fastapi.testclient import TestClient
from PIL import Image

from backend.main import app
from backend.app.schemas.telemetry import TelemetryIn
from backend.app.services.decision_engine import decision_engine
from ai.src.vision_detector import vision_detector

client = TestClient(app)


def test_vision_detector_synthetic_hazard_frame():
    # 1. Generate synthetic frame with water puddle and human
    img = vision_detector.create_synthetic_test_image("waterlogging_and_human", 640, 640)
    result = vision_detector.analyze_image(img, pole_id="P-001", simulation_hint="waterlogging_and_human")

    assert result["waterlogging_detected"] is True
    assert result["human_proximity_detected"] is True
    assert result["estimated_distance_meters"] is not None
    assert 0.3 <= result["estimated_distance_meters"] <= 3.0
    assert result["visual_hazard_score"] >= 0.85
    assert len(result["detected_objects"]) >= 2
    assert os.path.exists(result["annotated_image_path"])


def test_vision_detector_safe_frame():
    # 2. Generate clean baseline frame (pole only)
    img = vision_detector.create_synthetic_test_image("clear_daylight", 640, 640)
    result = vision_detector.analyze_image(img, pole_id="P-003", simulation_hint="clear_safe")

    assert result["waterlogging_detected"] is False
    assert result["human_proximity_detected"] is False
    assert result["visual_hazard_score"] <= 0.20


def test_cross_modal_decision_engine_surge():
    """
    Validates Scenario 4: A moderate leakage reading (28mA) that is nominal/advisory
    alone immediately surges to CRITICAL (CRI >= 95) when fused with computer vision
    evidence of a standing water puddle and a pedestrian at 1.2m.
    """
    telemetry = TelemetryIn(
        pole_id="P-004",
        leakage_current_ma=28.0,
        touch_voltage_v=42.0,
        tilt_angle_deg=1.1,
        vibration_g=0.03,
        temperature_c=25.0,
        humidity_pct=95.0,
        rain_detected=True,
        is_simulated=True
    )

    # 1. Without vision: 28mA is under the 30mA hard trip threshold
    eval_no_vision = decision_engine.evaluate_telemetry(telemetry, visual_hazard_score=0.0)
    assert eval_no_vision.deterministic_rule_tripped is False
    assert eval_no_vision.composite_risk_index < 85.0

    # 2. With vision fusion: standing puddle + pedestrian at 1.2m (hazard score = 0.96)
    eval_with_vision = decision_engine.evaluate_telemetry(
        telemetry=telemetry,
        visual_hazard_score=0.96,
        vision_details={"estimated_distance_meters": 1.2}
    )
    assert eval_with_vision.risk_level == "CRITICAL"
    assert eval_with_vision.alert_triggered is True
    assert eval_with_vision.deterministic_rule_tripped is True
    assert eval_with_vision.composite_risk_index >= 95.0
    assert "PEDESTRIAN" in eval_with_vision.alert_message.upper() or "WATERLOGGING" in eval_with_vision.alert_message.upper()


def test_vision_api_upload_and_fusion():
    """Tests the full HTTP upload endpoint and automated multi-modal fusion."""
    # First ingest a moderate telemetry reading for P-004
    client.post("/api/v1/telemetry", json={
        "pole_id": "P-004",
        "leakage_current_ma": 28.0,
        "touch_voltage_v": 45.0,
        "tilt_angle_deg": 1.0,
        "rain_detected": True,
        "is_simulated": True
    })

    # Generate test image in memory
    img = vision_detector.create_synthetic_test_image("waterlogging_and_human")
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    buf.seek(0)

    # Upload to /api/v1/vision/upload
    response = client.post(
        "/api/v1/vision/upload",
        data={"pole_id": "P-004", "simulation_hint": "waterlogging_and_human"},
        files={"file": ("field_inspection.jpg", buf, "image/jpeg")}
    )

    assert response.status_code == 200
    res = response.json()
    assert res["success"] is True
    data = res["data"]
    assert data["pole_id"] == "P-004"
    assert data["waterlogging_detected"] is True
    assert data["human_proximity_detected"] is True
    assert data["visual_hazard_score"] >= 0.85
    assert data["multi_modal_risk_level"] == "CRITICAL"
    assert data["composite_risk_index"] >= 95.0
    assert data["alert_triggered"] is True


def test_get_vision_inspections_endpoint():
    resp = client.get("/api/v1/vision/inspections/P-004")
    assert resp.status_code == 200
    res = resp.json()
    assert res["success"] is True
    assert res["data"]["pole_id"] == "P-004"
    assert res["data"]["has_recent_visual_alerts"] is True
