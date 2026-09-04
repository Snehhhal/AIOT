import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.main import app
from backend.app.core.seed import seed_initial_data


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    """Ensure schema tables and seed data exist before running tests."""
    await seed_initial_data()


@pytest.mark.asyncio
async def test_list_poles():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/api/v1/poles")
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert data["count"] >= 4
        pole_ids = [p["id"] for p in data["data"]]
        assert "P-001" in pole_ids
        assert "P-002" in pole_ids


@pytest.mark.asyncio
async def test_get_single_pole():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/api/v1/poles/P-001")
        assert res.status_code == 200
        data = res.json()
        assert data["data"]["id"] == "P-001"
        assert "connectivity" in data["data"]


@pytest.mark.asyncio
async def test_ingest_telemetry_and_verify_persistence():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Ingest reading with dangerous leakage in rain
        payload = {
            "pole_id": "P-001",
            "leakage_current_ma": 42.5,
            "touch_voltage_v": 68.0,
            "tilt_angle_deg": 1.5,
            "vibration_g": 0.05,
            "temperature_c": 28.0,
            "humidity_pct": 95.0,
            "rain_detected": True,
            "is_simulated": True
        }
        ingest_res = await ac.post("/api/v1/telemetry", json=payload)
        assert ingest_res.status_code == 201
        res_data = ingest_res.json()["data"]
        assert res_data["risk_level"] == "CRITICAL"
        assert res_data["alert_triggered"] is True

        # Verify latest reading endpoint returns the persisted values
        reading_res = await ac.get("/api/v1/poles/P-001/readings")
        assert reading_res.status_code == 200
        r_data = reading_res.json()["data"]
        assert r_data["leakage_current"] == 42.5
        assert r_data["rain"] is True

        # Verify pole status updated to CRITICAL
        pole_res = await ac.get("/api/v1/poles/P-001")
        assert pole_res.json()["data"]["status"] == "CRITICAL"


@pytest.mark.asyncio
async def test_get_pole_history():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/api/v1/poles/P-001/history")
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert isinstance(data["data"], list)


@pytest.mark.asyncio
async def test_get_pole_health_and_risk():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        health_res = await ac.get("/api/v1/poles/P-001/health")
        assert health_res.status_code == 200
        assert "health_score" in health_res.json()["data"]
        assert "maintenance_priority" in health_res.json()["data"]

        risk_res = await ac.get("/api/v1/poles/P-001/risk")
        assert risk_res.status_code == 200
        assert "risk_score" in risk_res.json()["data"]
        assert "risk_tier" in risk_res.json()["data"]


@pytest.mark.asyncio
async def test_admin_create_pole():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Login as Admin
        login_res = await ac.post(
            "/api/v1/auth/login",
            json={"email": "admin@safety.org", "password": "password123"}
        )
        token = login_res.json()["access_token"]

        # 2. Register P-005
        pole_payload = {
            "id": "P-005",
            "name": "University Circle - West Gate",
            "latitude": 18.5300,
            "longitude": 73.8300,
            "zone": "Sector 5",
            "status": "HEALTHY",
            "health_score": 98,
            "risk_score": 2,
            "is_active": True
        }
        create_res = await ac.post(
            "/api/v1/poles",
            json=pole_payload,
            headers={"Authorization": f"Bearer {token}"}
        )
        assert create_res.status_code == 201
        assert create_res.json()["data"]["id"] == "P-005"
