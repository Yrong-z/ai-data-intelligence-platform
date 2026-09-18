$ErrorActionPreference = "Stop"

Write-Host "Stopping common development processes on ports 8000, 8010, 8001, 9000, 9010, and 5173..."

$ports = @(8000, 8010, 8001, 9000, 9010, 5173)
foreach ($port in $ports) {
  $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
  foreach ($connection in $connections) {
    if ($connection.OwningProcess) {
      Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
      Write-Host "Stopped process $($connection.OwningProcess) on port $port"
    }
  }
}

Write-Host "Port-based cleanup completed. Stop any remaining project processes manually if needed."
