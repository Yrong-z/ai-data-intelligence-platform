$ErrorActionPreference = "Continue"
$platformRoot = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $platformRoot "runtime"
$pidFile = Join-Path $runtime "pids.json"
if (Test-Path $pidFile) { foreach ($entry in @(Get-Content $pidFile | ConvertFrom-Json)) { Stop-Process -Id ([int]$entry.pid) -Force -ErrorAction SilentlyContinue }; Remove-Item $pidFile -Force -ErrorAction SilentlyContinue }
$releaseRoot = Split-Path -Parent $platformRoot
$wshuRoot = if ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { Join-Path $releaseRoot "text2sql-data-agent" }
docker compose -p wshu_platform -f (Join-Path $wshuRoot "docker/docker-compose.yaml") down
Write-Host "Stopped platform-owned processes and wshu_platform containers."
