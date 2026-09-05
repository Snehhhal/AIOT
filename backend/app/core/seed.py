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

        # 2. Seed Poles (P-001 through P-004) with real location details
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
                    address="MG Road, Near Central Library, Junction 4",
                    area="Pune Cantonment",
                    zone="Sector 4",
                    pole_type="DISTRIBUTION",
                    status="CRITICAL",
                    health_score=42,
                    risk_score=88,
                    installation_date=datetime(2021, 5, 12, tzinfo=timezone.utc),
                    last_inspection_date=datetime.now(timezone.utc) - timedelta(days=5),
                    last_heartbeat=datetime.now(timezone.utc),
                ),
                Pole(
                    id="P-002",
                    serial_number="PL-2024-002",
                    name="FC Road - Near Metro Station",
                    latitude=18.5280,
                    longitude=73.8420,
                    address="Fergusson College Road, Opp Metro Gate 2",
                    area="Shivajinagar",
                    zone="Sector 1",
                    pole_type="DISTRIBUTION",
                    status="WARNING",
                    health_score=68,
                    risk_score=45,
                    installation_date=datetime(2022, 8, 19, tzinfo=timezone.utc),
                    last_inspection_date=datetime.now(timezone.utc) - timedelta(days=12),
                    last_heartbeat=datetime.now(timezone.utc),
                ),
                Pole(
                    id="P-003",
                    serial_number="PL-2024-003",
                    name="Station Road - East Zone",
                    latitude=18.5312,
                    longitude=73.8745,
                    address="Pune Station Road, Near Platform 1 Feeder",
                    area="Railway Circle",
                    zone="Sector 2",
                    pole_type="FEEDER",
                    status="HEALTHY",
                    health_score=94,
                    risk_score=8,
                    installation_date=datetime(2023, 2, 10, tzinfo=timezone.utc),
                    last_inspection_date=datetime.now(timezone.utc) - timedelta(days=2),
                    last_heartbeat=datetime.now(timezone.utc),
                ),
                Pole(
                    id="P-004",
                    serial_number="PL-2024-004",
                    name="Kothrud Market Center",
                    latitude=18.5074,
                    longitude=73.8077,
                    address="Paud Road, Near Shivaji Statue Center",
                    area="Kothrud",
                    zone="Sector 3",
                    pole_type="DISTRIBUTION",
                    status="HEALTHY",
                    health_score=96,
                    risk_score=5,
                    installation_date=datetime(2023, 11, 24, tzinfo=timezone.utc),
                    last_inspection_date=datetime.now(timezone.utc) - timedelta(days=1),
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

        # 4. Seed Initial Citizen Hazard Reports if empty
        existing_reports = await db.execute(select(HazardReport))
        if not existing_reports.scalars().first():
            print("[*] Seeding sample citizen hazard reports...")
            now = datetime.now(timezone.utc)
            sample_reports = [
                HazardReport(
                    id="REP-000101",
                    reporter_id="USR-CIT-01",
                    reporter_name="Rahul Sharma",
                    reporter_phone="+91-9876543210",
                    pole_id="P-001",
                    latitude=18.5206,
                    longitude=73.8569,
                    address="MG Road, Corner opposite State Bank",
                    hazard_type="Electrical leakage suspicion",
                    description="Tingling sensation felt when touching metal bus stop railing adjacent to Pole P-001 during light rain.",
                    image_url=None,
                    status="UNDER_REVIEW",
                    created_at=now - timedelta(hours=3),
                    updated_at=now - timedelta(hours=2),
                ),
                HazardReport(
                    id="REP-000102",
                    reporter_id="USR-CIT-01",
                    reporter_name="Pooja Deshmukh",
                    reporter_phone="+91-9822011223",
                    pole_id="P-002",
                    latitude=18.5283,
                    longitude=73.8423,
                    address="FC Road near Cafe GoodLuck",
                    hazard_type="Sparking",
                    description="Occasional bright sparks visible at top cross-arm insulator bracket.",
                    image_url=None,
                    status="ASSIGNED",
                    assigned_technician_id="USR-TECH-14",
                    inspection_notes="Assigned to Lineman Kailas Jadhav for priority morning inspection.",
                    created_at=now - timedelta(hours=6),
                    updated_at=now - timedelta(hours=1),
                )
            ]
            db.add_all(sample_reports)
            await db.commit()
            print(f"[+] Successfully seeded sample citizen hazard reports.")
