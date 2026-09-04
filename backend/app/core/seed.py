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
            print("[+] Poles populated successfully.")

        # 3. Seed 24-Hour Historical Sensor Readings for Trend Charts
        existing_readings = await db.execute(select(SensorReading))
        if not existing_readings.scalars().first():
            print("[*] Seeding 24-hour time-series sensor telemetry for P-001 through P-004...")
            from datetime import timedelta
            now = datetime.now(timezone.utc)
            readings = []

            for i in range(24):
                ts = now - timedelta(hours=(23 - i))
                
                # P-001: Escalates from safe (2mA) -> advisory (15mA) -> critical leakage in rain (48.5mA)
                if i < 15:
                    p1_leak = 2.0 + (i * 0.2)
                    p1_volt = 230.0 - (i * 0.1)
                    p1_rain = False
                    p1_hum = 55.0
                elif i < 20:
                    p1_leak = 8.0 + ((i - 15) * 3.5)
                    p1_volt = 227.0 - ((i - 15) * 1.5)
                    p1_rain = False
                    p1_hum = 75.0
                else:
                    p1_leak = 34.0 + ((i - 20) * 3.6)
                    p1_volt = 55.0 + ((i - 20) * 4.8)
                    p1_rain = True
                    p1_hum = 95.0

                readings.append(SensorReading(
                    pole_id="P-001",
                    leakage_current=round(p1_leak, 2),
                    voltage=round(p1_volt, 1),
                    temperature=round(27.0 + (i % 5) * 0.6, 1),
                    humidity=p1_hum,
                    rain=p1_rain,
                    is_simulated=True,
                    recorded_at=ts,
                ))

                # P-002: Moderate insulation degradation (9 to 16 mA)
                p2_leak = 9.5 + ((i % 7) * 0.9)
                readings.append(SensorReading(
                    pole_id="P-002",
                    leakage_current=round(p2_leak, 2),
                    voltage=round(228.0 - (i % 3) * 0.5, 1),
                    temperature=round(28.0 + (i % 4) * 0.4, 1),
                    humidity=65.0,
                    rain=False,
                    is_simulated=True,
                    recorded_at=ts,
                ))

                # P-003: Optimal Healthy (1.2 to 2.4 mA)
                p3_leak = 1.2 + ((i % 5) * 0.2)
                readings.append(SensorReading(
                    pole_id="P-003",
                    leakage_current=round(p3_leak, 2),
                    voltage=round(230.0 + (i % 2) * 0.8, 1),
                    temperature=round(27.5 + (i % 6) * 0.3, 1),
                    humidity=50.0,
                    rain=False,
                    is_simulated=True,
                    recorded_at=ts,
                ))

                # P-004: Optimal Healthy (0.8 to 1.8 mA)
                p4_leak = 0.8 + ((i % 4) * 0.2)
                readings.append(SensorReading(
                    pole_id="P-004",
                    leakage_current=round(p4_leak, 2),
                    voltage=round(229.5 + (i % 3) * 0.5, 1),
                    temperature=round(26.8 + (i % 5) * 0.4, 1),
                    humidity=46.0,
                    rain=False,
                    is_simulated=True,
                    recorded_at=ts,
                ))

            db.add_all(readings)
            await db.commit()
            print(f"[+] Successfully seeded {len(readings)} historical sensor readings.")
