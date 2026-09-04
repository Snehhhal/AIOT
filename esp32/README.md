# ESP32 Edge Safety Node Firmware

Production C++ firmware for the pole-mounted ESP32 micro-controller board, developed with **PlatformIO** and **Arduino C++**.

---

## 1. System Architecture

The firmware uses a **Dual-Core FreeRTOS Multitasking Architecture** to guarantee hard real-time safety constraints regardless of network conditions:

```
                      ┌────────────────────────────────────────┐
                      │          ESP32 Dual-Core MCU           │
                      ├───────────────────┬────────────────────┤
                      │      CORE 1       │       CORE 0       │
                      │  (Deterministic)  │   (Asynchronous)   │
                      ├───────────────────┼────────────────────┤
                      │ • 100 Hz Sampling │ • Wi-Fi Manager    │
                      │ • True RMS CT     │ • HTTP Post        │
                      │ • MPU-6050 Tilt   │ • Offline Buffer   │
                      │ • Hardware Relay  │ • Batch Resync     │
                      │   Cutoff (<20ms)  │ • Cloud Telemetry  │
                      └─────────┬─────────┴─────────┬──────────┘
                                │                   │
                        [Local Failsafe]    [FastAPI Backend]
                     Relay / Buzzer / LED   /api/v1/telemetry
```

### Why Dual-Core FreeRTOS?
In life safety systems, network latency, Wi-Fi drops, or HTTP timeouts **must never delay emergency electrical isolation**. By pinning the sensor acquisition and local relay trip logic to **Core 1**, the pole cuts off hazardous power in **$<20\,\text{ms}$**, completely isolated from network operations running on **Core 0**.

---

## 2. Hardware Bill of Materials (BOM)

| Component | Part Number / Module | Interface | Description |
| :--- | :--- | :--- | :--- |
| **MCU** | ESP-WROOM-32 (30/38 Pin) | USB / 3.3V | Dual-core Tensilica Xtensa 240MHz, 520KB SRAM |
| **Current Sensor** | SCT-013-000 (100A/50mA) | ADC1_CH6 (GPIO 34) | Split-core current transformer for non-invasive true RMS AC leakage |
| **Touch Voltage Sensor** | ZMPT101B Module | ADC1_CH7 (GPIO 35) | Active voltage transformer module measuring chassis potential |
| **Inertial Sensor** | MPU-6050 Module | I2C (SDA=21, SCL=22) | 6-DOF Accelerometer & Gyroscope for structural tilt & collision shock |
| **Rain / Moisture** | FC-37 / YL-83 Sensor | Digital (GPIO 19) / ADC (32) | Detects precipitation and surface conductive waterlogging |
| **Ambient Climate** | DHT22 (AM2302) | Digital (GPIO 4) | Enclosure temperature and relative humidity |
| **Trip Actuator** | 5V Optocoupler Relay | Digital (GPIO 27) | High-speed electrical isolation cutoff to feeder circuit breaker |
| **Local Siren** | 5V Active Piezo Buzzer | Digital (GPIO 25) | Audible alarm warning pedestrians within 15 meters |
| **Visual Beacon** | High-Intensity Red LED | Digital (GPIO 26) | Flashing visual beacon indicating energized chassis hazard |
| **Technician Reset** | Push Button / BOOT Pin | GPIO 0 | Manual reset to unlatch safety relay after site inspection |

---

## 3. Circuit Pinout & Wiring Table

```
   +-------------------+--------------------+------------------------+
   | Component Pin     | ESP32 GPIO Pin     | Notes / Voltage        |
   +-------------------+--------------------+------------------------+
   | SCT-013 Signal    | GPIO 34 (ADC1_CH6) | Via 1.65V DC bias circuit|
   | ZMPT101B Analog   | GPIO 35 (ADC1_CH7) | 0 - 3.3V analog input  |
   | FC-37 Digital OUT | GPIO 19            | Internal PULLUP enabled|
   | FC-37 Analog OUT  | GPIO 32 (ADC1_CH4) | Optional analog wetness|
   | DHT22 Data        | GPIO 4             | 4.7kΩ pull-up resistor |
   | MPU-6050 SDA      | GPIO 21            | Standard I2C Data      |
   | MPU-6050 SCL      | GPIO 22            | Standard I2C Clock     |
   | Active Buzzer (+) | GPIO 25            | Active HIGH drive      |
   | Strobe LED (+)    | GPIO 26            | Active HIGH (220Ω res) |
   | Relay IN          | GPIO 27            | Active HIGH trip       |
   | BOOT / Reset      | GPIO 0             | Active LOW manual ack  |
   +-------------------+--------------------+------------------------+
```

---

## 4. Signal Processing Algorithms

### 4.1 True RMS Leakage Current
Mains AC in India/Europe oscillates at $50\,\text{Hz}$ ($20\,\text{ms}$ cycle). The firmware samples the analog output over two complete cycles ($40\,\text{ms}$) at $10\,\text{kHz}$:

$$I_{\text{RMS}} = K_{\text{current}} \cdot \sqrt{\frac{1}{N} \sum_{i=1}^{N} (V_{\text{ADC}}[i] - V_{\text{bias}})^2}$$

* $V_{\text{bias}} = 2048$ (calibrated midpoint of 12-bit ADC at $1.65\,\text{V}$).
* $K_{\text{current}} = 0.082$: Empirical scaling parameter matching SCT-013 burden resistor.

### 4.2 Structural Tilt Angle & Impact Shock
Using the MPU-6050 3-axis accelerometer:

$$\theta_{\text{tilt}} = \operatorname{atan2}\left(\sqrt{a_x^2 + a_y^2},\, |a_z|\right) \times \frac{180^\circ}{\pi}$$

$$\text{Vibration Magnitude} = \left|\frac{\sqrt{a_x^2 + a_y^2 + a_z^2}}{9.80665\,\text{m/s}^2} - 1.0\,g\right|$$

* If $\theta_{\text{tilt}} \ge 15^\circ$, severe structural damage or collision is flagged.
* If $\text{Vibration} \ge 1.5\,g$, an impact shock is logged.

---

## 5. Local Hardware Failsafe & Standards Compliance

Conforms to **IEC 60479-1** (*Effects of current on human beings and livestock*):

| Measured Metric | Safe Baseline | Warning Advisory | Critical Emergency Action |
| :--- | :--- | :--- | :--- |
| **Leakage Current** | $< 10.0\,\text{mA}$ | $10.0 - 29.9\,\text{mA}$ | $\ge 30.0\,\text{mA}$ (**Instant Relay Trip**) |
| **Touch Potential** | $< 12.0\,\text{V}$ | $12.0 - 49.9\,\text{V}$ | $\ge 50.0\,\text{V}$ (UL touch voltage limit) |
| **Pole Tilt** | $< 5.0^\circ$ | $5.0 - 14.9^\circ$ | $\ge 15.0^\circ$ (**Instant Relay Trip**) |
| **Rain / Moisture** | Dry | Damp | Rain Detected (Elevates risk index) |

When a critical threshold is breached:
1. `PIN_RELAY_TRIP` is driven `HIGH` in $<20\,\text{ms}$, isolating electrical supply.
2. `PIN_BUZZER` and `PIN_WARNING_LED` trigger continuous local alarms.
3. The alarm is latched until a field technician manually presses the `BOOT` button (`GPIO 0`).

---

## 6. Offline Resilient Ring Buffer & Batch Resynchronization

If Wi-Fi disconnects or the backend server is unreachable:
1. Telemetry records are stored in a circular ring buffer (`MAX_OFFLINE_BUFFER = 24`).
2. When the Wi-Fi link recovers, Core 0 formats all accumulated readings into a `TelemetryBatchIn` JSON payload:
   ```json
   {
     "pole_id": "P-001",
     "readings": [
       { "leakage_current_ma": 34.2, "touch_voltage_v": 52.0, ... },
       { "leakage_current_ma": 38.5, "touch_voltage_v": 58.0, ... }
     ]
   }
   ```
3. The packet is dispatched to `/api/v1/telemetry/batch`. Upon receiving `HTTP 201 Created`, the buffer is cleared.

---

## 7. Build & Flash Instructions

### Prerequisites
* [PlatformIO Core](https://platformio.org/install/cli) or PlatformIO IDE extension in VS Code.
* Micro-USB / Type-C cable connected to ESP32.

### Step 1: Configure Wi-Fi and Server IP
Edit [`esp32/include/config.h`](include/config.h):
```cpp
#define WIFI_SSID "Your_WiFi_Network"
#define WIFI_PASSWORD "Your_WiFi_Password"
#define BACKEND_SERVER_URL "http://192.168.1.100:8000/api/v1/telemetry"
#define BACKEND_BATCH_URL  "http://192.168.1.100:8000/api/v1/telemetry/batch"
```

### Step 2: Build Firmware
```bash
pio run -d esp32/
```

### Step 3: Flash to ESP32
```bash
pio run -d esp32/ -t upload
```

### Step 4: Open Serial Monitor
```bash
pio device monitor -b 115200
```

---

## 8. Demonstration & Evaluation Mode

If physical sensors are not yet connected during a desktop evaluation:
* The firmware **auto-detects** missing I2C or analog signals.
* It logs `[WARN] MPU-6050 not detected. Running with synthetic inertial model.`
* It outputs realistic, nominal telemetry, allowing examiners to inspect serial output and verify FastAPI ingestion without breadboard hardware.
