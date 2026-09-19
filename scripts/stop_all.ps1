$ErrorActionPreference = "Continue"
$platformRoot = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $platformRoot "runtime"
$pidFile = Join-Path $runtime "pids.json"

function Test-PlatformTree([int]$processId) {
  $root = $platformRoot.Replace('/', '\\').TrimEnd('\\')
  $all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
  $queue = [System.Collections.Generic.Queue[int]]::new()
  $queue.Enqueue($processId)
  while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    $process = $all | Where-Object { $_.ProcessId -eq $current } | Select-Object -First 1
    if (-not $process) { continue }
    $commandLine = [string]$process.CommandLine
    if ($commandLine.IndexOf($root, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    foreach ($child in ($all | Where-Object { $_.ParentProcessId -eq $current })) { $queue.Enqueue([int]$child.ProcessId) }
  }
  return $false
}

if (Test-Path $pidFile) {
  $entries = @(Get-Content $pidFile -Raw | ConvertFrom-Json)
  foreach ($entry in $entries) {
    foreach ($processId in @($entry.pid)) {
      $pidValue = 0
      if (-not [int]::TryParse([string]$processId, [ref]$pidValue)) { continue }
      if (-not (Test-PlatformTree $pidValue)) {
        Write-Host "[stop] Skip PID ${pidValue}: command line is not confirmed as platform-owned."
        continue
      }
      # Start-Logged creates a PowerShell wrapper which owns the uvicorn/Vite child.
      # taskkill /T is used only after validating the wrapper command line above.
      & taskkill.exe /PID $pidValue /T /F | Out-Host
    }
  }
}
$releaseRoot = Split-Path -Parent $platformRoot
$wshuRoot = if ($env:WSHU_REPO_DIR) { $env:WSHU_REPO_DIR } elseif ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { Join-Path $releaseRoot "text2sql-data-agent" }
$ragRoot = if ($env:RAG_REPO_DIR) { $env:RAG_REPO_DIR } elseif ($env:ZHIKU_ROOT) { $env:ZHIKU_ROOT } else { Join-Path $releaseRoot 'rag-knowledge-agent' }
if (Test-Path (Join-Path $ragRoot 'docker-compose.milvus.yml')) { docker compose -p rag_platform -f (Join-Path $ragRoot 'docker-compose.milvus.yml') down }
docker compose -p wshu_platform -f (Join-Path $wshuRoot 'docker/docker-compose.yaml') down

# Fallback for stale/corrupt pids.json: stop listeners owned by this platform.
$root = $platformRoot.Replace('/', '\').TrimEnd('\')
$listenerPids = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
  Where-Object { $_.LocalPort -in @(5173, 8001, 8010, 9010) } |
  Select-Object -ExpandProperty OwningProcess -Unique)
foreach ($listenerPid in $listenerPids) {
  $process = Get-CimInstance Win32_Process -Filter "ProcessId = $listenerPid" -ErrorAction SilentlyContinue
  $commandLine = [string]$process.CommandLine
  if ($commandLine.IndexOf($root, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or $commandLine -match 'uvicorn|vite') {
    & taskkill.exe /PID $listenerPid /T /F | Out-Host
  } else {
    Write-Warning "Port listener PID $listenerPid was not identified as platform-owned; it was not killed."
  }
}

$deadline = (Get-Date).AddSeconds(10)
do {
  $remaining = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -in @(5173, 8001, 8010, 9010) })
  if ($remaining.Count -eq 0) {
    if (Test-Path $pidFile) { Remove-Item $pidFile -Force -ErrorAction SilentlyContinue }
    Write-Host "Stopped platform-owned processes and wshu_platform containers. Ports released."
    exit 0
  }
  Start-Sleep -Milliseconds 500
} while ((Get-Date) -lt $deadline)

$details = ($remaining | ForEach-Object { "port=$($_.LocalPort) pid=$($_.OwningProcess)" }) -join '; '
Write-Error "Platform stop incomplete; listeners remain: $details. pids.json was preserved for recovery."
exit 1
