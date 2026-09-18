$ErrorActionPreference = "Continue"

$targets = @(
  @{ Name = "ZhiKu"; Url = "http://127.0.0.1:8010/docs" },
  @{ Name = "Wshu"; Url = "http://127.0.0.1:8001/docs" },
  @{ Name = "Gateway"; Url = "http://127.0.0.1:9010/api/health" },
  @{ Name = "Frontend"; Url = "http://127.0.0.1:5173" }
)

foreach ($target in $targets) {
  try {
    $response = Invoke-WebRequest -Uri $target.Url -UseBasicParsing -TimeoutSec 5
    Write-Host "$($target.Name): OK ($($response.StatusCode))"
  } catch {
    Write-Host "$($target.Name): unavailable - $($_.Exception.Message)"
  }
}
