from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)


def test_ingest_normal_telemetry():
    payload = {
        "pole_id": "POLE-101",
        "leakage_current_ma": 2.5,
        "touch_voltage_v": 1.0,
        "tilt_angle_deg": 0.5,
        "rain_detected": False,
        "is_simulated": True
    }
    response = client.post("/api/v1/telemetry", json=payload)
    assert response.status_code == 201
    res = response.json()
    assert res["success"] is True
    data = res["data"]
    assert data["risk_level"] == "NORMAL"
    assert data["alert_triggered"] is False


def test_ingest_critical_leakage_in_rain():
    payload = {
        "pole_id": "POLE-102",
        "leakage_current_ma": 45.0,
        "touch_voltage_v": 72.0,
        "tilt_angle_deg": 1.2,
        "rain_detected": True,
        "is_simulated": True
    }
    response = client.post("/api/v1/telemetry", json=payload)
    assert response.status_code == 201
    res = response.json()
    assert res["success"] is True
    data = res["data"]
    assert data["risk_level"] == "CRITICAL"
    assert data["alert_triggered"] is True
    assert data["deterministic_rule_tripped"] is True
