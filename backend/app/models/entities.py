from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Text, ForeignKey
from backend.app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, index=True)
    email = Column(String(128), unique=True, index=True, nullable=False)
    hashed_password = Column(String(256), nullable=False)
    full_name = Column(String(128), nullable=False)
    role = Column(String(32), nullable=False, default="CITIZEN") # CITIZEN, TECHNICIAN, ENGINEER, AUTHORITY, ADMIN
    zone = Column(String(64), default="Sector 1")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Pole(Base):
    __tablename__ = "poles"

    id = Column(String(32), primary_key=True, index=True) # e.g. "P-001"
    serial_number = Column(String(64), unique=True, nullable=True)
    name = Column(String(128), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    zone = Column(String(64), nullable=False, default="Sector 1")
    status = Column(String(32), default="HEALTHY") # HEALTHY, WARNING, CRITICAL, OFFLINE
    health_score = Column(Integer, default=95)     # 0 - 100
    risk_score = Column(Integer, default=5)         # 0 - 100
    is_active = Column(Boolean, default=True)
    last_heartbeat = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id = Column(Integer, primary_key=True, autoincrement=True)
    pole_id = Column(String(32), ForeignKey("poles.id"), index=True, nullable=False)
    leakage_current = Column(Float, nullable=False) # mA
    voltage = Column(Float, nullable=False)         # V
    temperature = Column(Float, nullable=False)     # °C
    humidity = Column(Float, nullable=False)        # %
    rain = Column(Boolean, default=False)
    is_simulated = Column(Boolean, default=False)
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)


class Incident(Base):
    __tablename__ = "incidents"

    id = Column(String(36), primary_key=True, index=True)
    pole_id = Column(String(32), ForeignKey("poles.id"), nullable=False)
    severity = Column(String(32), nullable=False) # INFO, WARNING, CRITICAL, EMERGENCY
    status = Column(String(32), default="DETECTED") # DETECTED, ASSIGNED, ACKNOWLEDGED, UNDER_INSPECTION, REPAIR_IN_PROGRESS, RESOLVED, CLOSED
    description = Column(Text, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    acknowledged_at = Column(DateTime, nullable=True)
    resolved_at = Column(DateTime, nullable=True)
    resolved_by = Column(String(36), nullable=True)


class WorkOrder(Base):
    __tablename__ = "work_orders"

    id = Column(String(36), primary_key=True, index=True)
    incident_id = Column(String(36), ForeignKey("incidents.id"), nullable=False)
    technician_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    status = Column(String(32), default="PENDING")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String(36), primary_key=True, index=True)
    pole_id = Column(String(32), ForeignKey("poles.id"), nullable=False)
    severity = Column(String(32), nullable=False) # LOW, MEDIUM, HIGH, CRITICAL
    alert_type = Column(String(64), nullable=False)
    message = Column(Text, nullable=False)
    status = Column(String(32), default="NEW")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(36), nullable=True)
    action = Column(String(64), nullable=False) # e.g. LOGIN, ACKNOWLEDGE, ESCALATE, RESOLVE
    target_entity = Column(String(64), nullable=True) # e.g. Pole P-001, Incident INC-101
    details = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))
