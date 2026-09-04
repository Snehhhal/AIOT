"""
Electric Pole IoT Telemetry Simulator
====================================
Generates synthetic sensor telemetry simulating normal conditions, monsoon leakage faults,
and physical pole collisions. Dispatches standard JSON payloads to the FastAPI backend.

Usage:
    python scripts/simulate_telemetry.py --scenario normal
    python scripts/simulate_telemetry.py --scenario monsoon_leakage
    python scripts/simulate_telemetry.py --scenario collision
    python scripts/simulate_telemetry.py --scenario stream --interval 3
"""

import argparse
import random
import time
import requests

BACKEND_URL = "http://localhost:8000/api/v1/telemetry"


def generate_packet(pole_id: str, scenario: str) -> dict:
    if scenario == "normal":
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(0.5, 4.0), 2),
            "touch_voltage_v": round(random.uniform(0.2, 2.5), 2),
            "tilt_angle_deg": round(random.uniform(0.1, 1.2), 2),
            "vibration_g": round(random.uniform(0.01, 0.05), 3),
            "temperature_c": round(random.uniform(26.0, 32.0), 1),
            "humidity_pct": round(random.uniform(40.0, 60.0), 1),
            "rain_detected": False,
            "is_simulated": True
        }

    elif scenario == "monsoon_leakage":
        # Simulates rain + breakdown of insulation causing high leakage current
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(32.0, 55.0), 2),
            "touch_voltage_v": round(random.uniform(50.0, 85.0), 2),
            "tilt_angle_deg": round(random.uniform(0.5, 2.0), 2),
            "vibration_g": round(random.uniform(0.05, 0.15), 3),
            "temperature_c": round(random.uniform(24.0, 27.0), 1),
            "humidity_pct": round(random.uniform(92.0, 99.0), 1),
            "rain_detected": True,
            "is_simulated": True
        }

    elif scenario == "collision":
        # Simulates car collision or falling tree causing pole tilt
        return {
            "pole_id": pole_id,
            "leakage_current_ma": round(random.uniform(3.0, 8.0), 2),
            "touch_voltage_v": round(random.uniform(1.0, 5.0), 2),
            "tilt_angle_deg": round(random.uniform(18.0, 28.0), 2),
            "vibration_g": round(random.uniform(1.5, 3.2), 3),
            "temperature_c": 28.5,
            "humidity_pct": 55.0,
            "rain_detected": False,
            "is_simulated": True
        }

    else:
        raise ValueError(f"Unknown scenario: {scenario}")


def main():
    parser = argparse.ArgumentParser(description="Electric Pole Telemetry Simulator")
    parser.add_argument(
        "--scenario",
        choices=["normal", "monsoon_leakage", "collision", "stream"],
        default="stream",
        help="Telemetry condition scenario to simulate"
    )
    parser.add_argument("--pole", default="POLE-101", help="Target Pole ID")
    parser.add_argument("--interval", type=int, default=3, help="Interval in seconds for stream mode")
    parser.add_argument("--url", default=BACKEND_URL, help="Backend ingestion endpoint")
    args = parser.parse_args()

    print(f"[*] Starting Telemetry Simulator targeting: {args.url}")
    print(f"[*] Scenario: {args.scenario} | Target Pole: {args.pole}\n")

    if args.scenario != "stream":
        payload = generate_packet(args.pole, args.scenario)
        print(f"[>] Sending packet: {payload}")
        try:
            resp = requests.post(args.url, json=payload, timeout=5)
            print(f"[<] Response ({resp.status_code}): {resp.json()}")
        except Exception as e:
            print(f"[!] Error connecting to backend: {e}")
    else:
        poles = ["POLE-101", "POLE-102", "POLE-103"]
        scenarios = ["normal", "normal", "monsoon_leakage", "normal", "collision"]
        cycle = 0
        try:
            while True:
                pole = poles[cycle % len(poles)]
                scen = scenarios[cycle % len(scenarios)]
                payload = generate_packet(pole, scen)
                print(f"[>] Sending [{scen.upper()}] from {pole}: Current={payload['leakage_current_ma']}mA, Tilt={payload['tilt_angle_deg']}°")
                try:
                    resp = requests.post(args.url, json=payload, timeout=5)
                    data = resp.json().get("data", {})
                    print(f"    [+] Risk Level: {data.get('risk_level')} | CRI: {data.get('composite_risk_index')} | Alert: {data.get('alert_triggered')}")
                except Exception as e:
                    print(f"    [!] Connection error (is backend running?): {e}")

                cycle += 1
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[*] Simulator stopped by user.")


if __name__ == "__main__":
    main()
