$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Read-One([string]$Path) {
   $rows = @(Import-Csv (Join-Path $repo $Path))
   if($rows.Count -ne 1) { throw "Expected one row in $Path." }
   return $rows[0]
}

& (Join-Path $PSScriptRoot 'test_three_lane_momentum_same_side_exit_cooldown_source.ps1') | Out-Null

$source = Join-Path $repo 'release\three-lane-momentum-same-side-exit-cooldown-provisional\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Provisional.mq5'
$profile = Join-Path $repo 'release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set'
$sourceHash = (Get-FileHash $source -Algorithm SHA256).Hash.ToUpperInvariant()
$profileHash = (Get-FileHash $profile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E') { throw 'Release source identity changed.' }
if($profileHash -ne 'ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C') { throw 'Release profile identity changed.' }

$model4 = Read-One 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_DECISION.csv'
$annual = Read-One 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_DECISION.csv'
$stress = Read-One 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_STRESS_DECISION.csv'
if($model4.Status -ne 'MODEL4_GATE_PASSED' -or $model4.CenterNetProfit -ne '2492.25') { throw 'Model 4 gate changed.' }
if($annual.Status -ne 'ANNUAL_GATE_PASSED' -or $annual.CenterNoWorseYears -ne '12') { throw 'Annual gate changed.' }
if($stress.Status -ne 'STRESS_GATE_PASSED' -or $stress.HardRiskAuditPass -ne 'True' -or $stress.CostStressPass -ne 'True' -or $stress.OrderAwareMonteCarloPass -ne 'True') { throw 'Stress gate changed.' }
foreach($row in @($model4,$annual,$stress)) {
   if($row.ForwardCandidateChanged -ne 'False' -or $row.RealAccountTradingAllowed -ne 'False') { throw 'Research boundary changed.' }
}

$results = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_RESULTS.csv'))
$center = @($results | Where-Object { $_.Candidate -eq 'msec_center_060' -and $_.Window -eq 'continuous_2015_2026' })
if($center.Count -ne 1 -or $center[0].NetProfit -ne '2492.25' -or $center[0].CagrPercent -ne '1.95' -or $center[0].ProfitFactor -ne '1.93' -or $center[0].MaxDrawdownPercent -ne '1.18' -or $center[0].TotalTrades -ne '400') { throw 'Continuous leader metrics changed.' }

$risk = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_RISK_AUDIT.csv'))
if($risk.Count -ne 400 -or @($risk | Where-Object { $_.LanePass -ne 'True' -or $_.PortfolioPass -ne 'True' }).Count -ne 0) { throw 'Hard-risk audit changed.' }
$maxRisk = ($risk | Measure-Object PortfolioInitialRiskPercent -Maximum).Maximum
if([double]$maxRisk -gt 0.75) { throw 'Portfolio risk cap exceeded.' }

[pscustomobject][ordered]@{
   Status='PASS';NetProfit=$center[0].NetProfit;CagrPercent=$center[0].CagrPercent
   ProfitFactor=$center[0].ProfitFactor;MaxDrawdownPercent=$center[0].MaxDrawdownPercent
   Trades=$center[0].TotalTrades;MaximumPortfolioInitialRiskPercent=$maxRisk
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
}
