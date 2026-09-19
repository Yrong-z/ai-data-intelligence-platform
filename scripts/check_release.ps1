$ErrorActionPreference = "Stop"
$platformRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Split-Path -Parent $platformRoot
$blocked = @(".env", "runtime/logs", "runtime/pids.json", ".playwright-cli")
$found = @()
foreach ($relative in $blocked) {
  $path = Join-Path $platformRoot $relative
  if (Test-Path -LiteralPath $path) { $found += $relative }
}
$files = Get-ChildItem -LiteralPath $releaseRoot -Recurse -Force -File |
  Where-Object { $_.FullName -notmatch '\\(node_modules|\.venv|\.git)\\' }
$secretHits = @($files | Select-String -Pattern 'sk-[A-Za-z0-9]{20,}')
if ($found.Count -or $secretHits.Count) {
  if ($found.Count) { Write-Error "Release blockers present: $($found -join ', ')" }
  if ($secretHits.Count) { Write-Error "Secret-like token found outside placeholders." }
  exit 1
}
Write-Host "Release package check passed: no .env, runtime state, or secret-like token."
