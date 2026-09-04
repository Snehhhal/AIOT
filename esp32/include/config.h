#ifndef CONFIG_H
#define CONFIG_H

// Network Credentials (Set locally or via build flags)
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Central Backend Server Endpoint
#define BACKEND_SERVER_URL "http://192.168.1.100:8000/api/v1/telemetry"
#define POLE_IDENTIFIER "POLE-ESP32-01"

// Pin Definitions
#define PIN_CURRENT_CT 34      // SCT-013 Analog Input (ADC1_CH6)
#define PIN_RAIN_DIGITAL 19    // FC-37 Digital Moisture In
#define PIN_DHT22 4            // DHT22 Temp & Humidity Data
#define PIN_BUZZER 25          // Active 5V Buzzer (Local Alarm)
#define PIN_WARNING_LED 26     // Red Strobe LED
#define PIN_RELAY_TRIP 27      // Solid-State Relay Actuator

// Safety Thresholds
#define THRESHOLD_LEAKAGE_DANGER_MA 30.0f
#define TELEMETRY_INTERVAL_MS 5000

#endif // CONFIG_H
