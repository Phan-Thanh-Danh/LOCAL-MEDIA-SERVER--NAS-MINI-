@echo off
chcp 65001 >nul
title Local Media Server - NAS Mini
color 0A

setlocal enabledelayedexpansion

cls

echo.
echo ╔════════════════════════════════════════╗
echo ║  Local Media Server - NAS Mini          ║
echo ║  Browser: Video + Image Viewer          ║
echo ╚════════════════════════════════════════╝
echo.

REM Get LAN IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R "IPv4 Address.*192"') do (
    set "LANIP=%%a"
)
set "LANIP=!LANIP: =!"
if "!LANIP!"=="" set "LANIP=localhost"

echo [1/2] Starting Backend ^(ASP.NET Core^)...
start "Local Media Server Backend" /min cmd /k "cd /d \"D:\LOCAL MEDIA SERVER (NAS MINI)\backend\LocalMediaServer\" && dotnet run --no-build --urls http://0.0.0.0:5000"

echo Waiting for backend...
timeout /t 3 /nobreak >nul

echo [2/2] Starting Frontend ^(Vue.js + Vite^)...
start "Local Media Server Frontend" /min cmd /k "cd /d \"D:\LOCAL MEDIA SERVER (NAS MINI)\frontend\" && npm run dev -- --host 0.0.0.0 --port 5173"

echo Waiting for frontend...
timeout /t 5 /nobreak >nul

echo Opening browser...
start http://192.168.2.10:5173

echo.
echo ════════════════════════════════════════
echo   ✓ Local Media Server Started!
echo ════════════════════════════════════════
echo.
echo Local Access:  http://192.168.2.10:5173
echo LAN Access:    http://!LANIP!:5173
echo.
echo Backend API:   http://127.0.0.1:5000
echo.
echo Services running in background windows.
echo Close those windows to stop the services.
echo ════════════════════════════════════════
echo.

pause

