$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

& (Join-Path $PSScriptRoot 'test_three_lane_momentum_buy_residual_risk_source.ps1') | Out-Null
& (Join-Path $PSScriptRoot 'build_three_lane_momentum_buy_residual_risk_discovery_decision.ps1') | Out-Null

$decision = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_DECISION.csv'))
$summary = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_SUMMARY.csv'))
$results = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_MODEL1_RESULTS.csv'))
$manifest = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_MODEL1_MANIFEST.csv'))

if($decision.Count -ne 1 -or $decision[0].Status -ne 'REJECTED_IN_DISCOVERY') { throw 'Expected a frozen discovery rejection.' }
if($decision[0].ReportsParsed -ne '18' -or $decision[0].IdentityValidReports -ne '18') { throw 'Expected 18 exact parsed reports.' }
if($decision[0].CenterGrowthGate -ne 'True' -or $decision[0].CenterCagrGate -ne 'True') { throw 'Expected the center headline-growth gates to pass.' }
foreach($gate in @('CenterEfficiencyGate','CenterRiskGate','CenterTradeCountGate','HoldoutValidationPermitted','Model4ValidationPermitted','ResearchPromotionPermitted','ForwardCandidateChanged','RealAccountTradingAllowed')) {
   if($decision[0].$gate -ne 'False') { throw "Expected $gate to remain false." }
}
if($decision[0].LowerRungsPassed -ne '0' -or $decision[0].LowerRungsRequired -ne '3') { throw 'Unexpected lower-rung support result.' }
if($summary.Count -ne 6 -or $results.Count -ne 18 -or $manifest.Count -ne 18) { throw 'Unexpected evidence topology.' }
if(@($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw 'Every final report must be parsed.' }
if(@($manifest | Where-Object { $_.AdaptiveRiskPercent -ne '0.15' -or $_.BaseLotEligibility -ne 'required' }).Count -ne 0) {
   throw 'Manifest lost the exact leader adaptive-risk or base-lot contract.'
}
$control = $summary | Where-Object Candidate -eq 'mbr_control'
$center = $summary | Where-Object Candidate -eq 'mbr_center_buy020'
if($control.ContinuousNetProfit -ne '1353.74' -or $control.MaxDrawdownPercent -ne '1.06' -or $control.TotalTrades -ne '265') {
   throw 'Control reproduction changed.'
}
if($center.ContinuousNetProfit -ne '1524.39' -or $center.MaxDrawdownPercent -ne '1.3' -or $center.TotalTrades -ne '266') {
   throw 'Center evidence changed.'
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   Decision = $decision[0].Status
   Reports = $results.Count
   ControlNetProfit = $control.ContinuousNetProfit
   CenterNetProfit = $center.ContinuousNetProfit
   CenterDrawdownPercent = $center.MaxDrawdownPercent
   LowerRungsPassed = $decision[0].LowerRungsPassed
   RecentOpened = $false
   Model4Opened = $false
   ForwardCandidateChanged = $false
   RealAccountTradingAllowed = $false
}
