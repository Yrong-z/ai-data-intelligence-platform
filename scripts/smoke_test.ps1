$ErrorActionPreference = "Stop"
$gateway = "http://127.0.0.1:9010"
if ((Invoke-WebRequest -UseBasicParsing "$gateway/api/health" -TimeoutSec 5).StatusCode -ne 200) { throw "Gateway health failed" }
foreach ($q in @("统计所有地区的销售总额", "统计浙江省的销售总额", "统计2025年华东地区的订单数量")) { $body = @{ query = $q } | ConvertTo-Json; $response = Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$gateway/api/data/query" -ContentType "application/json" -Body $body -TimeoutSec 120; if ($response.StatusCode -ne 200 -or !$response.Content) { throw "Text-to-SQL smoke failed: $q" }; Write-Host "Text-to-SQL PASS: $q" }
Write-Host "Gateway-routed smoke test completed."
