# Flutter Mobile Field & Citizen Application

## Overview
Cross-platform mobile application providing:
1. **Lineman Field Client:**
   - Real-time GIS map of sector utility poles and current leakage states.
   - Push notifications for critical leakage / pole tilt incidents.
   - On-site photo capture for automated YOLO hazard inspection.
   - Interactive RAG Safety Assistant chat for de-energization guidelines.
   - Offline SQLite synchronization.
2. **Citizen Safety Perimeter Warnings:**
   - Geo-fenced proximity alert if approaching a live energized/leaking pole in waterlogged conditions.

## Architecture
* Built with **Flutter (Dart)**.
* State management: Provider / Riverpod.
* Offline storage: SQLite / Sqflite.
* Mapping: `flutter_map` with OpenStreetMap vector tiles.
