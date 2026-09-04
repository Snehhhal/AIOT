# ESP32 Firmware Subsystem

## Overview
Firmware for the pole-mounted ESP32 micro-controller board, developed with **PlatformIO** and **Arduino C++**.

## Responsibilities
1. Sample SCT-013 Current Transformer at 1 kHz to compute true RMS leakage current.
2. Monitor MPU6050 accelerometer for physical pole tilt and impact vibration.
3. Detect precipitation via the FC-37 rain sensor.
4. Execute **Local Hardware Failsafe**: Trigger buzzer, strobe LED, and trip relay immediately if leakage current $> 30\text{ mA}$ (zero cloud latency).
5. Transmit formatted JSON telemetry to FastAPI at `/api/v1/telemetry`.

## Structure
* `platformio.ini`: PlatformIO board configurations and external library dependencies.
* `include/config.h`: Pinout mapping, backend URL, and threshold declarations.
* `src/main.cpp`: FreeRTOS loop, ADC sampling logic, and HTTP client.
