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
docker compose -p wshu_platform -f (Join-Path $wshuRoot "docker/docker-compose.yaml") up -d
Write-Host "TEI may be downloading BAAI/bge-large-zh-v1.5 on first startup..."
$deadline = (Get-Date).AddMinutes(15)
do {
  try { $tei = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:8081/health" -TimeoutSec 5; if ($tei.StatusCode -eq 200) { break } } catch { }
  if ((Get-Date) -gt $deadline) { throw "TEI did not become healthy. Check: docker compose -p wshu_platform logs embedding" }
  Start-Sleep -Seconds 5
} while ($true)
& $python (Join-Path $wshuRoot "scripts/init_demo_retrieval.py")
if ($LASTEXITCODE -ne 0) { throw "Wshu retrieval initialization failed." }
$processes = @()
function Start-Logged([string]$name, [string]$cwd, [string]$command) {
  $log = Join-Path $logDir "$name.log"
  $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList @("-NoProfile", "-Command", "Set-Location -LiteralPath '$cwd'; $command *> '$log'")
  return @{ name = $name; pid = $p.Id; log = $log }
}
$processes += Start-Logged "rag" $zhikuRoot "uv run --project '$zhikuRoot' uvicorn main:app --host 127.0.0.1 --port 8010"
$processes += Start-Logged "wshu" $wshuRoot "uv run --project '$wshuRoot' uvicorn app.main:app --host 127.0.0.1 --port 8001"
$gateway = Join-Path $platformRoot "gateway"
$processes += Start-Logged "gateway" $gateway "uv run --project '$gateway' uvicorn main:app --host 127.0.0.1 --port 9010"
$frontend = Join-Path $platformRoot "frontend"
if (!(Test-Path (Join-Path $frontend "node_modules"))) { npm --prefix $frontend install }
$processes += Start-Logged "frontend" $frontend "npm run dev -- --host 127.0.0.1 --port 5173"
$processes | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Write-Host ""
Write-Host "========================================="
Write-Host "AI Data Intelligence Platform is ready"
Write-Host "========================================="
Write-Host "Frontend:          http://localhost:5173"
Write-Host "Gateway:           http://localhost:9010"
Write-Host "RAG API:           http://localhost:8010/docs"
Write-Host "Text-to-SQL API:   http://localhost:8001/docs"
Write-Host "Stop:              powershell -ExecutionPolicy Bypass -File scripts/stop_all.ps1"
Start-Process "http://localhost:5173"
