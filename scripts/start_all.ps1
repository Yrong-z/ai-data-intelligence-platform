$ErrorActionPreference = "Stop"
# Docker Compose writes harmless deprecation warnings to stderr; do not turn
# those warnings into terminating PowerShell errors during readiness polling.
$PSNativeCommandUseErrorActionPreference = $false
$platformRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Split-Path -Parent $platformRoot

function Import-DotEnv([string]$path) {
  if (!(Test-Path -LiteralPath $path)) { return }
  foreach ($line in Get-Content -LiteralPath $path) {
    $text = $line.Trim()
    if (!$text -or $text.StartsWith("#")) { continue }
    $parts = $text -split "=", 2
    if ($parts.Count -ne 2) { continue }
    $name = $parts[0].Trim()
    if ($name -notmatch "^[A-Za-z_][A-Za-z0-9_]*$") { continue }
    $value = $parts[1].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
  }
}

Import-DotEnv (Join-Path $platformRoot ".env")
$env:PLATFORM_ENV_FILE = Join-Path $platformRoot ".env"

$ragMode = if ($env:RAG_MODE) { $env:RAG_MODE.Trim().ToLower() } else { "demo" }
if ($ragMode -notin @("demo", "real")) { throw "RAG_MODE must be demo or real" }
$env:RAG_MODE = $ragMode
if ($ragMode -eq "real") {
  $env:LLM_MODE = "real"
  $env:IMPORT_MODE = "real"
  $env:MOCK_SEARCH_EMBEDDING = "false"
} else {
  $env:LLM_MODE = "mock"
  $env:IMPORT_MODE = "mock"
  $env:MOCK_SEARCH_EMBEDDING = "true"
}
$zhikuRoot = if ($env:RAG_REPO_DIR) { $env:RAG_REPO_DIR } elseif ($env:ZHIKU_ROOT) { $env:ZHIKU_ROOT } else { Join-Path $releaseRoot "rag-knowledge-agent" }
$wshuRoot = if ($env:WSHU_REPO_DIR) { $env:WSHU_REPO_DIR } elseif ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { Join-Path $releaseRoot "text2sql-data-agent" }
if (![IO.Path]::IsPathRooted($zhikuRoot)) { $zhikuRoot = Join-Path $platformRoot $zhikuRoot }
if (![IO.Path]::IsPathRooted($wshuRoot)) { $wshuRoot = Join-Path $platformRoot $wshuRoot }
$zhikuRoot = [IO.Path]::GetFullPath($zhikuRoot)
$wshuRoot = [IO.Path]::GetFullPath($wshuRoot)

$env:ZHIKU_BASE_URL = if ($env:ZHIKU_BASE_URL) { $env:ZHIKU_BASE_URL } else { "http://127.0.0.1:8010" }
$env:WSHU_BASE_URL = if ($env:WSHU_BASE_URL) { $env:WSHU_BASE_URL } else { "http://127.0.0.1:8001" }
$env:VITE_GATEWAY_BASE_URL = if ($env:VITE_GATEWAY_BASE_URL) { $env:VITE_GATEWAY_BASE_URL } else { "http://127.0.0.1:9010" }
$env:MILVUS_URL = if ($env:MILVUS_URL) { $env:MILVUS_URL } else { "http://127.0.0.1:19530" }
$env:LLM_MODEL = if ($env:LLM_MODEL) { $env:LLM_MODEL } else { "deepseek-v4-flash" }
$env:LLM_BASE_URL = if ($env:LLM_BASE_URL) { $env:LLM_BASE_URL } else { "https://api.deepseek.com" }
$env:LLM_API_KEY = if ($null -ne $env:LLM_API_KEY) { $env:LLM_API_KEY } else { "" }
$env:MINERU_API_TOKEN = if ($null -ne $env:MINERU_API_TOKEN) { $env:MINERU_API_TOKEN } else { "" }
$env:OPENAI_API_KEY = $env:LLM_API_KEY
$env:OPENAI_API_BASE = $env:LLM_BASE_URL
$env:LLM_DEFAULT_MODEL = $env:LLM_MODEL
$runtime = Join-Path $platformRoot "runtime"
$logDir = Join-Path $runtime "logs"
$pidFile = Join-Path $runtime "pids.json"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Assert-PortsFree {
  $conflicts = @()
  foreach ($port in @(5173, 8001, 8010, 9010)) {
    $listeners = @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue)
    foreach ($listener in $listeners) {
      $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
      $conflicts += "port=$port pid=$($listener.OwningProcess) process=$($process.ProcessName)"
    }
  }
  if ($conflicts.Count -gt 0) {
    throw "Platform ports are already in use: $($conflicts -join '; '). Run STOP_PLATFORM.bat or stop the named process, then retry."
  }
}

Assert-PortsFree
foreach ($path in @($zhikuRoot, $wshuRoot, (Join-Path $platformRoot "gateway"), (Join-Path $platformRoot "frontend"))) { if (!(Test-Path $path)) { throw "Missing release repository: $path" } }
if (!(Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker is required" }
$dockerErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$dockerInfo = & docker info 2>&1
$dockerExitCode = $LASTEXITCODE
$ErrorActionPreference = $dockerErrorAction
if ($dockerExitCode -ne 0) {
  $dockerMessage = "Docker " + [char]0x5DF2 + [char]0x5B89 + [char]0x88C5 + [char]0xFF0C + "Docker Desktop / Docker Engine " + [char]0x672A + [char]0x542F + [char]0x52A8 + [char]0xFF0C + [char]0x8BF7 + [char]0x542F + [char]0x52A8 + [char]0x540E + [char]0x91CD + [char]0x8BD5 + [char]0x3002
  throw $dockerMessage
}
$gateway = Join-Path $platformRoot "gateway"
$frontend = Join-Path $platformRoot "frontend"
$ragPython = Join-Path $zhikuRoot ".venv/Scripts/python.exe"
$wshuPython = Join-Path $wshuRoot ".venv/Scripts/python.exe"
$gatewayPython = Join-Path $gateway ".venv/Scripts/python.exe"
foreach ($path in @($ragPython, $wshuPython, $gatewayPython)) { if (!(Test-Path $path)) { throw "Missing Python environment: $path. Run SETUP_PLATFORM.bat first." } }
if (!(Test-Path (Join-Path $frontend "node_modules"))) { throw "Missing frontend/node_modules. Run SETUP_PLATFORM.bat first." }
 $ragCompose = Join-Path $zhikuRoot "docker-compose.milvus.yml"
if ($ragMode -eq "real") {
  if (!(Test-Path $ragCompose)) { throw "Missing Milvus compose file: $ragCompose" }
  Write-Host "[RAG] Starting platform Milvus..."
  docker compose -p rag_platform -f $ragCompose up -d
}
$processes = @()
function Start-Logged([string]$name, [string]$cwd, [string]$command) {
  $log = Join-Path $logDir "$name.log"
  if (Test-Path -LiteralPath $log) {
    Copy-Item -LiteralPath $log -Destination "$log.$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').bak"
  }
  $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList @("-NoProfile", "-Command", "Set-Location -LiteralPath '$cwd'; $command *> '$log'")
  # Keep the wrapper: its command line includes the platform log path and
  # STOP can terminate its entire child tree, including uv's Python process.
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
function Wait-Ready([string]$name, [string]$url, [int]$timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  $lastBody = "unreachable"
  do {
    try {
      $response = Invoke-WebRequest -UseBasicParsing $url -TimeoutSec 5
      $body = $response.Content | ConvertFrom-Json
      $lastBody = $response.Content
      if ($response.StatusCode -eq 200 -and $body.status -in @("ready", "ok")) { Write-Host "[$name] Ready"; return }
    } catch { }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  throw "$name did not become ready: $url; last state: $lastBody; check .env and runtime/logs/$($name.ToLower()).log"
}
function Wait-ComposeHealth([string]$name, [string]$project, [string]$composeFile, [string]$service, [int]$timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  do {
    $composeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $containerId = docker compose -p $project -f $composeFile ps -q $service 2>$null | Select-Object -First 1
    $ErrorActionPreference = $composeErrorAction
    if ($containerId) {
      $status = docker inspect --format "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}" $containerId 2>$null
      if ($status -eq "healthy") { Write-Host "[$name] Healthy"; return }
      if ($status -in @("exited", "dead")) { throw "$name exited before becoming healthy." }
    }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  throw "$name did not become healthy within $timeoutSeconds seconds."
}
function Wait-Tcp([string]$name, [string]$hostName, [int]$port, [int]$timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  do {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
      $connect = $client.BeginConnect($hostName, $port, $null, $null)
      if ($connect.AsyncWaitHandle.WaitOne(1000) -and $client.Connected) {
        $client.EndConnect($connect)
        Write-Host "[$name] Ready"
        return
      }
    } catch { } finally { $client.Dispose() }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  throw "$name did not accept TCP connections on ${hostName}:$port"
}
if ($ragMode -eq "real") {
  Wait-ComposeHealth "Milvus etcd" "rag_platform" $ragCompose "etcd" 180
  Wait-ComposeHealth "Milvus MinIO" "rag_platform" $ragCompose "minio" 180
  Wait-ComposeHealth "Milvus standalone" "rag_platform" $ragCompose "standalone" 300
  Wait-Http "Milvus HTTP" "http://127.0.0.1:9091/healthz" 60
  Wait-Tcp "Milvus TCP" "127.0.0.1" 19530 60
}
Start-Logged "rag" $zhikuRoot "& '$ragPython' -m uvicorn main:app --host 127.0.0.1 --port 8010"
$gateway = Join-Path $platformRoot "gateway"
Start-Logged "gateway" $gateway "& '$gatewayPython' -m uvicorn main:app --host 127.0.0.1 --port 9010"
$frontend = Join-Path $platformRoot "frontend"
Start-Logged "frontend" $frontend "npm run dev -- --host 127.0.0.1 --port 5173"
$processes | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Wait-Ready "RAG" "http://127.0.0.1:8010/health/ready" 120
Wait-Http "Frontend" "http://127.0.0.1:5173" 120
Write-Host ""
Write-Host "Frontend: http://localhost:5173"
Write-Host "Gateway:  http://localhost:9010"
Write-Host "RAG API:  http://localhost:8010/docs"
Write-Host "[Wshu] TEI initializing/downloading model..."
Write-Host "[Wshu] Text-to-SQL is not ready yet."
docker compose -p wshu_platform -f (Join-Path $wshuRoot "docker/docker-compose.yaml") up -d
Wait-Http "TEI" "http://127.0.0.1:8081/health" 900
& $wshuPython (Join-Path $wshuRoot "scripts/init_demo_retrieval.py")
if ($LASTEXITCODE -ne 0) { throw "Wshu retrieval initialization failed." }
Start-Logged "wshu" $wshuRoot "& '$wshuPython' -m uvicorn app.main:app --host 127.0.0.1 --port 8001"
$processes | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Wait-Ready "Wshu" "http://127.0.0.1:8001/health/ready" 120
Wait-Ready "Gateway" "http://127.0.0.1:9010/api/health" 120
try {
  Start-Process -FilePath "http://localhost:5173" -ErrorAction Stop | Out-Null
  Write-Host "[Frontend] Browser opened: http://localhost:5173"
} catch {
  Write-Warning "[Frontend] Could not open the browser automatically: $($_.Exception.Message)"
}
Write-Host "[Wshu] Ready"
Write-Host "Text-to-SQL API: http://localhost:8001/docs"
