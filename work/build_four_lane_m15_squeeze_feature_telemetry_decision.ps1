[CmdletBinding()]
param()
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expected=[ordered]@{
   Source='C6B4BC66F661BB70CC51B92E320A87A5643745454C26791B09766F84DA9C94C4'
   Binary='EAC3F26DDCE7E7FC59CD02AFFE3F358397FCABF4F9D402F8F0B6D27B8EE3AA9C'
   Manifest='80FA027F757922A9E5404DCD682BC769F2328E5D8FC6F86CEED592B374BB1C07'
   Events='582EDBE4CBF398CB8108CCE7E11CA7C7FBFE64F2D1D68419AFC54C8D6A1A2F5E'
   Result='7BD6BB00475FB4EFF999E1BE95D1E38BFBFC667262647322E650FBEF34F2149D'
   Ledger='992D32AC8E7608CB24F337E4AB6275AADEA3580861A818EBDB2355A7E323CB84'
   Analyzer='EDD9DC6CE723F111C9C888B321DF76405A0E581AF539C0DD04F566912E7558C8'
   Screen='F8ADB87457F11EC554349BFEAC31A70F4F583F73D8A068DEF77A8EEFBE3C4B64'
   Selection='3869D8B044075FEF4F68F2521A05C223147B98E323119F56F3449567AA5B5237'
}
function Assert-Hash([string]$Relative,[string]$Expected,[string]$Label){$path=Join-Path $repo $Relative;$actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant();if($actual -ne $Expected){throw "$Label identity changed: $actual"}}
Assert-Hash 'work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Feature_Telemetry_Research.mq5' $expected.Source 'Source'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_MODEL1_MANIFEST.csv' $expected.Manifest 'Manifest'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_EVENTS.csv' $expected.Events 'Events'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_RESULT.csv' $expected.Result 'Result'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_TRADES.csv' $expected.Ledger 'Ledger'
Assert-Hash 'work\analyze_four_lane_m15_squeeze_feature_telemetry.py' $expected.Analyzer 'Analyzer'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SCREEN.csv' $expected.Screen 'Screen'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SELECTION.csv' $expected.Selection 'Selection'
$result=Import-Csv (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_RESULT.csv')|Select-Object -First 1
$selection=Import-Csv (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SELECTION.csv')|Select-Object -First 1
$run=Import-Csv (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_WORKER_1.csv')|Select-Object -First 1
$neutral=$result.Status -eq 'PARSED' -and [double]$result.NetProfit -eq 1695.16 -and [int]$result.TotalTrades -eq 391 -and [double]$result.ProfitFactor -eq 1.84 -and [double]$result.MaxDrawdownPercent -eq 1.10
if(!$neutral -or $run.Status -ne 'REPORT_FOUND' -or $run.PackageSourceSha256 -ne $expected.Source -or $run.PortableBinarySha256 -ne $expected.Binary){throw 'Behavior-neutral reproduction or run identity failed.'}
if($selection.Status -ne 'NO_TRAINING_CANDIDATE' -or [int]$selection.PassingTrainingFamilies -ne 0 -or $selection.ValidationOpened -ne 'False' -or $selection.CodeTestPermitted -ne 'False'){throw 'Frozen selection verdict changed.'}
$range=@(Import-Csv (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_SCREEN.csv')|Where-Object{$_.Feature -eq 'RangeATR' -and $_.Direction -eq 'minimum'}|Sort-Object{[double]$_.Quantile})
if($range.Count -ne 3 -or @($range|Where-Object TrainingSupport -eq 'True').Count -ne 2 -or [int]$range[2].KeptTrades -ne 41){throw 'Recorded RangeATR near-miss topology changed.'}
$decision=[pscustomobject][ordered]@{Status='NO_TRAINING_CANDIDATE';BehaviorNeutralReproduction=$neutral;ReportsParsed=1;IdentityValidReports=1;SqueezeTrades=88;TrainingTrades=55;ReservedValidationTrades=33;Features=15;Directions=2;ThresholdRungs=3;PassingTrainingFamilies=0;ValidationOpened=$false;CodeTestPermitted=$false;Post2020Permitted=$false;Model4Permitted=$false;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=1695.16;ControlCagrPercent=2.64;ControlProfitFactor=1.84;ControlDrawdownPercent=1.10;SourceSha256=$expected.Source;BinarySha256=$expected.Binary;ManifestSha256=$expected.Manifest;LedgerSha256=$expected.Ledger;AnalyzerSha256=$expected.Analyzer}
$decision|Export-Csv (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_DECISION.csv') -NoTypeInformation -Encoding ASCII
$lines=@(
   '# Four-Lane M15 Squeeze Feature-Telemetry Decision','',
   '**Decision: NO TRAINING CANDIDATE. No validation outcome, strategy filter, post-2020 test, Model 4 test, promotion, forward change, or real trading is permitted. NO NEW BEST.**','',
   '- Exact Model 1 telemetry report: `1/1` accepted with source, EX5, config, report, and sidecar identity.',
   '- Behavior-neutral reproduction: `+$1,695.16`, `+16.95%`, `2.64%/yr` CAGR, PF `1.84`, 391 report trades, `1.10%` drawdown.',
   '- Aggregated squeeze ledger: 88 positions, 129 exit deals, 41 protected partial events, `+$328.66` squeeze net.',
   '- Frozen screen: 15 completed-bar features x two directions x three fixed quantile rungs; 55 training trades from 2015-2018.',
   '- Passing training families: `0/30`. The reserved 33 trades from 2019-2020 were not opened for candidate validation because no family earned that right.','',
   '## Closest Training Family','',
   '| RangeATR minimum rung | Threshold | Kept | Retention | Improvement | Early half | Late half | PF | Training gate |',
   '|---|---:|---:|---:|---:|---:|---:|---:|---|',
   "| 15% | $($range[0].Threshold) | $($range[0].KeptTrades)/55 | $([math]::Round(100*[double]$range[0].Retention,2))% | +`$$([double]$range[0].Improvement) | +`$$([double]$range[0].early_improvement) | +`$$([double]$range[0].late_improvement) | $([math]::Round([double]$range[0].KeptPF,4)) | $($range[0].TrainingSupport) |",
   "| 20% center | $($range[1].Threshold) | $($range[1].KeptTrades)/55 | $([math]::Round(100*[double]$range[1].Retention,2))% | +`$$([double]$range[1].Improvement) | +`$$([double]$range[1].early_improvement) | +`$$([double]$range[1].late_improvement) | $([math]::Round([double]$range[1].KeptPF,4)) | $($range[1].TrainingSupport) |",
   "| 25% | $($range[2].Threshold) | $($range[2].KeptTrades)/55 | $([math]::Round(100*[double]$range[2].Retention,2))% | +`$$([double]$range[2].Improvement) | +`$$([double]$range[2].early_improvement) | +`$$([double]$range[2].late_improvement) | $([math]::Round([double]$range[2].KeptPF,4)) | $($range[2].TrainingSupport) |",'',
   'The RangeATR family was coherent in both training halves, but its 25% neighbor retained only `41/55 = 74.55%`, below the frozen `75%` floor. Changing the retention rule, threshold, or neighbor after seeing this result would be a rescue. The near miss is recorded for independent future research only; it does not open the reserved validation set.','',
   "- Source SHA-256: ``$($expected.Source)``","- EX5 SHA-256: ``$($expected.Binary)``","- Ledger SHA-256: ``$($expected.Ledger)``","- Frozen analyzer SHA-256: ``$($expected.Analyzer)``",'',
   'The verified Model 4 same-side exit-cooldown leader remains `+$2,492.25`, `+24.92%`, `1.95%/yr` CAGR, PF `1.93`, and `1.18%` drawdown. The invalid `$100,000` demo contributes zero forward evidence and real-account trading remains disabled.'
)
$lines|Set-Content (Join-Path $repo 'outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_DECISION.md') -Encoding ASCII
$decision
