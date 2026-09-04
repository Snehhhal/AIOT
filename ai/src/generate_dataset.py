"""
Synthetic Multi-Sensor Dataset Generator for Electric Pole Safety
==================================================================
Generates realistic, physics-grounded synthetic telemetry data simulating:
- Normal steady operational states
- Insulation degradation / warning advisory conditions
- Monsoon weather-induced high leakage faults
- Vehicular collision / structural tilt hazards
- Critical multi-factor emergencies

Outputs a balanced dataset conforming to IEC 60479-1 standards.
"""

import os
from typing import Tuple
import numpy as np
import pandas as pd

# Default output location
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
DATASET_PATH = os.path.join(DATA_DIR, "pole_safety_dataset.csv")

# Class label mappings
CLASS_NORMAL = 0
CLASS_ADVISORY = 1
CLASS_HIGH_RISK = 2
CLASS_CRITICAL = 3

CLASS_NAMES = {
    CLASS_NORMAL: "NORMAL",
    CLASS_ADVISORY: "ADVISORY",
    CLASS_HIGH_RISK: "HIGH_RISK",
    CLASS_CRITICAL: "CRITICAL",
}


def generate_synthetic_data(num_samples: int = 4000, random_seed: int = 42) -> pd.DataFrame:
    """
    Generates a balanced synthetic dataset of multi-sensor telemetry readings
    with realistic physical noise, environmental multipliers, and ground-truth labels.
    """
    np.random.seed(random_seed)
    samples_per_class = num_samples // 4

    records = []

    # 1. CLASS 0: NORMAL (Safe Steady-State Operations)
    for _ in range(samples_per_class):
        leakage = np.clip(np.random.normal(loc=2.2, scale=1.0), 0.2, 7.5)
        touch_v = np.clip(np.random.normal(loc=1.5, scale=0.8), 0.1, 8.0)
        tilt = np.clip(np.random.normal(loc=0.6, scale=0.4), 0.0, 3.5)
        vib = np.clip(np.random.normal(loc=0.02, scale=0.01), 0.005, 0.08)
        temp = np.random.uniform(22.0, 38.0)
        humidity = np.random.uniform(35.0, 70.0)
        rain = 1 if np.random.random() < 0.08 else 0  # Rare light drizzle without leakage

        records.append({
            "leakage_current_ma": round(float(leakage), 2),
            "touch_voltage_v": round(float(touch_v), 2),
            "tilt_angle_deg": round(float(tilt), 2),
            "vibration_g": round(float(vib), 3),
            "temperature_c": round(float(temp), 1),
            "humidity_pct": round(float(humidity), 1),
            "rain_detected": int(rain),
            "risk_label": CLASS_NORMAL,
            "risk_class": "NORMAL"
        })

    # 2. CLASS 1: ADVISORY (Minor Insulation Degradation or Early Wear)
    for _ in range(samples_per_class):
        # Either moderate leakage (10-25 mA) OR moderate tilt (5-12 deg)
        mode = np.random.choice(["leakage", "tilt"])
        if mode == "leakage":
            leakage = np.clip(np.random.normal(loc=16.0, scale=4.0), 10.0, 27.5)
            touch_v = np.clip(np.random.normal(loc=22.0, scale=8.0), 10.0, 38.0)
            tilt = np.clip(np.random.normal(loc=1.2, scale=0.6), 0.2, 4.0)
            vib = np.clip(np.random.normal(loc=0.04, scale=0.02), 0.01, 0.15)
        else:
            leakage = np.clip(np.random.normal(loc=3.5, scale=1.5), 1.0, 8.5)
            touch_v = np.clip(np.random.normal(loc=3.0, scale=1.5), 0.5, 9.0)
            tilt = np.clip(np.random.normal(loc=8.5, scale=2.0), 5.0, 13.5)
            vib = np.clip(np.random.normal(loc=0.10, scale=0.05), 0.02, 0.35)

        temp = np.random.uniform(24.0, 42.0)
        humidity = np.random.uniform(50.0, 85.0)
        rain = 1 if np.random.random() < 0.20 else 0

        records.append({
            "leakage_current_ma": round(float(leakage), 2),
            "touch_voltage_v": round(float(touch_v), 2),
            "tilt_angle_deg": round(float(tilt), 2),
            "vibration_g": round(float(vib), 3),
            "temperature_c": round(float(temp), 1),
            "humidity_pct": round(float(humidity), 1),
            "rain_detected": int(rain),
            "risk_label": CLASS_ADVISORY,
            "risk_class": "ADVISORY"
        })

    # 3. CLASS 2: HIGH_RISK (Dangerous Leakage or Severe Tilt Hazard)
    for _ in range(samples_per_class):
        fault_type = np.random.choice(["electrical", "structural"])
        if fault_type == "electrical":
            leakage = np.clip(np.random.normal(loc=36.0, scale=5.0), 30.0, 48.0)
            touch_v = np.clip(np.random.normal(loc=58.0, scale=10.0), 45.0, 75.0)
            tilt = np.clip(np.random.normal(loc=1.5, scale=0.8), 0.3, 4.5)
            vib = np.clip(np.random.normal(loc=0.05, scale=0.03), 0.01, 0.20)
            rain = 0  # Dry-condition leakage or moderate humidity
            humidity = np.random.uniform(60.0, 85.0)
        else:
            leakage = np.clip(np.random.normal(loc=4.5, scale=2.0), 1.0, 9.5)
            touch_v = np.clip(np.random.normal(loc=4.0, scale=2.0), 1.0, 10.0)
            tilt = np.clip(np.random.normal(loc=19.5, scale=3.0), 15.0, 26.0)
            vib = np.clip(np.random.normal(loc=0.60, scale=0.25), 0.20, 1.40)
            rain = 1 if np.random.random() < 0.25 else 0
            humidity = np.random.uniform(40.0, 80.0)

        temp = np.random.uniform(22.0, 36.0)

        records.append({
            "leakage_current_ma": round(float(leakage), 2),
            "touch_voltage_v": round(float(touch_v), 2),
            "tilt_angle_deg": round(float(tilt), 2),
            "vibration_g": round(float(vib), 3),
            "temperature_c": round(float(temp), 1),
            "humidity_pct": round(float(humidity), 1),
            "rain_detected": int(rain),
            "risk_label": CLASS_HIGH_RISK,
            "risk_class": "HIGH_RISK"
        })

    # 4. CLASS 3: CRITICAL (Lethal Monsoon Leakage or Collision Collapse)
    for _ in range(samples_per_class):
        fault_type = np.random.choice(["monsoon_leakage", "collision", "extreme_leakage"])
        if fault_type == "monsoon_leakage":
            # Rain + Leakage > 30mA (Lethal touch hazard)
            leakage = np.clip(np.random.normal(loc=46.0, scale=8.0), 32.0, 85.0)
            touch_v = np.clip(np.random.normal(loc=72.0, scale=12.0), 55.0, 110.0)
            tilt = np.clip(np.random.normal(loc=1.8, scale=1.0), 0.5, 6.0)
            vib = np.clip(np.random.normal(loc=0.08, scale=0.04), 0.02, 0.30)
            rain = 1
            humidity = np.random.uniform(92.0, 99.5)
            temp = np.random.uniform(22.0, 27.0)
        elif fault_type == "collision":
            # Vehicular impact: extreme tilt > 20 deg + vibration spike > 1.8g
            leakage = np.clip(np.random.normal(loc=8.0, scale=4.0), 2.0, 22.0)
            touch_v = np.clip(np.random.normal(loc=12.0, scale=6.0), 2.0, 35.0)
            tilt = np.clip(np.random.normal(loc=26.0, scale=5.0), 20.0, 48.0)
            vib = np.clip(np.random.normal(loc=2.8, scale=0.8), 1.6, 4.8)
            rain = 1 if np.random.random() < 0.30 else 0
            humidity = np.random.uniform(45.0, 85.0)
            temp = np.random.uniform(24.0, 35.0)
        else:
            # Extreme electrical breakdown (> 55mA) even without rain
            leakage = np.clip(np.random.normal(loc=65.0, scale=12.0), 52.0, 115.0)
            touch_v = np.clip(np.random.normal(loc=95.0, scale=15.0), 70.0, 150.0)
            tilt = np.clip(np.random.normal(loc=2.0, scale=1.2), 0.5, 8.0)
            vib = np.clip(np.random.normal(loc=0.10, scale=0.05), 0.02, 0.40)
            rain = 1 if np.random.random() < 0.40 else 0
            humidity = np.random.uniform(70.0, 98.0)
            temp = np.random.uniform(20.0, 34.0)

        records.append({
            "leakage_current_ma": round(float(leakage), 2),
            "touch_voltage_v": round(float(touch_v), 2),
            "tilt_angle_deg": round(float(tilt), 2),
            "vibration_g": round(float(vib), 3),
            "temperature_c": round(float(temp), 1),
            "humidity_pct": round(float(humidity), 1),
            "rain_detected": int(rain),
            "risk_label": CLASS_CRITICAL,
            "risk_class": "CRITICAL"
        })

    df = pd.DataFrame(records)
    # Shuffle the dataset
    df = df.sample(frac=1.0, random_state=random_seed).reset_index(drop=True)
    return df


def save_dataset(df: pd.DataFrame, output_path: str = DATASET_PATH) -> str:
    """Saves the dataframe to disk, creating directories as needed."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    df.to_csv(output_path, index=False)
    print(f"[*] Synthetic dataset saved: {output_path} ({len(df)} records)")
    return output_path


if __name__ == "__main__":
    dataset = generate_synthetic_data(num_samples=4000)
    save_dataset(dataset)
    print("\nDataset Class Distribution:")
    print(dataset["risk_class"].value_counts())
