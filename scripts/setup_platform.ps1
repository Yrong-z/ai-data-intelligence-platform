$ErrorActionPreference = "Stop"
$platformRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Split-Path -Parent $platformRoot
$zhikuRoot = if ($env:RAG_REPO_DIR) { $env:RAG_REPO_DIR } else { Join-Path $releaseRoot "rag-knowledge-agent" }
$wshuRoot = if ($env:WSHU_REPO_DIR) { $env:WSHU_REPO_DIR } else { Join-Path $releaseRoot "text2sql-data-agent" }
$gatewayRoot = Join-Path $platformRoot "gateway"
$frontendRoot = Join-Path $platformRoot "frontend"
foreach ($path in @($zhikuRoot, $wshuRoot, $gatewayRoot, $frontendRoot)) { if (!(Test-Path $path)) { throw "Missing repository: $path" } }
if (!(Get-Command uv -ErrorAction SilentlyContinue)) { throw "uv is required" }
if (!(Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm is required" }
if (!(Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker is required" }
Write-Host "[1/5] Syncing rag-knowledge-agent..."
uv sync --project $zhikuRoot
Write-Host "[2/5] Syncing text2sql-data-agent..."
uv sync --project $wshuRoot
Write-Host "[3/5] Syncing gateway..."
uv sync --project $gatewayRoot
Write-Host "[4/5] Installing frontend dependencies..."
if (Test-Path (Join-Path $frontendRoot "package-lock.json")) { npm --prefix $frontendRoot ci } else { npm --prefix $frontendRoot install }
Write-Host "[5/5] Pulling Docker images..."
$ragCompose = Join-Path $zhikuRoot "docker-compose.milvus.yml"
$wshuCompose = Join-Path $wshuRoot "docker/docker-compose.yaml"
if (Test-Path $ragCompose) { docker compose -p rag_platform -f $ragCompose pull }
if (Test-Path $wshuCompose) { docker compose -p wshu_platform -f $wshuCompose pull }
Write-Host ""
Write-Host "SETUP COMPLETE"
Write-Host "Run START_PLATFORM.bat to start the platform."
