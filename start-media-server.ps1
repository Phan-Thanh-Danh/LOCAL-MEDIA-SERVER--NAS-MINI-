# Local Media Server Launcher
Add-Type -AssemblyName System.Windows.Forms

$basePath = $PSScriptRoot
$backendPath = Join-Path $basePath "backend\LocalMediaServer"
$frontendPath = Join-Path $basePath "frontend"

# Get LAN IP
function Get-LanIP {
    $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } | Select-Object -First 1
    if ($ip) { return $ip.IPAddress } else { return "localhost" }
}

$lanIP = Get-LanIP

# Clear screen
Clear-Host

# Print header
Write-Host @"

╔════════════════════════════════════════╗
║   Local Media Server - NAS Mini         ║
║   Browser: Video + Image Viewer         ║
╚════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "[1/2] Starting Backend (ASP.NET Core)..." -ForegroundColor Yellow
Write-Host ""

# Start backend
Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/k cd /d `"$backendPath`" && dotnet run --no-build --urls http://0.0.0.0:5000"

Start-Sleep -Seconds 3
Write-Host "✓ Backend started`n" -ForegroundColor Green

Write-Host "[2/2] Starting Frontend (Vue.js + Vite)..." -ForegroundColor Yellow
Write-Host ""

# Start frontend
Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/k cd /d `"$frontendPath`" && npm run dev -- --host 0.0.0.0 --port 5173"

Start-Sleep -Seconds 5
Write-Host "✓ Frontend started`n" -ForegroundColor Green

# Open browser
Write-Host "Opening browser..." -ForegroundColor Cyan
Write-Host ""

Start-Process "https://127.0.0.1:5173"

# Print info
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host "   Local Media Server Started!" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Host "Local Access:  https://127.0.0.1:5173" -ForegroundColor Cyan
Write-Host "LAN Access:    https://$lanIP:5173" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API:   http://127.0.0.1:5000" -ForegroundColor Cyan
Write-Host ""

Write-Host "Close this window to stop the services." -ForegroundColor Yellow
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Keep the window open
Read-Host "Press Enter to exit"
