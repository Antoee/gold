$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

& (Join-Path $PSScriptRoot 'test_three_lane_momentum_buy_payoff_source.ps1') | Out-Null
& (Join-Path $PSScriptRoot 'build_three_lane_momentum_buy_payoff_discovery_decision.ps1') | Out-Null

$decision = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_DECISION.csv'))
$summary = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_SUMMARY.csv'))
$results = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_MODEL1_RESULTS.csv'))
$manifest = @(Import-Csv (Join-Path $repo 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_MODEL1_MANIFEST.csv'))

if($decision.Count -ne 1 -or $decision[0].Status -ne 'REJECTED_IN_DISCOVERY') { throw 'Expected a frozen discovery rejection.' }
if($decision[0].ReportsParsed -ne '15' -or $decision[0].IdentityValidReports -ne '15') { throw 'Expected 15 exact parsed reports.' }
foreach($gate in @('AllDisjointErasPositive','CenterEraRetentionGate','CenterGrowthGate','CenterCagrGate','CenterEfficiencyGate','CenterRiskGate','CenterBehaviorChanged')) {
   if($decision[0].$gate -ne 'True') { throw "Expected $gate to pass." }
}
foreach($gate in @('CenterTradeCountGate','HoldoutValidationPermitted','Model4ValidationPermitted','ResearchPromotionPermitted','ForwardCandidateChanged','RealAccountTradingAllowed')) {
   if($decision[0].$gate -ne 'False') { throw "Expected $gate to remain false." }
}
if($decision[0].LowerRungsPassed -ne '0' -or $decision[0].LowerRungsRequired -ne '2') { throw 'Unexpected neighbor support result.' }
if($summary.Count -ne 5 -or $results.Count -ne 15 -or $manifest.Count -ne 15) { throw 'Unexpected evidence topology.' }
if(@($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw 'Every final report must be parsed.' }
if(@($manifest | Where-Object {
   $_.AdaptiveRiskPercent -ne '0.15' -or $_.MomentumRiskPercent -ne '0.15' -or $_.MomentumSellTakeProfitR -ne '2.00'
}).Count -ne 0) { throw 'Manifest lost the exact leader risk or frozen sell-target contract.' }
$control = $summary | Where-Object Candidate -eq 'mbp_control'
$center = $summary | Where-Object Candidate -eq 'mbp_center_buy250'
if($control.ContinuousNetProfit -ne '1353.74' -or $control.MaxDrawdownPercent -ne '1.06' -or $control.TotalTrades -ne '265') {
   throw 'Control reproduction changed.'
}
if($center.ContinuousNetProfit -ne '1412.34' -or $center.MaxDrawdownPercent -ne '1.1' -or
   $center.ProfitFactor -ne '1.9' -or $center.TotalTrades -ne '261') { throw 'Center evidence changed.' }

[pscustomobject][ordered]@{
   Status='PASS';Decision=$decision[0].Status;Reports=$results.Count;ControlNetProfit=$control.ContinuousNetProfit
   CenterNetProfit=$center.ContinuousNetProfit;CenterProfitFactor=$center.ProfitFactor
   CenterDrawdownPercent=$center.MaxDrawdownPercent;CenterTrades=$center.TotalTrades
   LowerRungsPassed=$decision[0].LowerRungsPassed;RecentOpened=$false;Model4Opened=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
}
