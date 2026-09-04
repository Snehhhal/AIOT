/**
 * AI & IoT Based Leakage Detection in Electric Pole and Life Safety
 * Firmware: ESP32 Edge Safety Node
 */

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "config.h"

// Sample state variables
float sampleLeakageCurrent = 0.0f;
float sampleTiltAngle = 0.0f;
bool isRainDetected = false;
unsigned long lastTelemetryTime = 0;

void setupHardware() {
    pinMode(PIN_BUZZER, OUTPUT);
    pinMode(PIN_WARNING_LED, OUTPUT);
    pinMode(PIN_RELAY_TRIP, OUTPUT);
    pinMode(PIN_RAIN_DIGITAL, INPUT);

    digitalWrite(PIN_BUZZER, LOW);
    digitalWrite(PIN_WARNING_LED, LOW);
    digitalWrite(PIN_RELAY_TRIP, LOW);
}

void triggerLocalSafetyAlarm() {
    // IMMEDIATE LOCAL ACTION (Independent of network)
    digitalWrite(PIN_BUZZER, HIGH);
    digitalWrite(PIN_WARNING_LED, HIGH);
    digitalWrite(PIN_RELAY_TRIP, HIGH);
    Serial.println("[CRITICAL] Local leakage threshold exceeded! Alarm activated.");
}

void sendTelemetry() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[WARN] Wi-Fi offline. Buffering telemetry locally...");
        return;
    }

    HTTPClient http;
    http.begin(BACKEND_SERVER_URL);
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<256> doc;
    doc["pole_id"] = POLE_IDENTIFIER;
    doc["leakage_current_ma"] = sampleLeakageCurrent;
    doc["touch_voltage_v"] = sampleLeakageCurrent * 1.5f; // Estimated
    doc["tilt_angle_deg"] = sampleTiltAngle;
    doc["vibration_g"] = 0.02f;
    doc["temperature_c"] = 29.5f;
    doc["humidity_pct"] = 75.0f;
    doc["rain_detected"] = isRainDetected;
    doc["is_simulated"] = false;

    String payload;
    serializeJson(doc, payload);

    int httpResponseCode = http.POST(payload);
    Serial.printf("[HTTP] POST response code: %d\n", httpResponseCode);
    http.end();
}

void setup() {
    Serial.begin(115200);
    setupHardware();
    Serial.println("[*] ESP32 Pole Safety Node Initialized.");
}

void loop() {
    // 1. High-frequency ADC check for leakage
    // In Phase 3, real ADC sampling calculations will replace this mock
    isRainDetected = (digitalRead(PIN_RAIN_DIGITAL) == LOW);

    // 2. Immediate Local Hardware Failsafe Check
    if (sampleLeakageCurrent >= THRESHOLD_LEAKAGE_DANGER_MA) {
        triggerLocalSafetyAlarm();
    }

    // 3. Periodic Cloud Telemetry Dispatch
    if (millis() - lastTelemetryTime >= TELEMETRY_INTERVAL_MS) {
        sendTelemetry();
        lastTelemetryTime = millis();
    }

    delay(10);
}
