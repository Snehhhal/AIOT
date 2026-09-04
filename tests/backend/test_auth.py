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
        response = await ac.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "online"
        assert "CITIZEN" in data["supported_roles"]


@pytest.mark.asyncio
async def test_login_demo_technician():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/api/v1/auth/login",
            json={"email": "technician@safety.org", "password": "password123"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["user"]["role"] == "TECHNICIAN"


@pytest.mark.asyncio
async def test_get_me_with_jwt():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        login_res = await ac.post(
            "/api/v1/auth/login",
            json={"email": "admin@safety.org", "password": "password123"}
        )
        token = login_res.json()["access_token"]

        me_res = await ac.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert me_res.status_code == 200
        me_data = me_res.json()
        assert me_data["role"] == "ADMIN"
        assert me_data["email"] == "admin@safety.org"


@pytest.mark.asyncio
async def test_login_invalid_password():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/api/v1/auth/login",
            json={"email": "technician@safety.org", "password": "wrongpassword"}
        )
        assert response.status_code == 401
