$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$result = & (Join-Path $PSScriptRoot "build_momentum_breakout_quality_discovery_package.ps1")
$queue = @(Import-Csv (Join-Path $repo "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_QUEUE.csv"))
$manifest = @(Import-Csv (Join-Path $repo "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_MANIFEST.csv"))
if($result.Status -ne "READY" -or $queue.Count -ne 21 -or $manifest.Count -ne 21) { throw "Package row count changed." }
if(@($queue.Candidate | Sort-Object -Unique).Count -ne 7 -or @($queue.Window | Sort-Object -Unique).Count -ne 3) { throw "Profile/window matrix changed." }
if(@($queue | Where-Object {[datetime]::ParseExact($_.To,'yyyy.MM.dd',$null).Year -gt 2020}).Count -ne 0) { throw "Discovery opened post-2020 data." }
$sourceHash = (Get-FileHash (Join-Path $PSScriptRoot "Professional_XAUUSD_Momentum_Breakout_Quality_Portfolio.mq5") -Algorithm SHA256).Hash
$contractHash = (Get-FileHash (Join-Path $repo "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_CONTRACT.md") -Algorithm SHA256).Hash
foreach($row in $queue) {
   if($row.SourceSha256 -ne $sourceHash -or $row.ContractSha256 -ne $contractHash -or $row.Model -ne "1" -or $row.Deposit -ne "10000") { throw "Frozen identity or tester setting changed." }
   $profile = Get-Content (Join-Path $repo "outputs\momentum_breakout_quality_discovery_model1_package\$($row.ProfileSnapshot)") -Raw
   foreach($required in @('InpRVRiskPercent=0.45','InpMORiskPercent=0.15','InpMaximumPortfolioOpenRiskPercent=0.75','InpAllowRealAccountTrading=false','InpLogTrades=false')) {
      if($profile.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { throw "Profile safety field changed: $required" }
   }
}
"MOMENTUM_BREAKOUT_QUALITY_PACKAGE_TEST_PASS reports=21 source=$sourceHash"
