# PoleGuard — Production Deployment & Operations Runbook

> **Complete End-to-End Deployment Guide for Backend, AI Engine, Docker, ESP32 Edge, and Flutter Mobile**

---

## 1. System Requirements & Prerequisites

### Server / Host Machine
* **Operating System**: Ubuntu 22.04 LTS / Debian 12 / Windows 11 / macOS (arm64/x86_64)
* **CPU**: 2+ Cores (4 Cores recommended for concurrent Computer Vision inference)
* **RAM**: Minimum 4 GB (8 GB recommended for ChromaDB vector embeddings)
* **Disk**: 15 GB free space (Docker images, model weights, and SQLite/PostgreSQL storage)
* **Ports**: `8000` (FastAPI REST/WSS), `80/443` (Reverse Proxy), `5432` (PostgreSQL optional)

### Software Toolchains
* **Python**: 3.11 or 3.12 (`python --version`)
* **Docker & Docker Compose**: Docker Engine 24+ and Compose V2
* **Flutter**: Flutter SDK 3.19+ with Android SDK Build-Tools 34.0.0
* **PlatformIO**: Core CLI or VS Code Extension (for ESP32 flashing)

---

## 2. Fast-Track Containerized Deployment (Recommended)

The easiest and most reliable method to deploy PoleGuard is via Docker Compose:

### Step 1: Clone Repository & Configure Environment
```bash
git clone https://github.com/Snehhhal/AIOT.git
cd AIOT

# Copy sample configuration to active .env
cp .env.example .env
```

### Step 2: Review Environment Settings
Open `.env` in your editor and verify:
```ini
APP_ENV=production
DEBUG=false
JWT_SECRET_KEY=change-this-to-a-secure-random-token-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=1440
SIMULATION_MODE=true
```

### Step 3: Launch Containers
```bash
docker compose up --build -d
```

### Step 4: Verify Container Health
```bash
docker compose ps
curl http://localhost:8000/health
```
*Expected Output:*
```json
{"status":"ok","timestamp":"2026-09-05T00:00:00.000000","version":"1.0.0"}
```

---

## 3. Native Python Host Deployment (Without Docker)

For bare-metal Ubuntu/Debian Linux installations:

### Step 1: Install System Dependencies
```bash
sudo apt update && sudo apt install -y python3-venv python3-pip curl build-essential git
```

### Step 2: Set Up Virtual Environment & Dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 3: Run Full Verification Suite
```bash
pytest tests/ -v -o pythonpath=.
```
Ensure all 54 tests pass before proceeding to systemd daemon setup.

### Step 4: Configure systemd Service Daemon
Create `/etc/systemd/system/poleguard.service`:
```ini
[Unit]
Description=PoleGuard AI & IoT Electric Safety Core
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/AIOT
EnvironmentFile=/opt/AIOT/.env
ExecStart=/opt/AIOT/.venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start the daemon:
```bash
sudo systemctl daemon-reload
sudo systemctl enable poleguard
sudo systemctl start poleguard
sudo systemctl status poleguard
```

---

## 4. Production Nginx Reverse Proxy with TLS (HTTPS/WSS)

To expose PoleGuard securely over the internet for the mobile application:

### Step 1: Install Nginx & Certbot
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### Step 2: Configure Virtual Host
Create `/etc/nginx/sites-available/poleguard`:
```nginx
server {
    server_name api.poleguard.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
```

Enable configuration and issue SSL:
```bash
sudo ln -s /etc/nginx/sites-available/poleguard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d api.poleguard.yourdomain.com
```

---

## 5. Compiling the Flutter Mobile Application

The Flutter application (`frontend-mobile/`) compiles to standard Android Release packages (`.apk` or `.aab`).

### Step 1: Navigate to Flutter Directory
```bash
cd frontend-mobile
flutter pub get
```

### Step 2: Build Debug APK (For Testing on Physical Devices)
```bash
flutter build apk --debug
```
*Output Location:* `build/app/outputs/flutter-apk/app-debug.apk`

### Step 3: Build Production Release APK
```bash
flutter build apk --release
```
*Output Location:* `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Build Google Play Store App Bundle (`.aab`)
```bash
flutter build appbundle --release
```
*Output Location:* `build/app/outputs/bundle/release/app-release.aab`

---

## 6. Flashing ESP32 Edge Firmware

The physical IoT sensor node runs dual-core FreeRTOS C++ firmware.

### Hardware Connection
Connect the ESP32 development board (NodeMCU-32S / ESP32-WROOM-32) to your computer via micro-USB.

### Configuration
Edit `esp32/src/main.cpp`:
```cpp
// Set local Wi-Fi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Set Backend API endpoint
const char* serverUrl = "http://192.168.1.100:8000/api/v1/telemetry";
```

### Flash using PlatformIO
```bash
cd esp32
pio run --target upload
pio device monitor --baud 115200
```

---

## 7. Operational Troubleshooting

| Symptom | Probable Root Cause | Resolution |
| :--- | :--- | :--- |
| `HTTP 403 Forbidden` on API call | Role-Based Access Control (RBAC) rejection | Ensure JWT Bearer token has required role (`AUTHORITY` for grid cutoff, `ADMIN` for users). |
| WebSocket disconnected in Mobile App | Network firewall or reverse proxy timeout | Ensure Nginx has `Upgrade $http_upgrade` headers enabled with `proxy_read_timeout 86400;`. |
| Mobile app shows "Network Error" | Connecting to `localhost` instead of LAN IP | In Android emulator, use `10.0.2.2:8000`. On physical phone, use host machine's Wi-Fi IP (e.g. `192.168.1.50:8000`). |
| Database locked error in SQLite | Concurrent synchronous writes | PoleGuard backend uses `aiosqlite` async driver with WAL mode enabled. Check file permissions on `data/`. |
