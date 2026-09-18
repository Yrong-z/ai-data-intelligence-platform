$ErrorActionPreference = "Stop"

Write-Host "Starting AI-BI development services..."

$platformRoot = Split-Path -Parent $PSScriptRoot
$zhikuRoot = if ($env:ZHIKU_ROOT) { $env:ZHIKU_ROOT } else { Join-Path (Split-Path $platformRoot -Parent) "ZhiKu" }
$wshuRoot = if ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { Join-Path (Split-Path $platformRoot -Parent) "Wshu-GitHub-Release" }
$python = if ($env:PYTHON_EXE) { $env:PYTHON_EXE } else { "python" }

Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoExit", "-Command", "cd '$zhikuRoot'; & '$python' -m uvicorn main:app --reload --host 127.0.0.1 --port 8010"
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoExit", "-Command", "cd '$wshuRoot'; & '$python' -m uvicorn main:app --reload --host 127.0.0.1 --port 8001"
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoExit", "-Command", "cd '$platformRoot\gateway'; `$env:ZHIKU_BASE_URL='http://127.0.0.1:8010'; `$env:WSHU_BASE_URL='http://127.0.0.1:8001'; & '$python' -m uvicorn main:app --reload --host 127.0.0.1 --port 9010"
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoExit", "-Command", "cd '$platformRoot\frontend'; if (!(Test-Path node_modules)) { npm install }; npm run dev"

Write-Host "Started. Run scripts\check_services.ps1 to verify."
