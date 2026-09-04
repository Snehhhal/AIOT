#!/usr/bin/env bash
# PoleGuard 1-Click Turnkey Launcher for Linux / macOS
set -e

echo "======================================================================"
echo "          PoleGuard: AI & IoT Electrical Safety Platform"
echo "======================================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d ".venv" ]; then
    echo "[*] Setting up Python virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
else
    source .venv/bin/activate
fi

echo "[*] Starting FastAPI Backend on http://localhost:8000 ..."
uvicorn backend.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

sleep 2

echo "[*] Opening PoleGuard Mobile Application..."
if command -v xdg-open > /dev/null; then
    xdg-open index.html
elif command -v open > /dev/null; then
    open index.html
fi

echo ""
echo "======================================================================"
echo "  [+] Mobile App:      Opened in your default browser!"
echo "  [+] Backend API:     http://localhost:8000/docs"
echo "  [+] Health Check:    http://localhost:8000/health"
echo "======================================================================"
echo ""
echo "Press Ctrl+C to stop the backend."
trap "kill $BACKEND_PID 2>/dev/null || true; exit 0" INT TERM
wait $BACKEND_PID
