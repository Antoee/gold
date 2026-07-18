$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$reportDir=Join-Path $repo "outputs\momentum_breakout_quality_discovery_model1_package\reports_here"
$reportCount=if(Test-Path $reportDir){@(Get-ChildItem $reportDir -Filter '*.htm').Count}else{0}
if($reportCount-eq21){& (Join-Path $PSScriptRoot "build_momentum_breakout_quality_discovery_decision.ps1")|Out-Null}
elseif($reportCount-ne0){throw "Expected either all 21 raw reports or none; found $reportCount."}
$decision=@(Import-Csv (Join-Path $repo "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_DECISION.csv"))
$results=@(Import-Csv (Join-Path $repo "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_RESULTS.csv"))
$summary=@(Import-Csv (Join-Path $repo "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_SUMMARY.csv"))
if($decision.Count-ne1-or$results.Count-ne21-or$summary.Count-ne7){throw "Decision dimensions changed."}
if(@($results|Where-Object {$_.Status-ne'PARSED'-or$_.ReportSourceIdentityPass-ne'True'}).Count-ne0){throw "Incomplete or identity-invalid report."}
if(@($results|Where-Object {[int]$_.To.Substring(0,4)-gt2020}).Count-ne0){throw "Post-2020 data entered discovery."}
$eligible=@($summary | Where-Object Decision -eq 'DISCOVERY_ELIGIBLE')
if(([int]$decision[0].EligibleProfiles-ne$eligible.Count)-or(($eligible.Count-gt0)-ne($decision[0].Status-eq'DISCOVERY_ELIGIBLE'))){throw "Decision/summary mismatch."}
if($decision[0].HoldoutOpened-ne'False'-or$decision[0].ForwardCandidateChanged-ne'False'-or$decision[0].RealAccountTradingAllowed-ne'False'){throw "Research isolation changed."}
if(!(Test-Path (Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'))-or(Test-Path (Join-Path $PSScriptRoot 'ALLOW_MT5_LOCAL_LAUNCH.unlock'))-or@(Get-Process terminal64,metatester64 -ErrorAction SilentlyContinue).Count-ne0){throw "MT5 safety lock is not restored."}
"MOMENTUM_BREAKOUT_QUALITY_DECISION_TEST_PASS status=$($decision[0].Status) eligible=$($eligible.Count)"
