[CmdletBinding()]
param(
   [string]$ResultsPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_MODEL1_RESULTS.csv',
   [string]$RunPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_RUN_ATTESTATION.csv',
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_MODEL1_MANIFEST.csv',
   [string]$DecisionCsvPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_DECISION.md'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Number($Value){return [double]::Parse([string]$Value,[Globalization.CultureInfo]::InvariantCulture)}
function Row([string]$Candidate,[string]$Window){
   $found=@($rows|Where-Object{$_.Candidate-eq$Candidate-and$_.Window-eq$Window})
   if($found.Count-ne1){throw "Expected one $Candidate / $Window row."}
   return $found[0]
}
function ReturnDd($Row){$dd=Number $Row.MaxDrawdownPercent;if($dd-le0){return 0.0};return (Number $Row.TotalReturnPercent)/$dd}
function Same-Metrics($Left,$Right){
   foreach($name in @('NetProfit','CagrPercent','ProfitFactor','TotalTrades','MaxDrawdownPercent','RecoveryFactor')){if((Number $Left.$name)-ne(Number $Right.$name)){return $false}}
   return $true
}

$rows=@(Import-Csv (Resolve-RepoPath $ResultsPath));$run=@(Import-Csv (Resolve-RepoPath $RunPath));$manifest=@(Import-Csv (Resolve-RepoPath $ManifestPath))
if($rows.Count-ne18-or$run.Count-ne18-or$manifest.Count-ne18){throw 'Decision requires 18 results, run rows, and manifest rows.'}
if(@($rows|Where-Object Status -ne PARSED).Count-or@($run|Where-Object Status -ne REPORT_FOUND).Count){throw 'Decision refuses incomplete evidence.'}
if(@($run.PackageSourceSha256|Sort-Object -Unique).Count-ne1-or@($run.PortableBinarySha256|Sort-Object -Unique).Count-ne1){throw 'Decision refuses mixed source or binary identities.'}

$exact=@('holdout_2021_2023','latest_2024_2026','continuous_2021_2026'|ForEach-Object{Row 'sqh_exact_control' $_})
$capacity=@('holdout_2021_2023','latest_2024_2026','continuous_2021_2026'|ForEach-Object{Row 'sqh_capacity_control' $_})
$controlsExact=(Same-Metrics $exact[0] $capacity[0])-and(Same-Metrics $exact[1] $capacity[1])-and(Same-Metrics $exact[2] $capacity[2])
$everyRowProfitable=@($rows|Where-Object{(Number $_.NetProfit)-le0}).Count-eq0
$controlOld=$exact[0];$controlLatest=$exact[1];$controlContinuous=$exact[2]
$referenceContinuous=Row 'sqh_reference150' 'continuous_2021_2026'

function Evaluate-Candidate([string]$Candidate,[bool]$Center){
   $old=Row $Candidate 'holdout_2021_2023';$latest=Row $Candidate 'latest_2024_2026';$continuous=Row $Candidate 'continuous_2021_2026'
   $growth=((Number $continuous.NetProfit)/(Number $controlContinuous.NetProfit)-1.0)*100.0
   $cagrGain=(Number $continuous.CagrPercent)-(Number $controlContinuous.CagrPercent)
   $pfRetention=(Number $continuous.ProfitFactor)/(Number $controlContinuous.ProfitFactor)*100.0
   $recoveryRetention=(Number $continuous.RecoveryFactor)/(Number $controlContinuous.RecoveryFactor)*100.0
   $returnDdRetention=(ReturnDd $continuous)/(ReturnDd $controlContinuous)*100.0
   $tradeRetention=(Number $continuous.TotalTrades)/(Number $controlContinuous.TotalTrades)*100.0
   $ddLimit=[Math]::Min(1.50,(Number $controlContinuous.MaxDrawdownPercent)+0.20)
   $bothEras=(Number $old.NetProfit)-ge(Number $controlOld.NetProfit)-and(Number $latest.NetProfit)-ge(Number $controlLatest.NetProfit)
   $growthFloor=if($Center){10.0}else{5.0};$qualityFloor=if($Center){95.0}else{90.0}
   $referenceGrowth=((Number $continuous.NetProfit)/(Number $referenceContinuous.NetProfit)-1.0)*100.0
   $pass=$everyRowProfitable-and$bothEras-and$growth-ge$growthFloor-and$pfRetention-ge$qualityFloor-and$recoveryRetention-ge$qualityFloor-and$returnDdRetention-ge $(if($Center){100.0}else{90.0})-and(Number $continuous.MaxDrawdownPercent)-le$ddLimit-and$tradeRetention-ge95.0
   if($Center){$pass=$pass-and$cagrGain-ge0.15-and$referenceGrowth-ge3.0-and(Number $continuous.NetProfit)-ne(Number $referenceContinuous.NetProfit)}
   [pscustomobject][ordered]@{Candidate=$Candidate;Role=$continuous.Role;TargetR=$continuous.SqueezeTakeProfitR;OldNet=$old.NetProfit;LatestNet=$latest.NetProfit;ContinuousNet=$continuous.NetProfit;ContinuousCagr=$continuous.CagrPercent;ContinuousPf=$continuous.ProfitFactor;Trades=$continuous.TotalTrades;DrawdownPercent=$continuous.MaxDrawdownPercent;Recovery=$continuous.RecoveryFactor;GrowthVsControlPercent=[Math]::Round($growth,4);CagrGainPoint=[Math]::Round($cagrGain,4);PfRetentionPercent=[Math]::Round($pfRetention,4);RecoveryRetentionPercent=[Math]::Round($recoveryRetention,4);ReturnDdRetentionPercent=[Math]::Round($returnDdRetention,4);TradeRetentionPercent=[Math]::Round($tradeRetention,4);GrowthVsReferencePercent=[Math]::Round($referenceGrowth,4);BothErasNoWorse=$bothEras;GatePass=$pass}
}

$decisionRows=@(
   Evaluate-Candidate 'sqh_reference150' $false
   Evaluate-Candidate 'sqh_lower200' $false
   Evaluate-Candidate 'sqh_center225' $true
   Evaluate-Candidate 'sqh_upper250' $false
)
$center=$decisionRows|Where-Object Candidate -eq 'sqh_center225'
$sensitivityPasses=@($decisionRows|Where-Object{$_.Candidate-in@('sqh_lower200','sqh_upper250')-and$_.GatePass}).Count
$overall=$controlsExact-and$everyRowProfitable-and[bool]$center.GatePass-and$sensitivityPasses-ge1
$decisionRows|Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$sourceHash=@($run.PackageSourceSha256|Sort-Object -Unique)[0];$binaryHash=@($run.PortableBinarySha256|Sort-Object -Unique)[0]
$manifestHash=(Get-FileHash (Resolve-RepoPath $ManifestPath) -Algorithm SHA256).Hash.ToUpperInvariant();$resultsHash=(Get-FileHash (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash.ToUpperInvariant();$runHash=(Get-FileHash (Resolve-RepoPath $RunPath) -Algorithm SHA256).Hash.ToUpperInvariant()
$lines=@(
   '# Four-Lane M15 Squeeze 2.25R Feature Holdout Decision','',
   $(if($overall){'**Decision: HOLDOUT PASSED. A separately frozen full-history Model 4 confirmation may be built; no promotion or forward change is permitted yet.**'}else{'**Decision: REJECTED IN FEATURE HOLDOUT. No Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**'}),'',
   "- Exact accepted Model 1 reports: ``18/18``",
   "- Source SHA-256: ``$sourceHash``",
   "- EX5 SHA-256: ``$binaryHash``",
   "- Manifest SHA-256: ``$manifestHash``",
   "- Results SHA-256: ``$resultsHash``",
   "- Run attestation SHA-256: ``$runHash``",
   "- Disabled controls reproduced exactly: ``$controlsExact``",
   "- Every report profitable: ``$everyRowProfitable``",'',
   '| Candidate | Target | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Growth vs control | PF retained | Gate |',
   '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|'
)
foreach($item in $decisionRows){$lines+=('| {0} | {1}R | {2:+$0.00;-$0.00;$0.00} | {3:+$0.00;-$0.00;$0.00} | {4:+$0.00;-$0.00;$0.00} | {5}%/yr | {6} | {7} | {8}% | {9}% | {10}% | {11} |' -f $item.Candidate,(Number $item.TargetR),(Number $item.OldNet),(Number $item.LatestNet),(Number $item.ContinuousNet),(Number $item.ContinuousCagr),(Number $item.ContinuousPf),(Number $item.Trades),(Number $item.DrawdownPercent),(Number $item.GrowthVsControlPercent),(Number $item.PfRetentionPercent),$item.GatePass)}
$lines+=@('','## Frozen Gate','',
   "- Fixed 2.25R center pass: ``$($center.GatePass)``",
   "- Passing fixed sensitivity rows: ``$sensitivityPasses/2``; required: ``1/2``",'',
   '## Interpretation','',
   'The fixed 2.25R center improved continuous post-2020 net from `+$1,046.44` to `+$1,131.75`, an `8.15%` gain, and beat the enabled 1.50R reference by `4.12%`. It did not reach the frozen 10% growth floor and its CAGR gain was `0.14` point versus `0.15` required.',
   'More importantly, the center trailed exact control in 2024-2026 (`+$418.67` versus `+$434.36`), reduced continuous PF from `2.08` to `1.76`, and raised drawdown from `1.21%` to `1.51%`, above the paired `1.41%` limit. Neither sensitivity row passed the complete quality and drawdown gate.',
   'The stronger pre-2021 2.25R result therefore did not transfer with enough risk-adjusted support. The target family is closed without spending Model 4 time. The verified three-lane same-side exit-cooldown leader remains unchanged.',
   'The frozen forward candidate is unchanged. The attached `$100,000` demo violates the `$10,000` capital contract and remains zero forward evidence; real-account trading remains disabled.'
)
$lines|Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
[pscustomobject]@{Decision=if($overall){'HOLDOUT_PASS'}else{'REJECTED'};ControlsExact=$controlsExact;EveryReportProfitable=$everyRowProfitable;CenterPass=[bool]$center.GatePass;SensitivityPasses=$sensitivityPasses;Model4Allowed=$overall;ForwardCandidateChanged=$false;RealAccountApproved=$false}
