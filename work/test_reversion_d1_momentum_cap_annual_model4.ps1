Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$results = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RESULTS.csv"))
$runs = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RUN.csv"))
$decision = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_DECISION.csv"))
if($results.Count -ne 12 -or $runs.Count -ne 12 -or $decision.Count -ne 12) { throw "Unexpected annual Model4 artifact count." }
if(@($runs | Where-Object Status -ne "REPORT_FOUND").Count -gt 0) { throw "Identity-invalid annual runner evidence is canonical." }
$negative = @($decision | Where-Object { [double]$_.NetProfit -lt 0.0 })
if($negative.Count -ne 2 -or @($negative.Window | Sort-Object) -join "," -ne "year_2019,year_2022") { throw "Expected annual failures were not preserved." }
if(@($decision | Where-Object DrawdownPass -ne "True").Count -gt 0) { throw "Unexpected annual drawdown failure." }
if(@($decision | Where-Object LossStreakPass -ne "True").Count -gt 0) { throw "Unexpected annual loss-streak failure." }
if(!(Test-Path -LiteralPath (Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"))) { throw "MT5 hard lock is missing." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock")) { throw "MT5 unlock leaked." }
if(Test-Path -LiteralPath (Join-Path $repo "work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock")) { throw "Hidden acknowledgement leaked." }
Write-Output "PASS: annual Model4 evidence stops money readiness on the two frozen red-year failures."
