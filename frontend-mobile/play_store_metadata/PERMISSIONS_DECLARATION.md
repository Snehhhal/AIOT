# PoleGuard Android Permissions Rationale & Declaration

This document specifies the purpose and rationale for all requested Android permissions in the `AndroidManifest.xml` of the PoleGuard application.

| Permission | Protection Level | Purpose & Justification |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | Normal | Required to stream real-time IoT telemetry, transmit SOS reports, receive critical hazard alerts, and communicate with the FastAPI backend and WebSocket server. |
| `android.permission.ACCESS_NETWORK_STATE` | Normal | Required by the offline-first sync engine to detect cellular/Wi-Fi transitions and automatically synchronize queued offline incident reports. |
| `android.permission.ACCESS_FINE_LOCATION` | Dangerous | Required when reporting hazardous or sparking utility poles so emergency crews receive exact geographic coordinates ($\pm 5m$). Also used to display nearby energized poles on the citizen safety map. |
| `android.permission.ACCESS_COARSE_LOCATION` | Dangerous | Serves as a fallback low-power location mechanism when GPS satellites are obscured by dense urban high-rises or storm clouds. |
| `android.permission.CAMERA` | Dangerous | Required by both Citizens and Technicians to capture on-site photographic evidence of physical damage, broken insulators, tilt, or waterlogging for the Computer Vision AI pipeline. |
| `android.permission.VIBRATE` | Normal | Used to trigger distinctive tactile high-priority haptic feedback patterns during CRITICAL and EMERGENCY electrical leakage alerts. |
| `android.permission.READ_EXTERNAL_STORAGE` | Dangerous (API $\le 32$) | Allows field personnel to select pre-captured photos of damaged utility infrastructure from the device gallery for submission. |
| `android.permission.READ_MEDIA_IMAGES` | Dangerous (API $\ge 33$) | Android 13+ granular permission replacing READ_EXTERNAL_STORAGE for selecting inspection evidence photos. |

## User Privacy Protection
- No background location tracking is performed when the application is closed.
- Camera is accessed strictly upon explicit user interaction in the hazard submission dialog.
- All sensitive device identifiers are omitted from API telemetry payloads.
