Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedContractHash = "0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67"

$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Portfolio.mq5") -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "D1 momentum-cap source identity changed." }
$contractHash = (Get-FileHash -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_CONTRACT.md") -Algorithm SHA256).Hash
if($contractHash -ne $expectedContractHash) { throw "D1 momentum-cap contract identity changed." }

$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_QUEUE.csv"))
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_RESULTS.csv"))
$runs = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_RUN.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_DECISION.csv"))
if($queue.Count -ne 35 -or $results.Count -ne 35 -or $runs.Count -ne 35 -or $decision.Count -ne 5) {
   throw "Unexpected artifact row count."
}
if(@($queue | Where-Object To -gt "2020.12.31").Count -gt 0) { throw "Post-2020 data leaked into discovery." }
if(@($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Unparsed result present." }
if(@($runs | Where-Object Status -ne "REPORT_FOUND").Count -gt 0) { throw "Identity-invalid runner evidence is canonical." }
$center = @($decision | Where-Object Candidate -eq "rdmc_di10_cap12_center")[0]
if($center.AnnualGatePass -ne "True" -or $center.QualityGatePass -ne "True" -or
   $center.ParentComparisonPass -ne "True" -or $center.AdjacentSupportPass -ne "True") {
   throw "Center does not satisfy every frozen discovery gate."
}
if($center.Decision -ne "OPEN_HOLDOUT") { throw "Passing center did not open holdout." }
if(@($decision | Where-Object Decision -eq "OPEN_HOLDOUT").Count -ne 1) { throw "Exactly one profile must open holdout." }
foreach($year in 2015..2020) {
   $property = "Net$year"
   if([double]$center.$property -le 0.0) { throw "Center annual result is not positive for $year." }
}
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked after testing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden-desktop acknowledgement leaked after testing." }

Write-Output "PASS: D1 momentum-cap discovery opens holdout only for the exact preregistered center."
