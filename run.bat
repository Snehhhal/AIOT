@echo off
title PoleGuard AI & IoT Electric Safety Platform
echo ======================================================================
echo           PoleGuard: AI & IoT Electrical Safety Platform
echo ======================================================================
echo.
echo Starting PoleGuard in your workspace...
echo.

cd /d "%~dp0"

REM Check for virtual environment
if not exist ".venv" (
    echo [*] Setting up Python virtual environment...
    python -m venv .venv
    call .venv\Scripts\activate.bat
    echo [*] Installing dependencies from requirements.txt...
    pip install -r requirements.txt
) else (
    call .venv\Scripts\activate.bat
)

echo [*] Starting FastAPI Backend on http://localhost:8000 ...
start "PoleGuard Backend Server" /min .venv\Scripts\uvicorn backend.main:app --host 0.0.0.0 --port 8000

echo [*] Opening PoleGuard Mobile Application in your browser...
timeout /t 2 /nobreak >nul
start "" "index.html"

echo.
echo ======================================================================
echo  [+] Mobile App:      Opened in your browser!
echo  [+] Backend API:     http://localhost:8000/docs
echo  [+] Health Check:    http://localhost:8000/health
echo  [+] Automated Tests: Run 'pytest tests/' to verify all 54 test cases
echo ======================================================================
echo.
pause
