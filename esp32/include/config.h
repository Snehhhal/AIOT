#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// AI & IoT Electric Pole Safety Node - Hardware & Network Configuration
// ============================================================================

// 1. Wi-Fi Station Credentials (Override via build_flags or local edits)
#ifndef WIFI_SSID
#define WIFI_SSID "YOUR_WIFI_SSID"
#endif

#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#endif

// 2. FastAPI Backend Ingestion Endpoints
// Note: Replace 192.168.1.100 with your development workstation host IP
#define BACKEND_SERVER_URL "http://192.168.1.100:8000/api/v1/telemetry"
#define BACKEND_BATCH_URL  "http://192.168.1.100:8000/api/v1/telemetry/batch"
#define POLE_IDENTIFIER    "P-001"

// 3. Hardware Pin Assignments (ESP32 DevKit v1 30-pin / 38-pin)
#define PIN_CURRENT_CT       34  // SCT-013 Split-Core Current Transformer (ADC1_CH6)
#define PIN_VOLTAGE_ADC      35  // ZMPT101B Touch Voltage Potential (ADC1_CH7)
#define PIN_RAIN_DIGITAL     19  // FC-37 / YL-83 Digital Rain Detector (Active LOW)
#define PIN_RAIN_ANALOG      32  // FC-37 Analog Precipitation Moisture Level (ADC1_CH4)
#define PIN_DHT22            4   // DHT22 Enclosure Temperature & Humidity
#define PIN_I2C_SDA          21  // MPU-6050 Accelerometer/Gyroscope I2C Data
#define PIN_I2C_SCL          22  // MPU-6050 Accelerometer/Gyroscope I2C Clock
#define PIN_BUZZER           25  // Active High 5V/3.3V Warning Piezo Buzzer
#define PIN_WARNING_LED      26  // High-Visibility Red Hazard Strobe LED
#define PIN_RELAY_TRIP       27  // Optocoupler Relay Actuator (Grid Isolation Cutoff)
#define PIN_MANUAL_RESET     0   // ESP32 Onboard BOOT Button (Technician Reset / Ack)

// 4. International Safety Standards & Thresholds (IEC 60479-1 Reference)
#define THRESHOLD_LEAKAGE_DANGER_MA   30.0f  // Let-go ventricular fibrillation threshold
#define THRESHOLD_LEAKAGE_WARNING_MA  10.0f  // Insulation degradation advisory limit
#define THRESHOLD_TILT_DANGER_DEG     15.0f  // Physical pole structural collapse limit
#define THRESHOLD_VIBRATION_SPIKE_G   1.5f   // Vehicular collision / tree impact limit

// 5. Analog Signal Processing & Calibration
#define ADC_BITS                    12
#define ADC_MAX_COUNTS              4095
#define ADC_REF_VOLTAGE_V           3.3f
#define MAINS_FREQUENCY_HZ          50
#define CURRENT_CALIBRATION_FACTOR  0.082f   // Empirical scaling factor: RMS counts to mA
#define VOLTAGE_CALIBRATION_FACTOR  0.125f   // Empirical scaling factor: ADC potential to Volts

// 6. Timing & Buffering Parameters
#define TELEMETRY_INTERVAL_MS       3000     // Normal streaming rate (3 seconds)
#define SAMPLING_INTERVAL_MS        10       // High-frequency sensor sample loop (100 Hz)
#define MAX_OFFLINE_BUFFER          24       // Ring buffer capacity during Wi-Fi outages
#define HTTP_TIMEOUT_MS             4000     // Network request timeout

#endif // CONFIG_H
