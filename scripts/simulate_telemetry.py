"""
Electric Pole IoT Telemetry Simulator
====================================
Generates synthetic sensor telemetry simulating normal conditions, monsoon leakage faults,
physical pole collisions, human proximity scenarios, and offline batch resynchronization.
Dispatches standard JSON payloads to the FastAPI backend using standard library urllib.

Usage:
    python scripts/simulate_telemetry.py --scenario normal --pole P-001
    python scripts/simulate_telemetry.py --scenario monsoon_leakage --pole P-002
    python scripts/simulate_telemetry.py --scenario collision --pole P-003
    python scripts/simulate_telemetry.py --scenario human_proximity --pole P-004
    python scripts/simulate_telemetry.py --scenario burst --pole P-001 --batch-size 12
    python scripts/simulate_telemetry.py --scenario stream --interval 3 --count 10
"""

import argparse
from datetime import datetime, timedelta, timezone
import json
import random
import time
from typing import Any, Dict, List, Optional, Tuple
import urllib.request
import urllib.error

DEFAULT_URL = "http://localhost:8000/api/v1/telemetry"
DEFAULT_BATCH_URL = "http://localhost:8000/api/v1/telemetry/batch"
DEFAULT_POLES = ["P-001", "P-002", "P-003", "P-004"]


def generate_packet(
    pole_id: str = "P-001",
    scenario: str = "normal",
    recorded_at: Optional[datetime] = None
) -> Dict[str, Any]:
    """
    Generates a single standardized telemetry packet matching the TelemetryIn schema.
    """
    ts = (recorded_at or datetime.now(timezone.utc)).isoformat()

    if scenario == "normal":
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(1.2, 3.8), 2),
            "touch_voltage_v": round(random.uniform(0.5, 2.2), 2),
            "tilt_angle_deg": round(random.uniform(0.2, 0.9), 2),
            "vibration_g": round(random.uniform(0.01, 0.04), 3),
            "temperature_c": round(random.uniform(27.0, 31.5), 1),
            "humidity_pct": round(random.uniform(45.0, 58.0), 1),
            "rain_detected": False,
            "is_simulated": True,
            "recorded_at": ts,
        }

    elif scenario == "monsoon_leakage":
        # Simulates heavy rain + insulation breakdown (>30 mA IEC let-go danger threshold)
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(35.0, 58.0), 2),
            "touch_voltage_v": round(random.uniform(55.0, 82.0), 2),
            "tilt_angle_deg": round(random.uniform(0.8, 2.2), 2),
            "vibration_g": round(random.uniform(0.05, 0.18), 3),
            "temperature_c": round(random.uniform(23.5, 26.5), 1),
            "humidity_pct": round(random.uniform(93.0, 99.0), 1),
            "rain_detected": True,
            "is_simulated": True,
            "recorded_at": ts,
        }

    elif scenario == "collision":
        # Simulates car collision or mechanical impact causing tilt > 15 deg & vibration spike
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(3.5, 7.5), 2),
            "touch_voltage_v": round(random.uniform(1.5, 4.5), 2),
            "tilt_angle_deg": round(random.uniform(18.5, 27.5), 2),
            "vibration_g": round(random.uniform(2.1, 4.2), 3),
            "temperature_c": 28.5,
            "humidity_pct": 52.0,
            "rain_detected": False,
            "is_simulated": True,
            "recorded_at": ts,
        }

    elif scenario == "human_proximity":
        # Elevated leakage during wet conditions ready for Computer Vision fusion
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(28.0, 38.0), 2),
            "touch_voltage_v": round(random.uniform(38.0, 65.0), 2),
            "tilt_angle_deg": round(random.uniform(0.6, 1.4), 2),
            "vibration_g": round(random.uniform(0.02, 0.08), 3),
            "temperature_c": 25.0,
            "humidity_pct": 96.0,
            "rain_detected": True,
            "is_simulated": True,
            "recorded_at": ts,
        }

    else:
        raise ValueError(
            f"Unknown scenario: '{scenario}'. Valid scenarios: normal, monsoon_leakage, collision, human_proximity."
        )


def generate_batch(
    pole_id: str = "P-001",
    count: int = 10,
    final_scenario: str = "monsoon_leakage",
    interval_seconds: int = 60
) -> Dict[str, Any]:
    """
    Generates a chronological batch of readings simulating an edge node recovering
    from an offline interval and dumping stored packets via /api/v1/telemetry/batch.
    """
    now = datetime.now(timezone.utc)
    readings: List[Dict[str, Any]] = []

    for i in range(count):
        # Earliest points are normal, later points escalate to final_scenario
        point_time = now - timedelta(seconds=(count - 1 - i) * interval_seconds)
        if i < count // 2:
            scen = "normal"
        else:
            scen = final_scenario
        readings.append(generate_packet(pole_id=pole_id, scenario=scen, recorded_at=point_time))

    return {
        "pole_id": pole_id,
        "readings": readings
    }


def send_packet(url: str, payload: Dict[str, Any], timeout: int = 5) -> Tuple[int, Dict[str, Any]]:
    """Dispatches a single telemetry packet to the ingestion endpoint."""
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json", "User-Agent": "AIoT-TelemetrySimulator/1.0"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            status_code = response.status
            body = json.loads(response.read().decode("utf-8"))
            return status_code, body
    except urllib.error.HTTPError as e:
        status_code = e.code
        try:
            body = json.loads(e.read().decode("utf-8"))
        except Exception:
            body = {"error": str(e)}
        return status_code, body


def send_batch(url: str, batch_payload: Dict[str, Any], timeout: int = 8) -> Tuple[int, Dict[str, Any]]:
    """Dispatches a batch payload to the batch ingestion endpoint."""
    return send_packet(url, batch_payload, timeout=timeout)


def run_stream(
    url: str,
    poles: List[str],
    interval: int = 3,
    max_count: Optional[int] = None
) -> None:
    """
    Streams telemetry periodically cycling across utility poles and scenario states.
    """
    scenarios = [
        "normal",
        "normal",
        "monsoon_leakage",
        "normal",
        "collision",
        "human_proximity"
    ]
    cycle = 0

    print(f"[*] Starting telemetry stream on {len(poles)} poles (interval={interval}s)...")
    try:
        while True:
            if max_count is not None and cycle >= max_count:
                print(f"[*] Completed {cycle} stream iterations. Exiting.")
                break

            pole = poles[cycle % len(poles)]
            scen = scenarios[cycle % len(scenarios)]
            payload = generate_packet(pole_id=pole, scenario=scen)

            print(f"[>] [{cycle + 1}] Sending [{scen.upper()}] from {pole}: "
                  f"I={payload['leakage_current_ma']}mA, "
                  f"V={payload['touch_voltage_v']}V, "
                  f"Tilt={payload['tilt_angle_deg']}°, Rain={payload['rain_detected']}")

            try:
                status_code, resp_json = send_packet(url, payload)
                if status_code == 201:
                    data = resp_json.get("data", {})
                    print(f"    [+] Evaluated -> Risk: {data.get('risk_level')} | "
                          f"CRI: {data.get('composite_risk_index')}/100 | "
                          f"Alert: {data.get('alert_triggered')}")
                else:
                    print(f"    [-] Server returned status {status_code}: {resp_json}")
            except Exception as e:
                print(f"    [!] Ingestion error (is backend running at {url}?): {e}")

            cycle += 1
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\n[*] Telemetry stream halted by operator.")


def main():
    parser = argparse.ArgumentParser(
        description="Electric Pole AI & IoT Telemetry Simulator",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--scenario",
        choices=["normal", "monsoon_leakage", "collision", "human_proximity", "stream", "burst"],
        default="stream",
        help="Telemetry simulation scenario"
    )
    parser.add_argument("--pole", default="P-001", help="Target Pole ID (e.g. P-001, P-002, P-003, P-004)")
    parser.add_argument("--interval", type=int, default=3, help="Interval in seconds for stream mode")
    parser.add_argument("--count", type=int, default=None, help="Number of packets to send before exiting (for stream)")
    parser.add_argument("--batch-size", type=int, default=10, help="Number of readings to generate for burst mode")
    parser.add_argument("--url", default=DEFAULT_URL, help="Single-reading ingestion endpoint URL")
    parser.add_argument("--batch-url", default=DEFAULT_BATCH_URL, help="Batch ingestion endpoint URL")
    args = parser.parse_args()

    print("=" * 60)
    print(" AI + IoT Electric Pole Safety - Telemetry Simulator")
    print("=" * 60)
    print(f" Target Mode   : {args.scenario.upper()}")
    print(f" Target Pole   : {args.pole}")
    print(f" Ingestion URL : {args.url}")
    print("-" * 60)

    if args.scenario == "burst":
        print(f"[*] Generating offline buffered burst of {args.batch_size} readings for {args.pole}...")
        batch_payload = generate_batch(pole_id=args.pole, count=args.batch_size)
        try:
            status_code, resp_json = send_batch(args.batch_url, batch_payload)
            print(f"[<] Response ({status_code}): {resp_json}")
        except Exception as e:
            print(f"[!] Error connecting to batch endpoint at {args.batch_url}: {e}")

    elif args.scenario == "stream":
        run_stream(
            url=args.url,
            poles=DEFAULT_POLES,
            interval=args.interval,
            max_count=args.count
        )

    else:
        payload = generate_packet(pole_id=args.pole, scenario=args.scenario)
        print(f"[>] Dispatching {args.scenario} payload: {payload}")
        try:
            status_code, resp_json = send_packet(args.url, payload)
            print(f"[<] Response ({status_code}): {resp_json}")
        except Exception as e:
            print(f"[!] Error connecting to backend at {args.url}: {e}")


if __name__ == "__main__":
    main()
