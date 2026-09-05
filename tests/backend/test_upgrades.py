import io
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
async def test_health_check():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/health")
        assert res.status_code == 200
        assert res.json()["status"] == "online"


@pytest.mark.asyncio
async def test_nearby_poles():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/api/v1/poles/nearby?latitude=18.5204&longitude=73.8567&radius_km=10.0")
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert data["count"] > 0
        assert data["data"][0]["distance_meters"] >= 0.0
        assert "address" in data["data"][0]


@pytest.mark.asyncio
async def test_photo_upload():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        dummy_img = io.BytesIO(b"\xff\xd8\xff\xe0\x00\x10JFIF" + b"\x00" * 100)
        res = await ac.post("/api/v1/uploads/image", files={"file": ("pole_photo.jpg", dummy_img, "image/jpeg")})
        assert res.status_code == 201
        assert res.json()["success"] is True
        assert "/uploads/" in res.json()["image_url"]


@pytest.mark.asyncio
async def test_hazard_report_lifecycle():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Create Report
        report_payload = {
            "latitude": 18.5204,
            "longitude": 73.8567,
            "pole_id": "P-001",
            "hazard_type": "Electrical leakage suspicion",
            "description": "Sparking and leakage near junction during drizzle",
            "image_url": "/uploads/sample_hazard.jpg",
            "reporter_name": "Test Citizen"
        }
        res = await ac.post("/api/v1/hazard-reports", json=report_payload)
        assert res.status_code == 201
        rep_id = res.json()["report_id"]
        assert res.json()["status"] == "REPORTED"

        # 2. Status Update
        res = await ac.patch(f"/api/v1/hazard-reports/{rep_id}/status", json={"status": "UNDER_REVIEW", "notes": "Operator verified"})
        assert res.status_code == 200
        assert res.json()["new_status"] == "UNDER_REVIEW"


@pytest.mark.asyncio
async def test_auth_staff_protection():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Attempt staff account without code
        res = await ac.post("/api/v1/auth/register", json={
            "email": "bad_admin_test@safety.org",
            "password": "password123",
            "full_name": "Hacker",
            "role": "ADMIN"
        })
        assert res.status_code == 403

        # Authorized staff registration
        import uuid
        unique_email = f"good_admin_{uuid.uuid4().hex[:6]}@safety.org"
        res = await ac.post("/api/v1/auth/register", json={
            "email": unique_email,
            "password": "password123",
            "full_name": "Authorized Admin",
            "role": "ADMIN",
            "staff_auth_code": "POLEGUARD-SECURE-2026"
        })
        assert res.status_code == 201


@pytest.mark.asyncio
async def test_forgot_and_reset_password():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.post("/api/v1/auth/forgot-password", json={"email": "citizen@safety.org"})
        assert res.status_code == 200
        token = res.json()["reset_token"]

        res = await ac.post("/api/v1/auth/reset-password", json={
            "email": "citizen@safety.org",
            "token": token,
            "new_password": "newpassword123"
        })
        assert res.status_code == 200

        # Reset back to standard password123 for other tests
        res2 = await ac.post("/api/v1/auth/forgot-password", json={"email": "citizen@safety.org"})
        token2 = res2.json()["reset_token"]
        await ac.post("/api/v1/auth/reset-password", json={
            "email": "citizen@safety.org",
            "token": token2,
            "new_password": "password123"
        })
