$ErrorActionPreference = "Stop"
$checks = @(
  @{ Name = "Qdrant"; Url = "http://127.0.0.1:6333/collections" },
  @{ Name = "Elasticsearch"; Url = "http://127.0.0.1:9200/_cluster/health" },
  @{ Name = "TEI"; Url = "http://127.0.0.1:8081/health" },
  @{ Name = "RAG API"; Url = "http://127.0.0.1:8010/openapi.json" },
  @{ Name = "Wshu API"; Url = "http://127.0.0.1:8001/openapi.json" },
  @{ Name = "Gateway"; Url = "http://127.0.0.1:9010/api/health" },
  @{ Name = "Frontend"; Url = "http://127.0.0.1:5173" }
)
foreach ($check in $checks) { try { $r = Invoke-WebRequest -UseBasicParsing -Uri $check.Url -TimeoutSec 5; Write-Host "$($check.Name): PASS ($($r.StatusCode))" } catch { Write-Error "$($check.Name): FAIL - $($_.Exception.Message)" } }
