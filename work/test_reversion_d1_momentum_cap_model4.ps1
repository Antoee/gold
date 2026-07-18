Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_RESULTS.csv"))
$runs = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_RUN.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_DECISION.csv"))
if($results.Count -ne 15 -or $runs.Count -ne 15 -or $decision.Count -ne 3) { throw "Unexpected Model4 artifact count." }
if(@($runs | Where-Object Status -ne "REPORT_FOUND").Count -gt 0) { throw "Identity-invalid Model4 runner evidence is canonical." }
$center = @($decision | Where-Object Candidate -eq "rdmc_di10_cap12_center")[0]
$neighbor = @($decision | Where-Object Candidate -eq "rdmc_di10_cap14")[0]
$parent = @($decision | Where-Object Candidate -eq "rdmc_di10_parent")[0]
if($center.EraGatePass -ne "True" -or $center.FullGatePass -ne "True" -or
   $center.ParentComparisonPass -ne "True" -or $center.NeighborSupportPass -ne "True") { throw "Center failed a frozen Model4 gate." }
if($center.Decision -ne "OPEN_MONEY_READINESS") { throw "Passing center did not open money readiness." }
if($neighbor.Decision -ne "SUPPORTS_CENTER") { throw "Passing neighbor was not retained." }
if([double]$center.FullNet -lt [double]$parent.FullNet -or [double]$center.FullDrawdownPercent -gt [double]$parent.FullDrawdownPercent) { throw "Parent comparison not enforced." }
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden acknowledgement leaked." }
Write-Output "PASS: D1 momentum-cap Model4 evidence opens money readiness only for a center with parent and neighbor support."
