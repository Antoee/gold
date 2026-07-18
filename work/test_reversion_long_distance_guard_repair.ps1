Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A"
$expectedContractHash = "6477C8F3D87B355F5AF397B5B6EE47D058108978EA8BAB95B3366A9D1C7278DE"

$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "work\Professional_XAUUSD_Reversion_Long_Distance_Guard_Portfolio.mq5") -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Long-distance guard source identity changed." }
$contractHash = (Get-FileHash -LiteralPath (Join-Path $repo "outputs\REVERSION_LONG_DISTANCE_GUARD_CONTRACT.md") -Algorithm SHA256).Hash
if($contractHash -ne $expectedContractHash) { throw "Repair contract identity changed." }

$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_QUEUE.csv"))
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_RESULTS.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_DECISION.csv"))
if($queue.Count -ne 8 -or $results.Count -ne 8 -or $decision.Count -ne 4) { throw "Unexpected artifact row count." }
if(@($queue | Where-Object To -gt "2020.12.31").Count -gt 0) { throw "Post-2020 data leaked into repair." }
if(@($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Unparsed result present." }
if(@($decision | Where-Object { $_.Candidate -ne "rld_fixed_control" -and [double]$_.RepairNetProfit -ge 0.0 }).Count -gt 0) {
   throw "A losing broad-window profile was not rejected."
}
if(@($decision | Where-Object { $_.Candidate -ne "rld_fixed_control" -and $_.Decision -ne "REJECT_BEFORE_HOLDOUT" }).Count -gt 0) {
   throw "Decision does not enforce the frozen gate."
}
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked after testing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden-desktop acknowledgement leaked after testing." }

Write-Output "PASS: reversion long-distance guard artifacts enforce rejection before post-2020 holdout."
