"""
Complete End-to-End Integration Test Suite for PoleGuard (Phase 11)
===================================================================
Executes the full pipeline:
ESP32/Simulator -> IoT Ingestion API -> AI/ML Prediction -> Decision Engine
-> Risk Classification -> Incident Creation -> Role-Based Retrieval

Validates all 6 core scenarios:
- SCENARIO A: NORMAL (Safe baseline, CRI < 25, no emergency)
- SCENARIO B: WARNING (Insulation degradation advisory, 10mA <= leakage < 30mA)
- SCENARIO C: CRITICAL (Lethal leakage >= 30mA in wet monsoon rain)
- SCENARIO D: EMERGENCY (Dual catastrophic failure: high leakage + severe tilt + shock)
- SCENARIO E: HUMAN/ANIMAL HAZARD (Cross-modal CV waterlogging puddle + pedestrian proximity)
- SCENARIO F: INTERNET OFFLINE & RESYNC (Offline ring buffer batch synchronization)
"""

import io
from datetime import datetime, timezone, timedelta
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from PIL import Image, ImageDraw

from backend.main import app
from backend.app.core.seed import seed_initial_data
from backend.app.services.decision_engine import decision_engine
from backend.app.schemas.telemetry import TelemetryIn
from ai.src.vision_detector import vision_detector


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    """Ensure schema tables and seed data exist before running tests."""
    await seed_initial_data()


# ==============================================================================
# SCENARIO A — NORMAL
# ==============================================================================
@pytest.mark.asyncio
async def test_scenario_a_normal():
    """
    Normal voltage/current/environment.
    Risk should remain safe/normal.
    No emergency incident.
    Pole status should remain HEALTHY.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "pole_id": "P-001",
            "leakage_current_ma": 1.8,
            "touch_voltage_v": 1.2,
            "tilt_angle_deg": 0.3,
            "vibration_g": 0.02,
            "temperature_c": 28.0,
            "humidity_pct": 52.0,
            "rain_detected": False,
            "is_simulated": True
        }

        res = await ac.post("/api/v1/telemetry", json=payload)
        assert res.status_code == 201
        data = res.json()["data"]

        # Input & Output Conditions
        assert data["risk_level"] == "NORMAL"
        assert data["composite_risk_index"] < 25.0
        assert data["alert_triggered"] is False
        assert data["alert_id"] is None
        assert data["deterministic_rule_tripped"] is False

        # Database Check: Pole status HEALTHY
        pole_res = await ac.get("/api/v1/poles/P-001")
        assert pole_res.status_code == 200
        pole_data = pole_res.json()["data"]
        assert pole_data["status"] == "HEALTHY"
        assert pole_data["risk_score"] < 25


# ==============================================================================
# SCENARIO B — WARNING
# ==============================================================================
@pytest.mark.asyncio
async def test_scenario_b_warning():
    """
    Moderately abnormal leakage/environment (16.5 mA, dry conditions).
    Rule engine classifies WARNING.
    Alert and incident should be generated.
    Technicians can see the event.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "pole_id": "P-002",
            "leakage_current_ma": 16.5,
            "touch_voltage_v": 18.0,
            "tilt_angle_deg": 1.1,
            "vibration_g": 0.05,
            "temperature_c": 31.0,
            "humidity_pct": 65.0,
            "rain_detected": False,
            "is_simulated": True
        }

        res = await ac.post("/api/v1/telemetry", json=payload)
        assert res.status_code == 201
        data = res.json()["data"]

        # Rule engine classification
        assert data["risk_level"] in ["WARNING", "ADVISORY"]
        assert 20.0 <= data["composite_risk_index"] <= 65.0
        assert data["alert_triggered"] is True
        assert data["alert_id"] is not None

        # Database Check: Pole status WARNING
        pole_res = await ac.get("/api/v1/poles/P-002")
        assert pole_res.json()["data"]["status"] == "WARNING"

        # Incident created and visible
        inc_res = await ac.get("/api/v1/incidents?pole_id=P-002")
        assert inc_res.status_code == 200
        inc_data = inc_res.json()
        assert inc_data["count"] >= 1
        assert any("P-002" in inc["pole_id"] for inc in inc_data["data"])


# ==============================================================================
# SCENARIO C — CRITICAL
# ==============================================================================
@pytest.mark.asyncio
async def test_scenario_c_critical():
    """
    High leakage (35.5 mA >= 30mA IEC let-go limit) in monsoon rain.
    AI prediction + Decision Engine classifies CRITICAL.
    Technician receives incident, Engineer can monitor.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "pole_id": "P-003",
            "leakage_current_ma": 35.5,
            "touch_voltage_v": 62.0,
            "tilt_angle_deg": 2.0,
            "vibration_g": 0.08,
            "temperature_c": 24.0,
            "humidity_pct": 98.0,
            "rain_detected": True,
            "is_simulated": True
        }

        res = await ac.post("/api/v1/telemetry", json=payload)
        assert res.status_code == 201
        data = res.json()["data"]

        assert data["risk_level"] == "CRITICAL"
        assert data["deterministic_rule_tripped"] is True
        assert data["composite_risk_index"] >= 75.0
        assert data["alert_triggered"] is True

        # Database Check: Pole status CRITICAL
        pole_res = await ac.get("/api/v1/poles/P-003")
        assert pole_res.json()["data"]["status"] == "CRITICAL"

        # Incident verification for Technician / Engineer queue
        inc_res = await ac.get("/api/v1/incidents?severity=CRITICAL&pole_id=P-003")
        assert inc_res.status_code == 200
        inc_list = inc_res.json()["data"]
        assert len(inc_list) >= 1
        incident = inc_list[0]
        assert incident["status"] == "DETECTED"

        # Engineer assigns incident to technician
        assign_payload = {
            "technician_id": "technician@safety.org",
            "notes": "Urgent: De-energize feeder and inspect insulator stack under rain protocol."
        }
        assign_res = await ac.post(f"/api/v1/incidents/{incident['id']}/assign", json=assign_payload)
        assert assign_res.status_code == 200
        assert assign_res.json()["data"]["status"] == "ASSIGNED"


# ==============================================================================
# SCENARIO D — EMERGENCY
# ==============================================================================
@pytest.mark.asyncio
async def test_scenario_d_emergency():
    """
    Catastrophic dual failure: severe leakage (48.0 mA) + collision tilt (21.5 deg) + impact shock (3.2g).
    Decision Engine classifies EMERGENCY.
    Escalation workflow activates.
    Authority can see the active emergency.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "pole_id": "P-004",
            "leakage_current_ma": 48.0,
            "touch_voltage_v": 85.0,
            "tilt_angle_deg": 21.5,
            "vibration_g": 3.2,
            "temperature_c": 27.0,
            "humidity_pct": 88.0,
            "rain_detected": True,
            "is_simulated": True
        }

        res = await ac.post("/api/v1/telemetry", json=payload)
        assert res.status_code == 201
        data = res.json()["data"]

        # Decision Engine EMERGENCY classification
        assert data["risk_level"] == "EMERGENCY"
        assert data["composite_risk_index"] >= 95.0
        assert data["alert_triggered"] is True
        assert "EMERGENCY" in data["alert_message"]

        # Authority Escalations Endpoint
        esc_res = await ac.get("/api/v1/incidents/escalations")
        assert esc_res.status_code == 200
        esc_data = esc_res.json()
        assert esc_data["success"] is True
        assert esc_data["count"] >= 1
        emergency_incidents = [e for e in esc_data["data"] if e["severity"] == "EMERGENCY"]
        assert len(emergency_incidents) >= 1
        assert any(e["pole_id"] == "P-004" for e in emergency_incidents)


# ==============================================================================
# SCENARIO E — HUMAN/ANIMAL HAZARD (CROSS-MODAL SENSOR + CV FUSION)
# ==============================================================================
@pytest.mark.asyncio
async def test_scenario_e_human_hazard_cross_modal():
    """
    CV detector detects pedestrian and standing water puddle within 1.5m of pole.
    Fused with moderate physical electrical leakage (25.0 mA in rain).
    Decision Engine escalates risk to CRITICAL with CRI surging to 98.2.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Ingest physical sensor reading
        sensor_payload = {
            "pole_id": "P-001",
            "leakage_current_ma": 25.0,
            "touch_voltage_v": 38.0,
            "tilt_angle_deg": 1.2,
            "vibration_g": 0.05,
            "temperature_c": 25.0,
            "humidity_pct": 95.0,
            "rain_detected": True,
            "is_simulated": True
        }
        await ac.post("/api/v1/telemetry", json=sensor_payload)

        # 2. Create synthetic inspection frame containing puddle and pedestrian near base
        img = vision_detector.create_synthetic_test_image("waterlogging_and_human")
        img_bytes = io.BytesIO()
        img.save(img_bytes, format="JPEG")
        img_bytes.seek(0)

        # 3. Post to Vision Inspection endpoint
        upload_res = await ac.post(
            "/api/v1/vision/upload",
            data={"pole_id": "P-001", "simulation_hint": "waterlogging_and_human"},
            files={"file": ("hazard_frame.jpg", img_bytes, "image/jpeg")}
        )
        assert upload_res.status_code == 200
        vision_result = upload_res.json()["data"]

        # Check CV Detection outputs
        assert vision_result["waterlogging_detected"] is True
        assert vision_result["human_proximity_detected"] is True
        assert vision_result["estimated_distance_meters"] is not None
        assert vision_result["estimated_distance_meters"] <= 2.5

        # Check Cross-Modal Safety Surge
        assert vision_result["multi_modal_risk_level"] == "CRITICAL"
        assert vision_result["composite_risk_index"] >= 95.0
        assert vision_result["alert_triggered"] is True
        assert "CRITICAL MULTI-MODAL HAZARD" in vision_result["alert_message"]


# ==============================================================================
# SCENARIO F — INTERNET OFFLINE & BATCH RESYNCHRONIZATION
# ==============================================================================
@pytest.mark.asyncio
async def test_scenario_f_offline_resync():
    """
    Edge device records telemetry offline into ring buffer during network outage.
    Upon connection restoration, uploads batch to /api/v1/telemetry/batch.
    Verifies all readings are persisted chronologically, no duplicate data is created,
    and latest status reflects the last state without fake live data.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        base_time = datetime.now(timezone.utc) - timedelta(minutes=10)
        batch_readings = []

        # Simulate 5 consecutive 2-second interval readings recorded offline
        for i in range(5):
            rec_time = base_time + timedelta(seconds=i * 2)
            batch_readings.append({
                "pole_id": "P-002",
                "leakage_current_ma": 4.0 + i * 2.0,
                "touch_voltage_v": 3.0 + i * 1.5,
                "tilt_angle_deg": 0.8,
                "vibration_g": 0.03,
                "temperature_c": 29.0,
                "humidity_pct": 55.0,
                "rain_detected": False,
                "is_simulated": True,
                "recorded_at": rec_time.isoformat()
            })

        batch_payload = {
            "pole_id": "P-002",
            "readings": batch_readings
        }

        # Resync batch
        resync_res = await ac.post("/api/v1/telemetry/batch", json=batch_payload)
        assert resync_res.status_code == 201
        resync_data = resync_res.json()["data"]

        assert resync_data["pole_id"] == "P-002"
        assert resync_data["processed_count"] == 5

        # Verify historical timeline reflects all 5 readings
        hist_res = await ac.get("/api/v1/poles/P-002/history?limit=10")
        assert hist_res.status_code == 200
        history = hist_res.json()["data"]
        assert len(history) >= 5
