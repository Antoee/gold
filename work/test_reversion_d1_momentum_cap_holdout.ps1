Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_MODEL1_RESULTS.csv"))
$runs = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_MODEL1_RUN.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_DECISION.csv"))
if($results.Count -ne 3 -or $runs.Count -ne 3 -or $decision.Count -ne 3) { throw "Unexpected holdout artifact count." }
if(@($runs | Where-Object Status -ne "REPORT_FOUND").Count -gt 0) { throw "Identity-invalid runner evidence is canonical." }
if(@($decision | Where-Object GatePass -ne "True").Count -gt 0) { throw "A frozen holdout gate failed." }
$continuous = @($decision | Where-Object Window -eq "continuous_2021_2026")[0]
if([int]$continuous.Trades -lt 120 -or [double]$continuous.ProfitFactor -lt 1.30 -or [double]$continuous.MaxDrawdownPercent -gt 2.80) {
   throw "Continuous holdout quality gate was not enforced."
}
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden acknowledgement leaked." }
Write-Output "PASS: D1 momentum-cap holdout opens Model4 only after every frozen post-2020 gate passes."
