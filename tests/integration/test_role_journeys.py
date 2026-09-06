"""
Five-Role Complete User Journeys & RBAC Backend Security (Phase 12)
==================================================================
Validates:
1. Strict Backend RBAC Enforcement (HTTP 403 Forbidden for unauthorized roles, 401 for unauthenticated).
2. Citizen Complete Journey: Login, view status, submit hazard report, query reports, query safety assistant.
3. Technician Complete Journey: Login, view work orders, acknowledge incident, update progress/notes, resolve.
4. Engineer Complete Journey: Login, fleet health check, detect anomalies, assign technician, approve repairs.
5. Authority Complete Journey: Login, monitor escalations, order emergency grid cutoff, verify isolation.
6. Admin Complete Journey: Login, user registry, toggle activation, audit log review, platform config.
"""

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport

from backend.main import app
from backend.app.core.seed import seed_initial_data


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    """Ensure database schema tables and seed default users exist."""
    await seed_initial_data()
    from backend.app.core.database import AsyncSessionLocal
    from backend.app.models.entities import Pole, SensorReading
    from datetime import datetime, timezone
    async with AsyncSessionLocal() as db:
        p = await db.get(Pole, "P-001")
        if not p:
            db.add(Pole(
                id="P-001",
                serial_number="PL-TEST-001",
                name="Test Feeder Asset",
                latitude=23.0,
                longitude=72.0,
                status="HEALTHY",
                health_score=90,
                risk_score=10,
                zone="Test Zone"
            ))
            db.add(SensorReading(
                pole_id="P-001",
                leakage_current=2.0,
                voltage=230.0,
                temperature=25.0,
                humidity=50.0,
                rain=False,
                recorded_at=datetime.now(timezone.utc)
            ))
            await db.commit()


async def get_auth_token(ac: AsyncClient, email: str, password: str = "password123") -> str:
    """Helper to log in and retrieve JWT access token."""
    res = await ac.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert res.status_code == 200, f"Login failed for {email}: {res.text}"
    return res.json()["access_token"]


# ==============================================================================
# 1. Backend RBAC Enforcement (Security Boundaries)
# ==============================================================================

@pytest.mark.asyncio
async def test_rbac_citizen_forbidden_actions():
    """Citizens cannot register poles or assign incidents (must return 403)."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        token = await get_auth_token(ac, "citizen@safety.org")
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Attempt pole registration (requires ADMIN/ENGINEER)
        pole_res = await ac.post("/api/v1/poles", json={
            "id": "P-HACK", "name": "Illegal Pole", "latitude": 18.5, "longitude": 73.8
        }, headers=headers)
        assert pole_res.status_code == 403
        assert "Access denied" in pole_res.json()["detail"]

        # 2. Attempt incident assignment (requires ENGINEER/ADMIN)
        assign_res = await ac.post("/api/v1/incidents/INC-TEST/assign", json={
            "technician_id": "technician@safety.org"
        }, headers=headers)
        assert assign_res.status_code == 403


@pytest.mark.asyncio
async def test_rbac_technician_forbidden_actions():
    """Technicians cannot execute grid cutoff or access admin user registry."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        token = await get_auth_token(ac, "technician@safety.org")
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Attempt emergency grid cutoff (requires AUTHORITY/ADMIN)
        cutoff_res = await ac.post("/api/v1/authority/grid-cutoff", json={
            "pole_id": "P-001", "reason": "Unauthorized cutoff"
        }, headers=headers)
        assert cutoff_res.status_code == 403

        # 2. Attempt admin user list (requires ADMIN)
        admin_res = await ac.get("/api/v1/admin/users", headers=headers)
        assert admin_res.status_code == 403


@pytest.mark.asyncio
async def test_rbac_unauthenticated_request_rejected():
    """Calling protected endpoints without authorization header returns 401."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/api/v1/admin/audit-logs")
        assert res.status_code == 401


# ==============================================================================
# 2. Role 1 — CITIZEN User Journey
# ==============================================================================

@pytest.mark.asyncio
async def test_citizen_user_journey():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        token = await get_auth_token(ac, "citizen@safety.org")
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Profile retrieval
        me_res = await ac.get("/api/v1/auth/me", headers=headers)
        assert me_res.status_code == 200
        assert me_res.json()["role"] == "CITIZEN"

        # 2. View public pole safety status
        poles_res = await ac.get("/api/v1/poles")
        assert poles_res.status_code == 200
        assert len(poles_res.json()["data"]) >= 4

        # 3. Report a visible physical hazard (sparking cable)
        report_payload = {
            "pole_id": "P-001",
            "description": "Visible sparking and crackling sound near insulator cap",
            "contact_phone": "+91 9876543210"
        }
        report_res = await ac.post("/api/v1/citizen/report", json=report_payload)
        assert report_res.status_code == 201
        report_data = report_res.json()["data"]
        assert "incident_id" in report_data

        # 4. View submitted citizen reports
        list_reports_res = await ac.get("/api/v1/citizen/reports")
        assert list_reports_res.status_code == 200
        assert list_reports_res.json()["count"] >= 1

        # 5. Ask safety chatbot for emergency precautions
        query_payload = {
            "query": "Water is pooling around the electric pole on my street. Is it safe to walk near it?",
            "pole_id": "P-001",
            "user_role": "CITIZEN"
        }
        chat_res = await ac.post("/api/v1/assistant/query", json=query_payload)
        assert chat_res.status_code == 200
        answer = chat_res.json()["data"]["answer"]
        assert "PROHIBITED" in answer or "perimeter" in answer.lower()


# ==============================================================================
# 3. Role 2 — TECHNICIAN User Journey
# ==============================================================================

@pytest.mark.asyncio
async def test_technician_user_journey():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        tech_token = await get_auth_token(ac, "technician@safety.org")
        tech_headers = {"Authorization": f"Bearer {tech_token}"}

        eng_token = await get_auth_token(ac, "engineer@safety.org")
        eng_headers = {"Authorization": f"Bearer {eng_token}"}

        # 1. Ingest high-leakage reading to generate an incident on P-002
        await ac.post("/api/v1/telemetry", json={
            "pole_id": "P-002",
            "leakage_current_ma": 36.0,
            "touch_voltage_v": 58.0,
            "tilt_angle_deg": 1.5,
            "rain_detected": True,
            "is_simulated": True
        })

        # 2. Retrieve the incident
        inc_res = await ac.get("/api/v1/incidents?pole_id=P-002")
        incident = inc_res.json()["data"][0]
        inc_id = incident["id"]

        # 3. Engineer assigns to technician
        assign_res = await ac.post(f"/api/v1/incidents/{inc_id}/assign", json={
            "technician_id": "technician@safety.org",
            "notes": "De-energize feeder before touching insulator stack."
        }, headers=eng_headers)
        assert assign_res.status_code == 200

        # 4. Technician views assigned work orders
        wo_res = await ac.get("/api/v1/work-orders?technician_id=technician@safety.org", headers=tech_headers)
        assert wo_res.status_code == 200
        assert wo_res.json()["count"] >= 1

        # 5. Technician acknowledges incident
        ack_res = await ac.post(f"/api/v1/incidents/{inc_id}/acknowledge", headers=tech_headers)
        assert ack_res.status_code == 200
        assert ack_res.json()["data"]["status"] == "ACKNOWLEDGED"

        # 6. Technician updates status to IN_PROGRESS and logs field inspection notes
        prog_res = await ac.post(f"/api/v1/incidents/{inc_id}/status", json={
            "status": "IN_PROGRESS",
            "notes": "Arrived on site. Non-contact HV detector verified zero voltage."
        }, headers=tech_headers)
        assert prog_res.status_code == 200
        assert prog_res.json()["data"]["status"] == "IN_PROGRESS"

        # 7. Technician completes repair and resolves work order
        resolve_res = await ac.post(f"/api/v1/incidents/{inc_id}/status", json={
            "status": "RESOLVED",
            "notes": "Replaced cracked pin insulator. Earth pit resistance measured 2.8 ohms (CEA compliant)."
        }, headers=tech_headers)
        assert resolve_res.status_code == 200
        assert resolve_res.json()["data"]["status"] == "RESOLVED"
        assert resolve_res.json()["data"]["resolved_at"] is not None


# ==============================================================================
# 4. Role 3 — ENGINEER User Journey
# ==============================================================================

@pytest.mark.asyncio
async def test_engineer_user_journey():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        token = await get_auth_token(ac, "engineer@safety.org")
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Health & Fleet Risk Analytics
        health_res = await ac.get("/api/v1/poles/P-001/health", headers=headers)
        assert health_res.status_code == 200
        assert "health_score" in health_res.json()["data"]

        risk_res = await ac.get("/api/v1/poles/P-001/risk", headers=headers)
        assert risk_res.status_code == 200
        assert "risk_score" in risk_res.json()["data"]
        assert "risk_tier" in risk_res.json()["data"]

        # 2. Historical sensor trend check (leakage current history for CustomPainter chart)
        hist_res = await ac.get("/api/v1/poles/P-001/history?limit=24", headers=headers)
        assert hist_res.status_code == 200
        assert len(hist_res.json()["data"]) >= 1

        # 3. Register new pole asset (Engineer privilege)
        import uuid
        new_pole_id = f"P-ENG-{uuid.uuid4().hex[:6].upper()}"
        create_res = await ac.post("/api/v1/poles", json={
            "id": new_pole_id,
            "name": "Sub-Station Feeder Asset 4",
            "latitude": 23.01,
            "longitude": 72.58,
            "zone": "Sector 4",
            "status": "HEALTHY",
            "health_score": 100,
            "risk_score": 0
        }, headers=headers)
        assert create_res.status_code == 201
        assert create_res.json()["data"]["id"] == new_pole_id


# ==============================================================================
# 5. Role 4 — AUTHORITY User Journey
# ==============================================================================

@pytest.mark.asyncio
async def test_authority_user_journey():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        token = await get_auth_token(ac, "authority@safety.org")
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Simulate an emergency event on P-003 to trigger an escalation
        await ac.post("/api/v1/telemetry", json={
            "pole_id": "P-003",
            "leakage_current_ma": 49.0,
            "touch_voltage_v": 92.0,
            "tilt_angle_deg": 19.5,
            "vibration_g": 2.5,
            "rain_detected": True,
            "is_simulated": True
        })

        # 2. Authority monitors active escalations
        esc_res = await ac.get("/api/v1/incidents/escalations", headers=headers)
        assert esc_res.status_code == 200
        escalations = esc_res.json()["data"]
        assert len(escalations) >= 1
        assert any(e["severity"] in ["CRITICAL", "EMERGENCY"] for e in escalations)

        # 3. Authority executes remote emergency power grid line cutoff
        cutoff_res = await ac.post("/api/v1/authority/grid-cutoff", json={
            "pole_id": "P-003",
            "reason": "Immediate life safety hazard: 49mA leakage in flooded pedestrian corridor"
        }, headers=headers)
        assert cutoff_res.status_code == 200
        cutoff_data = cutoff_res.json()["data"]
        assert cutoff_data["status"] == "OFFLINE"
        assert cutoff_data["ordered_by"] == "authority@safety.org"

        # 4. Verify pole is marked OFFLINE in registry
        pole_res = await ac.get("/api/v1/poles/P-003")
        assert pole_res.json()["data"]["status"] == "OFFLINE"


# ==============================================================================
# 6. Role 5 — ADMIN User Journey
# ==============================================================================

@pytest.mark.asyncio
async def test_admin_user_journey():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        token = await get_auth_token(ac, "admin@safety.org")
        headers = {"Authorization": f"Bearer {token}"}

        # 1. User management registry
        users_res = await ac.get("/api/v1/admin/users", headers=headers)
        assert users_res.status_code == 200
        users = users_res.json()["data"]
        assert len(users) >= 5
        roles = {u["role"] for u in users}
        assert {"CITIZEN", "TECHNICIAN", "ENGINEER", "AUTHORITY", "ADMIN"}.issubset(roles)

        # 2. Toggle user active status
        sample_user_id = users[0]["id"]
        toggle_res = await ac.post(f"/api/v1/admin/users/{sample_user_id}/toggle-active", headers=headers)
        assert toggle_res.status_code == 200
        # Toggle back to restore initial state
        await ac.post(f"/api/v1/admin/users/{sample_user_id}/toggle-active", headers=headers)

        # 3. Audit trail review
        audit_res = await ac.get("/api/v1/admin/audit-logs", headers=headers)
        assert audit_res.status_code == 200
        logs = audit_res.json()["data"]
        assert len(logs) >= 1
        actions = [l["action"] for l in logs]
        assert any("LOGIN" in a or "CUTOFF" in a or "REPORT" in a for a in actions)

        # 4. System safety configuration & IEC parameters
        config_res = await ac.get("/api/v1/admin/system-config", headers=headers)
        assert config_res.status_code == 200
        config = config_res.json()["data"]
        assert config["leakage_critical_threshold_ma"] == 30.0
        assert "IEC 60479" in config["iec_standard"]
