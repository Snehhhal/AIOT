import uuid
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from backend.main import app
from backend.app.core.database import AsyncSessionLocal
from backend.app.models.entities import User


@pytest.mark.asyncio
async def test_citizen_signup_and_db_persistence():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email = f"test.citizen.{uuid.uuid4().hex[:8]}@poleguard.test"
        payload = {
            "email": email,
            "password": "SecurePassword123!",
            "full_name": "Aarav Patel",
            "role": "CITIZEN",
            "zone": "Sector 4"
        }
        resp = await ac.post("/api/v1/auth/register", json=payload)
        assert resp.status_code == 201, resp.text
        data = resp.json()
        assert "access_token" in data
        assert data["user"]["email"] == email
        assert data["user"]["full_name"] == "Aarav Patel"
        assert data["user"]["role"] == "CITIZEN"

        # Verify in database directly
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(User).where(User.email == email))
            db_user = result.scalar_one_or_none()
            assert db_user is not None
            assert db_user.full_name == "Aarav Patel"
            assert db_user.role == "CITIZEN"
            assert db_user.hashed_password != "SecurePassword123!"
            assert len(db_user.hashed_password) > 30


@pytest.mark.asyncio
async def test_signup_duplicate_email_rejected():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email = f"test.duplicate.{uuid.uuid4().hex[:8]}@poleguard.test"
        payload = {
            "email": email,
            "password": "Password123!",
            "full_name": "First User",
            "role": "CITIZEN",
        }
        r1 = await ac.post("/api/v1/auth/register", json=payload)
        assert r1.status_code == 201

        payload["full_name"] = "Second User"
        r2 = await ac.post("/api/v1/auth/register", json=payload)
        assert r2.status_code == 400
        assert "already exists" in r2.json()["detail"].lower()


@pytest.mark.asyncio
async def test_login_wrong_password_rejected():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email = f"test.wrongpass.{uuid.uuid4().hex[:8]}@poleguard.test"
        reg_payload = {
            "email": email,
            "password": "CorrectPassword123",
            "full_name": "Test User",
            "role": "CITIZEN",
        }
        await ac.post("/api/v1/auth/register", json=reg_payload)

        login_payload = {
            "email": email,
            "password": "WrongPassword999"
        }
        resp = await ac.post("/api/v1/auth/login", json=login_payload)
        assert resp.status_code == 401
        assert resp.json()["detail"] == "Incorrect email or password."


@pytest.mark.asyncio
async def test_login_nonexistent_email_rejected():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        login_payload = {
            "email": f"nonexistent.{uuid.uuid4().hex[:8]}@poleguard.test",
            "password": "Password123!"
        }
        resp = await ac.post("/api/v1/auth/login", json=login_payload)
        assert resp.status_code == 401
        assert resp.json()["detail"] == "Incorrect email or password."


@pytest.mark.asyncio
async def test_login_correct_credentials_returns_jwt_and_db_role():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email = f"test.login.success.{uuid.uuid4().hex[:8]}@poleguard.test"
        await ac.post("/api/v1/auth/register", json={
            "email": email,
            "password": "ValidPassword123!",
            "full_name": "Snehal Chavan",
            "role": "CITIZEN"
        })

        resp = await ac.post("/api/v1/auth/login", json={
            "email": email,
            "password": "ValidPassword123!"
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert data["user"]["full_name"] == "Snehal Chavan"
        assert data["user"]["role"] == "CITIZEN"
        assert data["user"]["email"] == email


@pytest.mark.asyncio
async def test_staff_signup_requires_valid_key():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email_staff = f"test.engineer.{uuid.uuid4().hex[:8]}@poleguard.test"
        
        # Staff role without key -> Rejected with 403
        r_fail1 = await ac.post("/api/v1/auth/register", json={
            "email": email_staff,
            "password": "Password123!",
            "full_name": "Er. Priya",
            "role": "ENGINEER"
        })
        assert r_fail1.status_code == 403
        assert "authorization key" in r_fail1.json()["detail"].lower()

        # Staff role with WRONG key -> Rejected with 403
        r_fail2 = await ac.post("/api/v1/auth/register", json={
            "email": email_staff,
            "password": "Password123!",
            "full_name": "Er. Priya",
            "role": "ENGINEER",
            "staff_auth_code": "WRONG-KEY"
        })
        assert r_fail2.status_code == 403

        # Staff role with VALID key -> Accepted with 201
        r_ok = await ac.post("/api/v1/auth/register", json={
            "email": email_staff,
            "password": "Password123!",
            "full_name": "Er. Priya",
            "role": "ENGINEER",
            "staff_auth_code": "POLEGUARD-SECURE-2026"
        })
        assert r_ok.status_code == 201
        assert r_ok.json()["user"]["role"] == "ENGINEER"


@pytest.mark.asyncio
async def test_rbac_citizen_forbidden_admin_users_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        citizen_email = f"citizen.rbac.{uuid.uuid4().hex[:8]}@poleguard.test"
        reg_c = await ac.post("/api/v1/auth/register", json={
            "email": citizen_email,
            "password": "Password123!",
            "full_name": "Citizen User",
            "role": "CITIZEN"
        })
        c_token = reg_c.json()["access_token"]

        admin_res = await ac.get(
            "/api/v1/admin/users",
            headers={"Authorization": f"Bearer {c_token}"}
        )
        assert admin_res.status_code == 403

        admin_login = await ac.post("/api/v1/auth/login", json={
            "email": "admin@safety.org",
            "password": "password123"
        })
        assert admin_login.status_code == 200, admin_login.text
        a_token = admin_login.json()["access_token"]
        admin_res_ok = await ac.get(
            "/api/v1/admin/users",
            headers={"Authorization": f"Bearer {a_token}"}
        )
        assert admin_res_ok.status_code == 200


@pytest.mark.asyncio
async def test_forgot_password_and_reset_flow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email = f"test.resetpass.{uuid.uuid4().hex[:8]}@poleguard.test"
        await ac.post("/api/v1/auth/register", json={
            "email": email,
            "password": "OriginalPassword123",
            "full_name": "Reset Tester",
            "role": "CITIZEN"
        })

        r_forgot = await ac.post("/api/v1/auth/forgot-password", json={"email": email})
        assert r_forgot.status_code == 200
        token = r_forgot.json()["reset_token"]

        r_reset = await ac.post("/api/v1/auth/reset-password", json={
            "email": email,
            "token": token,
            "new_password": "NewSecretPassword456!"
        })
        assert r_reset.status_code == 200

        r_old = await ac.post("/api/v1/auth/login", json={
            "email": email,
            "password": "OriginalPassword123"
        })
        assert r_old.status_code == 401

        r_new = await ac.post("/api/v1/auth/login", json={
            "email": email,
            "password": "NewSecretPassword456!"
        })
        assert r_new.status_code == 200
