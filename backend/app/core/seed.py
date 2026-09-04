from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.core.database import engine, Base, AsyncSessionLocal
from backend.app.core.security import hash_password
from backend.app.models.entities import User, Pole, SensorReading, Incident, Alert


async def seed_initial_data():
    """Initializes schema tables and seeds default demo accounts & poles."""
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

        # 2. Seed Poles (P-001 through P-004)
        existing_poles = await db.execute(select(Pole))
        if not existing_poles.scalars().first():
            print("[*] Seeding infrastructure utility poles P-001 to P-004...")
            poles = [
                Pole(
                    id="P-001",
                    serial_number="PL-2024-001",
                    name="MG Road - Junction 4",
                    latitude=18.5204,
                    longitude=73.8567,
                    zone="Sector 4",
                    status="CRITICAL",
                    last_heartbeat=datetime.now(timezone.utc),
                ),
                Pole(
                    id="P-002",
                    serial_number="PL-2024-002",
                    name="FC Road - Near Metro Station",
                    latitude=18.5280,
                    longitude=73.8420,
                    zone="Sector 1",
                    status="WARNING",
                    last_heartbeat=datetime.now(timezone.utc),
                ),
                Pole(
                    id="P-003",
                    serial_number="PL-2024-003",
                    name="Station Road - East Zone",
                    latitude=18.5312,
                    longitude=73.8745,
                    zone="Sector 2",
                    status="HEALTHY",
                    last_heartbeat=datetime.now(timezone.utc),
                ),
                Pole(
                    id="P-004",
                    serial_number="PL-2024-004",
                    name="Kothrud Market Center",
                    latitude=18.5074,
                    longitude=73.8077,
                    zone="Sector 3",
                    status="HEALTHY",
                    last_heartbeat=datetime.now(timezone.utc),
                ),
            ]
            db.add_all(poles)
            await db.commit()
            print("[+] Seed data populated successfully.")
