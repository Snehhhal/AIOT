# PoleGuard — Mock IoT Simulator vs Future Physical ESP32 Hardware

A core design mandate of PoleGuard is ensuring the Flutter application is **genuinely functional today** while providing a seamless transition to physical hardware without redesigning the mobile app or backend APIs.

---

## 1. Strategic Rationale

During academic viva, university evaluations, or classroom presentations:
- Bringing high-voltage electrical hardware (230V AC) or physical electric poles into an examination hall is hazardous and impractical.
- Live weather conditions (e.g. heavy monsoon rain or flash floods) cannot be summoned on command.
- A physical shock hazard cannot be safely demonstrated on real humans.

**PoleGuard solves this by deploying a clearly labelled MOCK IoT Simulator.**
The simulator runs against the **EXACT SAME FastAPI endpoints** (`POST /api/v1/telemetry`) using the **EXACT SAME JSON schema** that the physical ESP32 firmware transmits.

---

## 2. Telemetry Schema Parity (100% Identical)

Whether received from the Python IoT Simulator or from physical ESP32 C++ firmware, the backend ingestion payload is identical:

```json
{
  "pole_id": "P-001",
  "leakage_current_ma": 42.5,
  "touch_voltage_v": 68.2,
  "tilt_angle_deg": 1.4,
  "vibration_g": 0.04,
  "temperature_c": 28.5,
  "humidity_pct": 95.0,
  "rain_detected": true,
  "is_simulated": true
}
```

When physical ESP32 hardware is connected, `is_simulated` is set to `false`. The backend, database, AI models, decision engine, and Flutter app treat the packet identically.

---

## 3. Clear UI Transparency

At no point does the application disguise simulated telemetry as real hardware. The mobile app explicitly displays:

```text
┌────────────────────────────────────────────────────────────────────────┐
│ ● Data Source: MOCK IoT / Simulation Mode (Ready for ESP32) [TEST GPS] │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Hardware Transition Blueprint (Connecting ESP32 in Future)

When physical ESP32 hardware is introduced:
1. Flash the ESP32 microcontroller with code in `esp32/src/main.cpp`.
2. Configure Wi-Fi credentials (`SSID`, `PASSWORD`) and backend IP (`http://<SERVER_IP>:8000/api/v1/telemetry`).
3. Connect sensors:
   - Current Transformer (CT) clamp to ADC Pin 34 (leakage current)
   - Voltage divider to ADC Pin 35 (surface voltage)
   - Rain sensor digital pin to GPIO 25
   - MPU6050 accelerometer to I2C (SDA 21 / SCL 22)
   - 5V Relay module to GPIO 18 (normally closed line isolator)
4. Power the ESP32. It immediately streams real telemetry into the running FastAPI backend.
5. **Zero lines of Flutter code need to be modified.** The mobile app automatically displays the live hardware stream.
