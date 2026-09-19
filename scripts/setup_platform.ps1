$ErrorActionPreference = "Stop"

$platformRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Split-Path -Parent $platformRoot
. (Join-Path $PSScriptRoot "release_config.ps1")

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

function Resolve-ConfiguredPath([string]$configured, [string]$fallback) {
  $value = if ($configured) { $configured } else { $fallback }
  if (![IO.Path]::IsPathRooted($value)) { $value = Join-Path $platformRoot $value }
  return [IO.Path]::GetFullPath($value)
}

function Invoke-Git([string]$workingDirectory, [string[]]$arguments, [string]$failureMessage) {
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = @(& git -C $workingDirectory @arguments 2>&1)
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorAction
  }
  if ($exitCode -ne 0) {
    $details = ($output -join [Environment]::NewLine).Trim()
    if ($details) { throw "$failureMessage`n$details" }
    throw $failureMessage
  }
  return $output
}

function Ensure-Backend([hashtable]$definition, [string]$path) {
  $name = $definition.Name
  $version = $definition.Version
  $repoUrl = $definition.RepoUrl
  $wasCloned = $false

  if (!(Test-Path -LiteralPath $path)) {
    if ($repoUrl -match "__GITHUB_USERNAME__") {
      throw "[$name] 后端目录不存在，但发布配置仍使用占位符。请先编辑 scripts/release_config.ps1，填写真实 GitHub 用户名。`n仓库：$repoUrl`n版本：$version"
    }
    Write-Host "[$name] backend missing; cloning fixed release $version..."
    $parent = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $cloneOutput = @(& git clone $repoUrl $path 2>&1)
    if ($LASTEXITCODE -ne 0) {
      $details = ($cloneOutput -join [Environment]::NewLine).Trim()
      throw "[$name] 下载失败`n仓库：$repoUrl`n版本：$version`n请检查：`n1. 网络连接`n2. GitHub 是否可访问`n3. 仓库地址和版本是否正确`n修复后重新运行 SETUP_PLATFORM.bat。`n$details"
    }
    $wasCloned = $true
  } else {
    Write-Host "[$name] backend found: $path"
  }

  if (!(Test-Path -LiteralPath (Join-Path $path ".git"))) {
    throw "[$name] 后端目录存在但不是 Git 仓库：$path"
  }
  Invoke-Git $path @("rev-parse", "--is-inside-work-tree") "[$name] Git 仓库检查失败：$path" | Out-Null

  $dirty = @(Invoke-Git $path @("status", "--porcelain", "--untracked-files=all") "[$name] 无法读取工作区状态：$path")
  $currentTags = @(Invoke-Git $path @("tag", "--points-at", "HEAD") "[$name] 无法读取当前版本：$path")
  $isExpectedVersion = $currentTags -contains $version
  if ($isExpectedVersion) {
    Write-Host "[$name] version OK: $version"
    return
  }

  $currentVersion = if ($currentTags.Count -gt 0) { $currentTags -join ", " } else { "未标记版本" }
  Write-Host "[$name] 当前版本：$currentVersion；期望版本：$version"
  if ($dirty.Count -gt 0) {
    throw "[$name] 工作区存在用户修改，已停止自动切换版本。请先处理以下修改后重新运行 SETUP_PLATFORM.bat：`n$($dirty -join [Environment]::NewLine)"
  }

  $tagCheck = @(& git -C $path rev-parse --verify --quiet ("refs/tags/{0}" -f $version) 2>$null)
  if ($LASTEXITCODE -ne 0) {
    $remoteCheck = @(& git -C $path remote get-url origin 2>$null)
    if ($LASTEXITCODE -ne 0 -or !$remoteCheck) {
      throw "[$name] 找不到固定版本 $version，且仓库没有 origin remote。请检查仓库来源或在本地准备该 tag。"
    }
    Write-Host "[$name] fetching tags..."
    Invoke-Git $path @("fetch", "--tags", "origin") "[$name] 获取版本标签失败。仓库：$repoUrl；版本：$version" | Out-Null
    $tagCheck = @(& git -C $path rev-parse --verify --quiet ("refs/tags/{0}" -f $version) 2>$null)
    if ($LASTEXITCODE -ne 0) {
      throw "[$name] 仓库中不存在期望版本 $version。仓库：$repoUrl"
    }
  }

  Write-Host "[$name] switching to fixed release $version..."
  Invoke-Git $path @("checkout", "--detach", $version) "[$name] 切换到固定版本失败：$version" | Out-Null
  if ($wasCloned) { Write-Host "[$name] cloned and checked out: $version" }
}

Import-DotEnv (Join-Path $platformRoot ".env")

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "未检测到 Git。" -ForegroundColor Red
  Write-Host "请先安装 Git for Windows："
  Write-Host "https://git-scm.com/"
  Write-Host "安装完成后重新运行 SETUP_PLATFORM.bat。"
  exit 1
}
if (!(Get-Command uv -ErrorAction SilentlyContinue)) { throw "未检测到 uv。请先安装 uv 后重新运行 SETUP_PLATFORM.bat。" }
if (!(Get-Command npm -ErrorAction SilentlyContinue)) { throw "未检测到 Node.js/npm。请先安装 Node.js 后重新运行 SETUP_PLATFORM.bat。" }
if (!(Get-Command docker -ErrorAction SilentlyContinue)) { throw "未检测到 Docker。请先安装并启动 Docker Desktop 后重新运行 SETUP_PLATFORM.bat。" }

$ragConfiguredPath = if ($env:RAG_REPO_DIR) { $env:RAG_REPO_DIR } elseif ($env:ZHIKU_ROOT) { $env:ZHIKU_ROOT } else { $null }
$wshuConfiguredPath = if ($env:WSHU_REPO_DIR) { $env:WSHU_REPO_DIR } elseif ($env:WSHU_ROOT) { $env:WSHU_ROOT } else { $null }
$ragRoot = Resolve-ConfiguredPath $ragConfiguredPath (Join-Path $releaseRoot "rag-knowledge-agent")
$wshuRoot = Resolve-ConfiguredPath $wshuConfiguredPath (Join-Path $releaseRoot "text2sql-data-agent")
$gatewayRoot = Join-Path $platformRoot "gateway"
$frontendRoot = Join-Path $platformRoot "frontend"
foreach ($path in @($gatewayRoot, $frontendRoot)) { if (!(Test-Path -LiteralPath $path)) { throw "Missing platform component: $path" } }

Ensure-Backend $PlatformReleaseConfig.RAG $ragRoot
Ensure-Backend $PlatformReleaseConfig.T2S $wshuRoot

Write-Host "[1/5] Syncing rag-knowledge-agent..."
uv sync --project $ragRoot
Write-Host "[2/5] Syncing text2sql-data-agent..."
uv sync --project $wshuRoot
Write-Host "[3/5] Syncing gateway..."
uv sync --project $gatewayRoot
Write-Host "[4/5] Installing frontend dependencies..."
if (Test-Path (Join-Path $frontendRoot "package-lock.json")) { npm --prefix $frontendRoot ci } else { npm --prefix $frontendRoot install }
Write-Host "[5/5] Pulling Docker images..."
$ragCompose = Join-Path $ragRoot "docker-compose.milvus.yml"
$wshuCompose = Join-Path $wshuRoot "docker/docker-compose.yaml"
if (Test-Path $ragCompose) { docker compose -p rag_platform -f $ragCompose pull }
if (Test-Path $wshuCompose) { docker compose -p wshu_platform -f $wshuCompose pull }
Write-Host ""
Write-Host "SETUP COMPLETE"
Write-Host "RAG release: $($PlatformReleaseConfig.RAG.Version)"
Write-Host "T2S release: $($PlatformReleaseConfig.T2S.Version)"
Write-Host "Run START_PLATFORM.bat to start the platform."
