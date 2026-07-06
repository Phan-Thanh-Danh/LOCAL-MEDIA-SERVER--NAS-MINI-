@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ==========================================
echo    Local Media Server - Starter
echo ==========================================

:: Kiểm tra dotnet
where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo [LỖI] Không tìm thấy dotnet. Vui lòng cài đặt .NET SDK.
    cmd /k
    exit /b
)

:: Kiểm tra node
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [LỖI] Không tìm thấy node. Vui lòng cài đặt Node.js.
    cmd /k
    exit /b
)

:: Lấy LAN IP động
set "LANIP="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"IPv4 Address" /c:"IPv4"') do (
    set "LANIP=%%A"
)
set "LANIP=!LANIP: =!"
if "!LANIP!"=="" set "LANIP=192.168.2.10"

echo [1/3] Đang khởi động Backend...
start "Local Media Server Backend" cmd /k "cd /d ""%~dp0"" && dotnet run --project backend\LocalMediaServer\LocalMediaServer.csproj --urls ""http://0.0.0.0:5000"""

echo [2/3] Đang chờ Backend khởi động (tối đa 30s)...
set "BACKEND_OK=0"
for /L %%i in (1,1,30) do (
    curl -s http://127.0.0.1:5000/api/files >nul 2>&1
    if !errorlevel! equ 0 (
        set "BACKEND_OK=1"
        goto :backend_ready
    )
    timeout /t 1 /nobreak >nul
)

:backend_ready
if "!BACKEND_OK!"=="0" (
    echo [LỖI] Backend không phản hồi sau 30 giây. Hủy khởi động Frontend.
    cmd /k
    exit /b
)

echo [OK] Backend đã sẵn sàng!
echo [3/3] Đang khởi động Frontend...

echo Đang kiểm tra thư viện Frontend...
start "Local Media Server Frontend" cmd /k "cd /d ""%~dp0frontend"" && npm install --no-audit --no-fund && npm run dev -- --host 0.0.0.0 --port 5173"

echo ==========================================
echo Server đã khởi động thành công!
echo Backend health:  http://127.0.0.1:5000/api/system/status
echo Frontend local:  https://localhost:5173
echo Frontend LAN:    https://!LANIP!:5173
echo ==========================================
echo Nhấn phím bất kỳ để thoát cửa sổ lệnh này...
pause >nul
