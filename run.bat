@echo off
title PoleGuard AI & IoT Electric Safety Platform
echo ======================================================================
echo           PoleGuard: AI & IoT Electrical Safety Platform
echo ======================================================================
echo.
echo Starting PoleGuard in your workspace...
echo.

cd /d "%~dp0"

REM Check for virtual environment (local or sibling AIOT)
if exist ".venv\Scripts\activate.bat" (
    call .venv\Scripts\activate.bat
    set "PYTHON_EXE=.venv\Scripts\python.exe"
    set "UVICORN_EXE=.venv\Scripts\uvicorn.exe"
) else if exist "..\AIOT\.venv\Scripts\activate.bat" (
    call ..\AIOT\.venv\Scripts\activate.bat
    set "PYTHON_EXE=..\AIOT\.venv\Scripts\python.exe"
    set "UVICORN_EXE=..\AIOT\.venv\Scripts\uvicorn.exe"
) else (
    echo [*] Setting up Python virtual environment...
    python -m venv .venv
    call .venv\Scripts\activate.bat
    set "PYTHON_EXE=.venv\Scripts\python.exe"
    set "UVICORN_EXE=.venv\Scripts\uvicorn.exe"
    echo [*] Installing dependencies from requirements.txt...
    pip install -r requirements.txt
)

echo [*] Starting FastAPI Backend on http://localhost:8000 ...
start "PoleGuard Backend Server" /min "%UVICORN_EXE%" backend.main:app --host 0.0.0.0 --port 8000 --reload

echo [*] Opening PoleGuard Mobile Application in your browser...
timeout /t 2 /nobreak >nul
start "" "index.html"

echo.
echo ======================================================================
echo  [+] Mobile App:      Opened in your browser!
echo  [+] Backend API:     http://localhost:8000/docs
echo  [+] Health Check:    http://localhost:8000/health
echo  [+] Automated Tests: Run 'pytest tests/' to verify all 68 test cases
echo  [+] Native Flutter:   cd frontend-mobile && flutter run
echo ======================================================================
echo.
pause
