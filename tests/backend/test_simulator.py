import pytest
from fastapi.testclient import TestClient
from backend.main import app
from scripts.simulate_telemetry import (
    generate_packet,
    generate_batch,
    DEFAULT_POLES
)

client = TestClient(app)


def test_generate_packet_normal():
    packet = generate_packet(pole_id="P-001", scenario="normal")
    assert packet["pole_id"] == "P-001"
    assert 1.0 <= packet["leakage_current_ma"] <= 5.0
    assert packet["rain_detected"] is False
    assert packet["is_simulated"] is True
    assert "recorded_at" in packet


def test_generate_packet_monsoon_leakage():
    packet = generate_packet(pole_id="P-002", scenario="monsoon_leakage")
    assert packet["pole_id"] == "P-002"
    assert packet["leakage_current_ma"] >= 30.0  # Exceeds IEC 60479 let-go threshold
    assert packet["touch_voltage_v"] >= 50.0
    assert packet["rain_detected"] is True
    assert packet["humidity_pct"] >= 90.0


def test_generate_packet_collision():
    packet = generate_packet(pole_id="P-003", scenario="collision")
    assert packet["pole_id"] == "P-003"
    assert packet["tilt_angle_deg"] >= 15.0  # Exceeds structural danger threshold
    assert packet["vibration_g"] >= 1.5      # Mechanical shock


def test_generate_packet_human_proximity():
    packet = generate_packet(pole_id="P-004", scenario="human_proximity")
    assert packet["pole_id"] == "P-004"
    assert packet["leakage_current_ma"] >= 25.0
    assert packet["rain_detected"] is True


def test_generate_packet_invalid_scenario():
    with pytest.raises(ValueError) as exc_info:
        generate_packet(pole_id="P-001", scenario="earthquake_supervolcano")
    assert "Unknown scenario" in str(exc_info.value)


def test_generate_batch():
    batch = generate_batch(pole_id="P-002", count=6, final_scenario="monsoon_leakage")
    assert batch["pole_id"] == "P-002"
    assert len(batch["readings"]) == 6

    # Verify chronological ordering
    readings = batch["readings"]
    for i in range(len(readings) - 1):
        assert readings[i]["recorded_at"] <= readings[i + 1]["recorded_at"]

    # First half should be normal, second half should be monsoon_leakage
    assert readings[0]["rain_detected"] is False
    assert readings[-1]["rain_detected"] is True
    assert readings[-1]["leakage_current_ma"] >= 30.0


def test_ingest_simulated_packets_via_api():
    # 1. Normal
    normal_pkt = generate_packet(pole_id="P-003", scenario="normal")
    resp1 = client.post("/api/v1/telemetry", json=normal_pkt)
    assert resp1.status_code == 201
    d1 = resp1.json()["data"]
    assert d1["risk_level"] == "NORMAL"
    assert d1["alert_triggered"] is False

    # 2. Monsoon Leakage
    monsoon_pkt = generate_packet(pole_id="P-001", scenario="monsoon_leakage")
    resp2 = client.post("/api/v1/telemetry", json=monsoon_pkt)
    assert resp2.status_code == 201
    d2 = resp2.json()["data"]
    assert d2["risk_level"] == "CRITICAL"
    assert d2["alert_triggered"] is True
    assert d2["deterministic_rule_tripped"] is True

    # 3. Collision
    collision_pkt = generate_packet(pole_id="P-002", scenario="collision")
    resp3 = client.post("/api/v1/telemetry", json=collision_pkt)
    assert resp3.status_code == 201
    d3 = resp3.json()["data"]
    assert d3["risk_level"] in ["HIGH_RISK", "CRITICAL"]
    assert d3["alert_triggered"] is True


def test_ingest_simulated_batch_via_api():
    batch_payload = generate_batch(pole_id="P-004", count=5, final_scenario="monsoon_leakage")
    resp = client.post("/api/v1/telemetry/batch", json=batch_payload)
    assert resp.status_code == 201
    res = resp.json()
    assert res["success"] is True
    assert res["data"]["processed_count"] == 5
    assert res["data"]["pole_id"] == "P-004"
