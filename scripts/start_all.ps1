$ErrorActionPreference = "Stop"
$platformRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Split-Path -Parent $platformRoot
$zhikuRoot = if ($env:ZHIKU_ROOT) { $env:ZHIKU_ROOT } else { Join-Path $releaseRoot "rag-knowledge-agent" }
$wshuRoot = if ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { Join-Path $releaseRoot "text2sql-data-agent" }
$python = if ($env:PYTHON_EXE) { $env:PYTHON_EXE } else { "python" }
$runtime = Join-Path $platformRoot "runtime"
$logDir = Join-Path $runtime "logs"
$pidFile = Join-Path $runtime "pids.json"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
foreach ($path in @($zhikuRoot, $wshuRoot, (Join-Path $platformRoot "gateway"), (Join-Path $platformRoot "frontend"))) { if (!(Test-Path $path)) { throw "Missing release repository: $path" } }
if (!(Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker is required" }
if (!(Get-Command uv -ErrorAction SilentlyContinue)) { throw "uv is required" }
if (!(Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm is required" }
& $python (Join-Path $wshuRoot "scripts/check_embedding_model.py")
if ($LASTEXITCODE -ne 0) { throw "Wshu embedding model is incomplete; startup stopped before launching a partial stack." }
docker compose -p wshu_platform -f (Join-Path $wshuRoot "docker/docker-compose.yaml") up -d
& $python (Join-Path $wshuRoot "scripts/init_demo_retrieval.py")
if ($LASTEXITCODE -ne 0) { throw "Wshu retrieval initialization failed." }
$processes = @()
function Start-Logged([string]$name, [string]$cwd, [string]$command) {
  $log = Join-Path $logDir "$name.log"
  $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList @("-NoProfile", "-Command", "Set-Location -LiteralPath '$cwd'; $command *> '$log'")
  return @{ name = $name; pid = $p.Id; log = $log }
}
$processes += Start-Logged "rag" $zhikuRoot "$python -m uvicorn main:app --host 127.0.0.1 --port 8010"
$processes += Start-Logged "wshu" $wshuRoot "$python -m uvicorn main:app --host 127.0.0.1 --port 8001"
$gateway = Join-Path $platformRoot "gateway"
$processes += Start-Logged "gateway" $gateway "$python -m uvicorn main:app --host 127.0.0.1 --port 9010"
$frontend = Join-Path $platformRoot "frontend"
if (!(Test-Path (Join-Path $frontend "node_modules"))) { npm --prefix $frontend install }
$processes += Start-Logged "frontend" $frontend "npm run dev -- --host 127.0.0.1 --port 5173"
$processes | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Write-Host "Started platform services."
