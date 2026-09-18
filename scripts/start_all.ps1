$ErrorActionPreference = "Stop"
$platformRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Split-Path -Parent $platformRoot
$zhikuRoot = if ($env:RAG_REPO_DIR) { $env:RAG_REPO_DIR } elseif ($env:ZHIKU_ROOT) { $env:ZHIKU_ROOT } else { Join-Path $releaseRoot "rag-knowledge-agent" }
$wshuRoot = if ($env:WSHU_REPO_DIR) { $env:WSHU_REPO_DIR } elseif ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { Join-Path $releaseRoot "text2sql-data-agent" }
$python = if ($env:PYTHON_EXE) { $env:PYTHON_EXE } else { "python" }
$runtime = Join-Path $platformRoot "runtime"
$logDir = Join-Path $runtime "logs"
$pidFile = Join-Path $runtime "pids.json"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
foreach ($path in @($zhikuRoot, $wshuRoot, (Join-Path $platformRoot "gateway"), (Join-Path $platformRoot "frontend"))) { if (!(Test-Path $path)) { throw "Missing release repository: $path" } }
if (!(Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker is required" }
if (!(Get-Command uv -ErrorAction SilentlyContinue)) { throw "uv is required" }
if (!(Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm is required" }
$processes = @()
function Start-Logged([string]$name, [string]$cwd, [string]$command) {
  $log = Join-Path $logDir "$name.log"
  $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList @("-NoProfile", "-Command", "Set-Location -LiteralPath '$cwd'; $command *> '$log'")
  $script:processes += @{ name = $name; pid = $p.Id; log = $log }
}
function Wait-Http([string]$name, [string]$url, [int]$timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  do {
    try { $response = Invoke-WebRequest -UseBasicParsing $url -TimeoutSec 3; if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) { Write-Host "[$name] Ready"; return } } catch { }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  throw "$name did not become ready: $url"
}
Start-Logged "rag" $zhikuRoot "uv run --project '$zhikuRoot' uvicorn main:app --host 127.0.0.1 --port 8010"
$gateway = Join-Path $platformRoot "gateway"
Start-Logged "gateway" $gateway "uv run --project '$gateway' uvicorn main:app --host 127.0.0.1 --port 9010"
$frontend = Join-Path $platformRoot "frontend"
if (!(Test-Path (Join-Path $frontend "node_modules"))) { npm --prefix $frontend install }
Start-Logged "frontend" $frontend "npm run dev -- --host 127.0.0.1 --port 5173"
$processes | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Wait-Http "RAG" "http://127.0.0.1:8010/openapi.json" 120
Wait-Http "Gateway" "http://127.0.0.1:9010/api/health" 120
Wait-Http "Frontend" "http://127.0.0.1:5173" 120
Write-Host ""
Write-Host "Frontend: http://localhost:5173"
Write-Host "Gateway:  http://localhost:9010"
Write-Host "RAG API:  http://localhost:8010/docs"
Start-Process "http://localhost:5173"
Write-Host "[Wshu] TEI initializing/downloading model..."
Write-Host "[Wshu] Text-to-SQL is not ready yet."
docker compose -p wshu_platform -f (Join-Path $wshuRoot "docker/docker-compose.yaml") up -d
Wait-Http "TEI" "http://127.0.0.1:8081/health" 900
& $python (Join-Path $wshuRoot "scripts/init_demo_retrieval.py")
if ($LASTEXITCODE -ne 0) { throw "Wshu retrieval initialization failed." }
Start-Logged "wshu" $wshuRoot "uv run --project '$wshuRoot' uvicorn app.main:app --host 127.0.0.1 --port 8001"
$processes | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Wait-Http "Wshu" "http://127.0.0.1:8001/openapi.json" 120
Write-Host "[Wshu] Ready"
Write-Host "Text-to-SQL API: http://localhost:8001/docs"
