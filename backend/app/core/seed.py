from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.core.database import engine, Base, AsyncSessionLocal
from backend.app.core.security import hash_password
from backend.app.models.entities import User, Pole, SensorReading, Incident, Alert, HazardReport, PasswordReset, WorkOrder, AuditLog


async def seed_initial_data():
    """Initializes schema tables and seeds default demo accounts, poles & hazard reports."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # 1. Seed Users (5 Roles)
        existing_users = await db.execute(select(User))
        if not existing_users.scalars().first():
            print("[*] Seeding default demo accounts for all 5 roles...")
            default_pwd = hash_password("password123")
            users = [
                User(
                    id="USR-CIT-01",
                    email="citizen@safety.org",
                    hashed_password=default_pwd,
                    full_name="Rahul Sharma",
                    role="CITIZEN",
                    zone="Sector 4",
                ),
                User(
                    id="USR-TECH-14",
                    email="technician@safety.org",
                    hashed_password=default_pwd,
                    full_name="Kailas Jadhav (Lineman #14)",
                    role="TECHNICIAN",
                    zone="Zone 1 & 2",
                ),
                User(
                    id="USR-ENG-02",
                    email="engineer@safety.org",
                    hashed_password=default_pwd,
                    full_name="Er. Snehal Chavan",
                    role="ENGINEER",
                    zone="Sub-Div Central",
                ),
                User(
                    id="USR-AUTH-01",
                    email="authority@safety.org",
                    hashed_password=default_pwd,
                    full_name="Disaster Management Office",
                    role="AUTHORITY",
                    zone="Metropolitan Circle",
                ),
                User(
                    id="USR-ADM-00",
                    email="admin@safety.org",
                    hashed_password=default_pwd,
                    full_name="Platform Root Administrator",
                    role="ADMIN",
                    zone="All Zones",
                ),
            ]
            db.add_all(users)
            await db.commit()

        # Authorized users for the 5 roles seeded for database-backed authentication.
        # No fake poles, locations, or reports are seeded. Every pole and report
        # must come from authorized database entries or live user submissions.
        print("[+] Database schema verified and authorized accounts initialized.")
