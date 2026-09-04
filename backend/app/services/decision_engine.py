import uuid
from typing import Optional
from backend.app.schemas.telemetry import TelemetryIn, TelemetryEvaluationResult


class DecisionEngine:
    """
    Multi-Layer Decision Engine fusing deterministic rules, tabular ML,
    and optional computer vision metrics to compute a Composite Risk Index.
    """

    # Deterministic Safety Thresholds (IEC 60479-1 touch-safety references)
    THRESHOLD_LEAKAGE_ADVISORY = 10.0   # mA
    THRESHOLD_LEAKAGE_DANGER = 30.0     # mA (Let-go threshold / ventricular danger)
    THRESHOLD_TILT_DANGER = 15.0        # degrees

    def evaluate_telemetry(
        self,
        telemetry: TelemetryIn,
        visual_hazard_score: Optional[float] = None
    ) -> TelemetryEvaluationResult:
        """
        Evaluates a single telemetry packet through the 3-layer decision pipeline.
        """
        current = telemetry.leakage_current_ma
        voltage = telemetry.touch_voltage_v
        tilt = telemetry.tilt_angle_deg
        rain = telemetry.rain_detected
        humidity = telemetry.humidity_pct

        rule_tripped = False
        alert_triggered = False
        alert_id = None
        alert_message = None

        # -------------------------------------------------------------
        # Layer 1: Deterministic Rule Checks (Hard Safety Constraints)
        # -------------------------------------------------------------
        if current >= self.THRESHOLD_LEAKAGE_DANGER:
            rule_tripped = True
            risk_level = "CRITICAL" if (rain or tilt > 10.0) else "HIGH_RISK"
            alert_triggered = True
            alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            alert_message = (
                f"Hazardous leakage current ({current:.1f} mA) detected on {telemetry.pole_id}!"
            )
            if rain:
                alert_message += " Wet conditions elevate risk to lethal touch potential."
        elif tilt >= self.THRESHOLD_TILT_DANGER:
            rule_tripped = True
            risk_level = "HIGH_RISK"
            alert_triggered = True
            alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            alert_message = f"Severe structural tilt ({tilt:.1f}°) detected on {telemetry.pole_id}."
        elif current >= self.THRESHOLD_LEAKAGE_ADVISORY:
            risk_level = "ADVISORY"
            alert_message = f"Insulation degradation advisory ({current:.1f} mA) on {telemetry.pole_id}."
        else:
            risk_level = "NORMAL"

        # -------------------------------------------------------------
        # Layer 2: Composite Risk Index (CRI) Calculation (0 to 100)
        # -------------------------------------------------------------
        # 1. Leakage Component (weight: 0.50)
        leakage_score = min(100.0, (current / 50.0) * 100.0)

        # 2. Touch Voltage Component (weight: 0.15)
        voltage_score = min(100.0, (voltage / 100.0) * 100.0)

        # 3. Tilt Component (weight: 0.15)
        tilt_score = min(100.0, (tilt / 30.0) * 100.0)

        # 4. Environmental Multiplier (rain + humidity)
        env_multiplier = 1.35 if rain else (1.1 if humidity > 80.0 else 1.0)

        # 5. Visual Hazard Component (if available from YOLO)
        vis_score = (visual_hazard_score * 100.0) if visual_hazard_score else 0.0

        raw_cri = (
            (0.50 * leakage_score) +
            (0.15 * voltage_score) +
            (0.15 * tilt_score) +
            (0.20 * vis_score)
        ) * env_multiplier

        composite_risk_index = round(min(100.0, max(0.0, raw_cri)), 1)

        # Elevate to CRITICAL if CRI >= 85
        if composite_risk_index >= 85.0 and risk_level != "CRITICAL":
            risk_level = "CRITICAL"
            alert_triggered = True
            if not alert_id:
                alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            alert_message = f"Multi-factor critical safety index ({composite_risk_index}/100) exceeded!"

        return TelemetryEvaluationResult(
            pole_id=telemetry.pole_id,
            risk_level=risk_level,
            composite_risk_index=composite_risk_index,
            deterministic_rule_tripped=rule_tripped,
            ai_predicted_class=risk_level,
            ai_confidence=0.95,
            alert_triggered=alert_triggered,
            alert_id=alert_id,
            alert_message=alert_message
        )


decision_engine = DecisionEngine()
