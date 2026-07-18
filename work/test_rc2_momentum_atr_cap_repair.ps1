Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$expectedContractHash = "484985776EF02F5C21D85AC3932B49B5DB9943F1946729C6BE12306700336D60"

$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5") -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "RC2 source identity changed." }
$contractHash = (Get-FileHash -LiteralPath (Join-Path $repo "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_CONTRACT.md") -Algorithm SHA256).Hash
if($contractHash -ne $expectedContractHash) { throw "Repair contract identity changed." }

$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_MODEL1_QUEUE.csv"))
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_MODEL1_RESULTS.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_DECISION.csv"))
if($queue.Count -ne 8 -or $results.Count -ne 8 -or $decision.Count -ne 4) { throw "Unexpected artifact row count." }
if(@($queue | Where-Object To -gt "2020.12.31").Count -gt 0) { throw "Post-2020 data leaked into repair." }
if(@($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Unparsed result present." }
if(@($decision | Where-Object { $_.Candidate -ne "mac_fixed_control" -and [double]$_.RepairNetProfit -ge 0.0 }).Count -gt 0) {
   throw "A losing broad-window profile was not rejected."
}
if(@($decision | Where-Object { $_.Candidate -ne "mac_fixed_control" -and $_.Decision -ne "REJECT_BEFORE_HOLDOUT" }).Count -gt 0) {
   throw "Decision does not enforce the frozen gate."
}
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked after testing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden-desktop acknowledgement leaked after testing." }

Write-Output "PASS: RC2 momentum ATR-cap repair artifacts enforce rejection before post-2020 holdout."
