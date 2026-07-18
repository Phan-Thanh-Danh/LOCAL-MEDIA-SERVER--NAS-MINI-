@echo off
setlocal

echo Checking dependencies...
where dotnet >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: dotnet is not installed or not in PATH.
    pause
    exit /b 1
)

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: node is not installed or not in PATH.
    pause
    exit /b 1
)

where cloudflared >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: cloudflared is not installed or not in PATH.
    pause
    exit /b 1
)

echo Dependencies found!
echo.
echo [1/3] Starting NAS - Backend...
start "NAS - Backend" cmd /c "cd backend\LocalMediaServer && dotnet run --urls http://0.0.0.0:5000"
echo Waiting 10 seconds for Backend to initialize...
timeout /t 10 /nobreak >nul

echo [2/3] Starting NAS - Frontend...
start "NAS - Frontend" cmd /c "cd frontend && npm run dev -- --host 0.0.0.0 --port 5173"
echo Waiting 8 seconds for Frontend to initialize...
timeout /t 8 /nobreak >nul

echo [3/3] Starting NAS - Cloudflare Tunnel...
start "NAS - Cloudflare Tunnel" cmd /k "cloudflared tunnel --url https://localhost:5173 --no-tls-verify --protocol http2"

echo.
echo ===============================================================================
echo ALL SERVICES STARTED!
echo Please look for the "NAS - Cloudflare Tunnel" window.
echo The public link will appear there in the format: https://xxxx.trycloudflare.com
echo ===============================================================================
pause
