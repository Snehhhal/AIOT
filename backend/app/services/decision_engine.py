import uuid
from typing import Any, Dict, Optional
from backend.app.schemas.telemetry import TelemetryIn, TelemetryEvaluationResult

try:
    from ai.src.inference import leakage_classifier
except Exception:
    leakage_classifier = None


class DecisionEngine:
    """
    Multi-Layer Decision Engine fusing deterministic rules, tabular ML,
    and computer vision spatial metrics to compute a Composite Risk Index (CRI).
    Architectural hierarchy: Hard Deterministic Safety Rules > Vision Fusion > Tabular AI.
    """

    # Deterministic Safety Thresholds (IEC 60479-1 touch-safety references)
    THRESHOLD_LEAKAGE_ADVISORY = 10.0   # mA
    THRESHOLD_LEAKAGE_DANGER = 30.0     # mA (Let-go threshold / ventricular danger)
    THRESHOLD_TILT_DANGER = 15.0        # degrees

    def evaluate_telemetry(
        self,
        telemetry: TelemetryIn,
        visual_hazard_score: Optional[float] = None,
        vision_details: Optional[Dict[str, Any]] = None
    ) -> TelemetryEvaluationResult:
        """
        Evaluates a single telemetry packet through the 3-layer decision pipeline.
        Fuses physical sensor telemetry with optional computer vision evidence.
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
        if (current >= self.THRESHOLD_LEAKAGE_DANGER and tilt >= self.THRESHOLD_TILT_DANGER) or \
           (current >= 40.0 and tilt >= 12.0 and telemetry.vibration_g >= 1.5):
            rule_tripped = True
            risk_level = "EMERGENCY"
            alert_triggered = True
            alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            alert_message = (
                f"EMERGENCY: Catastrophic dual failure on {telemetry.pole_id}! "
                f"Severe leakage ({current:.1f} mA) fused with structural compromise ({tilt:.1f}°, {telemetry.vibration_g:.1f}g)!"
            )
        elif current >= self.THRESHOLD_LEAKAGE_DANGER:
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
            risk_level = "WARNING"
            alert_triggered = True
            alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            alert_message = f"Insulation degradation warning ({current:.1f} mA) on {telemetry.pole_id}."
        else:
            risk_level = "NORMAL"

        # -------------------------------------------------------------
        # Cross-Modal Safety Fusion: Visual Hazard Escalation
        # -------------------------------------------------------------
        # If visual evidence confirms high hazard (water puddle + human <= 2.5m)
        # and current is moderate (>= 15.0 mA) or wet conditions exist,
        # escalate immediately to CRITICAL emergency!
        if visual_hazard_score and visual_hazard_score >= 0.80 and (current >= 15.0 or rain):
            rule_tripped = True
            risk_level = "CRITICAL"
            alert_triggered = True
            if not alert_id:
                alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            dist_str = f" at {vision_details.get('estimated_distance_meters')}m" if (vision_details and vision_details.get('estimated_distance_meters')) else ""
            alert_message = (
                f"CRITICAL MULTI-MODAL HAZARD on {telemetry.pole_id}: "
                f"Leakage current ({current:.1f} mA) fused with computer vision confirmation "
                f"of waterlogging puddle and pedestrian proximity{dist_str}!"
            )

        # -------------------------------------------------------------
        # Layer 2: Machine Learning Prediction (Tabular Random Forest)
        # -------------------------------------------------------------
        ai_predicted_class = risk_level
        ai_confidence = 0.95

        if leakage_classifier is not None:
            try:
                ai_res = leakage_classifier.predict(telemetry)
                ai_predicted_class = ai_res.get("predicted_class", risk_level)
                ai_confidence = float(ai_res.get("confidence", 0.95))
            except Exception:
                pass

        # If AI model flags high hazard but deterministic rules haven't tripped,
        # escalate to ADVISORY if currently NORMAL
        if not rule_tripped and ai_predicted_class in ["HIGH_RISK", "CRITICAL"] and ai_confidence >= 0.85:
            if risk_level == "NORMAL":
                risk_level = "ADVISORY"
                alert_message = f"AI predictive anomaly: compound multi-factor risk detected ({ai_predicted_class}, {ai_confidence:.0%} confidence)."

        # -------------------------------------------------------------
        # Layer 3: Composite Risk Index (CRI) Calculation (0 to 100)
        # -------------------------------------------------------------
        # 1. Leakage Component (weight: 0.35)
        leakage_score = min(100.0, (current / 50.0) * 100.0)

        # 2. Touch Voltage Component (weight: 0.15)
        voltage_score = min(100.0, (voltage / 100.0) * 100.0)

        # 3. Tilt Component (weight: 0.15)
        tilt_score = min(100.0, (tilt / 30.0) * 100.0)

        # 4. AI Probabilistic Component (weight: 0.15)
        if ai_predicted_class == "CRITICAL":
            ai_risk_score = 100.0 * ai_confidence
        elif ai_predicted_class == "HIGH_RISK":
            ai_risk_score = 75.0 * ai_confidence
        elif ai_predicted_class == "ADVISORY":
            ai_risk_score = 40.0 * ai_confidence
        else:
            ai_risk_score = 5.0

        # 5. Visual Hazard Component (from YOLO / Computer Vision) (weight: 0.20)
        vis_score = (visual_hazard_score * 100.0) if visual_hazard_score else 0.0

        # 6. Environmental Multiplier (rain + humidity)
        env_multiplier = 1.35 if rain else (1.1 if humidity > 80.0 else 1.0)

        raw_cri = (
            (0.35 * leakage_score) +
            (0.15 * voltage_score) +
            (0.15 * tilt_score) +
            (0.15 * ai_risk_score) +
            (0.20 * vis_score)
        ) * env_multiplier

        # Cross-Modal Surge: When visual waterlogging + pedestrian hazard fuses with moderate leakage
        if visual_hazard_score and visual_hazard_score >= 0.80 and current >= 20.0:
            raw_cri = max(raw_cri, 98.2)

        composite_risk_index = round(min(100.0, max(0.0, raw_cri)), 1)
        if risk_level == "CRITICAL":
            composite_risk_index = max(composite_risk_index, 75.0)
        elif risk_level == "EMERGENCY":
            composite_risk_index = max(composite_risk_index, 95.0)

        # Elevate to EMERGENCY or CRITICAL based on CRI
        if composite_risk_index >= 95.0 and (current >= 35.0 or tilt >= 15.0) and risk_level != "EMERGENCY":
            risk_level = "EMERGENCY"
            alert_triggered = True
            if not alert_id:
                alert_id = f"ALT-{uuid.uuid4().hex[:8]}"
            alert_message = f"Catastrophic emergency safety index ({composite_risk_index}/100) exceeded on {telemetry.pole_id}!"
        elif composite_risk_index >= 85.0 and risk_level not in ["CRITICAL", "EMERGENCY"]:
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
            ai_predicted_class=ai_predicted_class,
            ai_confidence=ai_confidence,
            alert_triggered=alert_triggered,
            alert_id=alert_id,
            alert_message=alert_message
        )


decision_engine = DecisionEngine()
