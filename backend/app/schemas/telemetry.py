from datetime import datetime, timezone
from typing import List, Optional
from pydantic import BaseModel, Field


class TelemetryIn(BaseModel):
    """
    Standardized telemetry schema shared by both physical ESP32 edge devices
    and software simulation scripts.
    """
    pole_id: str = Field(..., description="Unique identifier of the pole (e.g. POLE-101)")
    leakage_current_ma: float = Field(..., ge=0.0, le=2000.0, description="Measured leakage current in mA")
    touch_voltage_v: float = Field(default=0.0, ge=0.0, le=500.0, description="Estimated touch voltage in Volts")
    tilt_angle_deg: float = Field(default=0.0, ge=0.0, le=90.0, description="Tilt deviation in degrees")
    vibration_g: float = Field(default=0.0, ge=0.0, le=20.0, description="Vibration amplitude in g")
    temperature_c: float = Field(default=25.0, ge=-40.0, le=85.0, description="Enclosure temperature in Celsius")
    humidity_pct: float = Field(default=50.0, ge=0.0, le=100.0, description="Relative humidity %")
    rain_detected: bool = Field(default=false, description="Rain / moisture sensor flag")
    is_simulated: bool = Field(default=false, description="Flag indicating if reading originates from simulation")
    recorded_at: Optional[datetime] = Field(default_factory=lambda: datetime.now(timezone.utc))


class TelemetryBatchIn(BaseModel):
    """Batch payload for offline edge sync when re-establishing connectivity."""
    pole_id: str
    readings: List[TelemetryIn]


class TelemetryEvaluationResult(BaseModel):
    """Output returned by the Multi-Layer Decision Engine after evaluating a reading."""
    pole_id: str
    risk_level: str = Field(..., description="NORMAL, ADVISORY, HIGH_RISK, or CRITICAL")
    composite_risk_index: float = Field(..., ge=0.0, le=100.0, description="Score between 0 and 100")
    deterministic_rule_tripped: bool = False
    ai_predicted_class: Optional[str] = None
    ai_confidence: Optional[float] = None
    alert_triggered: bool = False
    alert_id: Optional[str] = None
    alert_message: Optional[str] = None
    evaluated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class TelemetryOut(TelemetryIn):
    id: Optional[int] = None
    created_at: Optional[datetime] = None
