[CmdletBinding()]
param(
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir='outputs\three_lane_reversion_strong_signal_lot_cap_discovery_model1_package\reports_here',
   [string]$CompileAuditPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_COMPILE_AUDIT.csv',
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256='C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$controlName='sslc_control';$unconditionalName='sslc_unconditional015';$lowerName='sslc_low012';$centerName='sslc_center015';$upperName='sslc_high018'
$continuousWindow='continuous_2015_2020';$windows=@('older_2015_2018','later_2019_2020',$continuousWindow)
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){$sign=if($Value -ge 0){'+'}else{'-'};return $sign+'$'+[Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
function BoolText([bool]$Value){if($Value){return 'PASS'};return 'FAIL'}

$manifest=@(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath));$audit=Import-Csv -LiteralPath (Resolve-RepoPath $CompileAuditPath)
if($manifest.Count -ne 15){throw 'Expected fifteen frozen manifest rows.'}
if($audit.Status -ne 'COMPILE_PASS' -or $audit.SourceSha256 -ne $expectedSourceSha256 -or $audit.CompileErrors -ne '0' -or $audit.CompileWarnings -ne '0' -or $audit.LaunchLocksRestored -ne 'True' -or $audit.MT5Processes -ne '0'){throw 'Compile audit is not an exact clean pass.'}
$expectedBinarySha256=([string]$audit.PortableBinarySha256).ToUpperInvariant();if($expectedBinarySha256 -notmatch '^[A-F0-9]{64}$'){throw 'Compile binary identity invalid.'}
if(@($manifest|Where-Object{$_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or [int]$_.Deposit -ne 10000}).Count -ne 0){throw 'Manifest source/model/capital identity changed.'}
if(@($manifest.Candidate|Sort-Object -Unique).Count -ne 5 -or @($manifest.Window|Sort-Object -Unique).Count -ne 3){throw 'Manifest topology changed.'}
foreach($item in $manifest){$config=Resolve-RepoPath ([string]$item.PackageConfig);if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256){throw "Config identity changed at rank $($item.QueueRank)."}}

$rawResults='work\SSLC_DECISION_RAW_RESULTS.csv';$rawSummary='work\SSLC_DECISION_RAW_SUMMARY.csv';$rawMetrics='work\SSLC_DECISION_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics|Out-Null
if($LASTEXITCODE -ne 0){throw 'Shared report collector failed.'}
$raw=@(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults));if($raw.Count -ne 15 -or @($raw|Where-Object Status -ne 'PARSED').Count -ne 0){throw 'Expected fifteen parsed reports.'}
$rawByReport=@{};foreach($row in $raw){$rawByReport[[string]$row.ExpectedReportName]=$row}

$workerRows=[Collections.Generic.List[object]]::new()
foreach($pattern in @('THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_EXACT_?.csv','THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_RETRY_?.csv')){
   foreach($file in Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File){foreach($row in @(Import-Csv -LiteralPath $file.FullName)){$workerRows.Add($row)|Out-Null}}
}
if($workerRows.Count -lt 15 -or @($workerRows|Where-Object{$_.PackageSourceSha256 -ne $expectedSourceSha256 -or $_.PortableExpertRecompiled -ne 'False' -or ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)}).Count -ne 0){throw 'Runner evidence incomplete or identity-mismatched.'}
$workerByRank=@{}
foreach($rank in 1..15){$attempts=@($workerRows|Where-Object{[int]$_.QueueRank -eq $rank});$valid=@($attempts|Where-Object Status -eq 'REPORT_FOUND'|Sort-Object Finished);if($valid.Count -ne 1){throw "Rank $rank does not have exactly one valid final report."};$workerByRank[[string]$rank]=$valid[0]}

$results=[Collections.Generic.List[object]]::new();$attestation=[Collections.Generic.List[object]]::new()
foreach($item in ($manifest|Sort-Object{[int]$_.QueueRank})){
   $parsed=$rawByReport[[string]$item.ExpectedReportName];$run=$workerByRank[[string]$item.QueueRank]
   if($null -eq $parsed -or $null -eq $run){throw "Evidence missing at rank $($item.QueueRank)."}
   $identityPath=[string]$run.ReportIdentityPath;if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)){throw "Identity sidecar missing at rank $($item.QueueRank)."}
   $identity=Get-Content -LiteralPath $identityPath -Raw|ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or $identity.ReportSha256 -ne $run.ReportSha256 -or $identity.ConfigSha256 -ne $run.PackageConfigSha256){throw "Identity sidecar mismatch at rank $($item.QueueRank)."}
   $returnDrawdown=if([double]$parsed.MaxDrawdownPercent -gt 0){[double]$parsed.TotalReturnPercent/[double]$parsed.MaxDrawdownPercent}else{0}
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;StrongSignalBodyRatio=[double]$item.StrongSignalBodyRatio
      StrongSignalRiskEnabled=$item.StrongSignalRiskEnabled;ReversionRiskPercent=[double]$item.ReversionRiskPercent
      SelectiveLotCapEnabled=$item.SelectiveLotCapEnabled;BaseReversionMaximumPositionLots=[double]$item.BaseReversionMaximumPositionLots
      StrongSignalMaximumPositionLots=[double]$item.StrongSignalMaximumPositionLots;Window=$item.Window;From=$item.From;To=$item.To;Model=[int]$item.Model
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256;Status=$parsed.Status
      NetProfit=[math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2);RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDrawdown,4)
      SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses;ReportSha256=$run.ReportSha256
   })|Out-Null
   $attempts=@($workerRows|Where-Object{[int]$_.QueueRank -eq [int]$item.QueueRank})
   $attestation.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status;Attempts=$attempts.Count;IdentityRetries=@($attempts|Where-Object Status -eq 'ERROR').Count;SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished})|Out-Null
}
$results|Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII;$attestation|Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII
$by=@{};foreach($row in $results){$by["$($row.Candidate)|$($row.Window)"]=$row}
$control=$by["$controlName|$continuousWindow"];$unconditional=$by["$unconditionalName|$continuousWindow"];$lower=$by["$lowerName|$continuousWindow"];$center=$by["$centerName|$continuousWindow"];$upper=$by["$upperName|$continuousWindow"]
function BehaviorChanged([string]$Candidate){foreach($window in $windows){$a=$by["$Candidate|$window"];$b=$by["$controlName|$window"];if([double]$a.NetProfit -ne [double]$b.NetProfit -or [double]$a.ProfitFactor -ne [double]$b.ProfitFactor -or [int]$a.TotalTrades -ne [int]$b.TotalTrades -or [double]$a.MaxDrawdownPercent -ne [double]$b.MaxDrawdownPercent -or [double]$a.RecoveryFactor -ne [double]$b.RecoveryFactor){return $true}};return $false}
function NoWorseEras([string]$Candidate){foreach($window in @('older_2015_2018','later_2019_2020')){if([double]$by["$Candidate|$window"].NetProfit -lt [double]$by["$controlName|$window"].NetProfit){return $false}};return $true}
function NeighborPass([string]$Candidate){$c=$by["$Candidate|$continuousWindow"];return (NoWorseEras $Candidate) -and (BehaviorChanged $Candidate) -and [double]$c.NetProfit -ge 1.03*[double]$control.NetProfit -and [double]$c.CagrPercent -ge [double]$control.CagrPercent+0.05 -and [double]$c.ProfitFactor -ge 0.97*[double]$control.ProfitFactor -and [double]$c.RecoveryFactor -ge 0.97*[double]$control.RecoveryFactor -and [double]$c.ReturnDrawdown -ge 0.97*[double]$control.ReturnDrawdown -and [double]$c.MaxDrawdownPercent -le 1.25}

$allPositive=@($results|Where-Object{[double]$_.NetProfit -le 0}).Count -eq 0;$unconditionalActive=BehaviorChanged $unconditionalName;$centerActive=BehaviorChanged $centerName;$centerNoWorse=NoWorseEras $centerName
$centerGrowth=[double]$center.NetProfit -ge 1.05*[double]$control.NetProfit;$centerCagr=[double]$center.CagrPercent -ge [double]$control.CagrPercent+0.08
$centerEfficiency=[double]$center.ProfitFactor -ge [double]$control.ProfitFactor -and [double]$center.RecoveryFactor -ge [double]$control.RecoveryFactor -and [double]$center.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$centerRisk=[double]$center.MaxDrawdownPercent -le 1.22 -and [double]$center.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent+0.10;$centerTrades=[int]$center.TotalTrades -ge [int]$control.TotalTrades-2
$unconditionalIncrement=[double]$unconditional.NetProfit-[double]$control.NetProfit;$centerIncrement=[double]$center.NetProfit-[double]$control.NetProfit
$retention=$unconditionalIncrement -gt 0 -and $centerIncrement -ge 0.50*$unconditionalIncrement
$improvesUnconditional=[double]$center.MaxDrawdownPercent -lt [double]$unconditional.MaxDrawdownPercent -and [double]$center.RecoveryFactor -gt [double]$unconditional.RecoveryFactor -and [double]$center.ReturnDrawdown -gt [double]$unconditional.ReturnDrawdown
$lowerGate=NeighborPass $lowerName;$upperGate=NeighborPass $upperName
$passed=$allPositive -and $unconditionalActive -and $centerActive -and $centerNoWorse -and $centerGrowth -and $centerCagr -and $centerEfficiency -and $centerRisk -and $centerTrades -and $retention -and $improvesUnconditional -and $lowerGate -and $upperGate

$summary=foreach($name in @($controlName,$unconditionalName,$lowerName,$centerName,$upperName)){$c=$by["$name|$continuousWindow"];[pscustomobject][ordered]@{Candidate=$name;Role=$c.Role;SelectiveLotCapEnabled=$c.SelectiveLotCapEnabled;BaseReversionMaximumPositionLots=$c.BaseReversionMaximumPositionLots;StrongSignalMaximumPositionLots=$c.StrongSignalMaximumPositionLots;OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;LaterNetProfit=$by["$name|later_2019_2020"].NetProfit;ContinuousNetProfit=$c.NetProfit;TotalReturnPercent=$c.TotalReturnPercent;CagrPercent=$c.CagrPercent;ProfitFactor=$c.ProfitFactor;TotalTrades=$c.TotalTrades;MaxDrawdownPercent=$c.MaxDrawdownPercent;RecoveryFactor=$c.RecoveryFactor;ReturnDrawdown=$c.ReturnDrawdown;BehaviorChangedVsControl=BehaviorChanged $name}}
$summary|Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$decision=[pscustomobject][ordered]@{Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=$results.Count;IdentityValidReports=$attestation.Count;TotalAttempts=$workerRows.Count;IdentityRefusals=@($workerRows|Where-Object Status -eq 'ERROR').Count;AllWindowsPositive=$allPositive;UnconditionalReferenceActive=$unconditionalActive;CenterBehaviorChanged=$centerActive;CenterNoWorseDisjointEras=$centerNoWorse;CenterGrowthGate=$centerGrowth;CenterCagrGate=$centerCagr;CenterEfficiencyGate=$centerEfficiency;CenterRiskGate=$centerRisk;CenterTradeCountGate=$centerTrades;IncrementalNetRetentionGate=$retention;ImprovesUnconditionalEfficiency=$improvesUnconditional;LowerNeighborGate=$lowerGate;UpperNeighborGate=$upperGate;HoldoutValidationPermitted=$passed;Model4ValidationPermitted=$false;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit;UnconditionalNetProfit=$unconditional.NetProfit;CenterNetProfit=$center.NetProfit;SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CenterProfileSha256=$center.ProfileSha256}
$decision|Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines=[Collections.Generic.List[string]]::new();$lines.Add('# Strong-Signal Selective Reversion Lot-Cap Discovery Decision');$lines.Add('');$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the exact frozen center may proceed to recent-data validation; Model 4 and promotion remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**'}));$lines.Add('')
$lines.Add("- Reports: ``$($results.Count) / 15`` exact source/binary/config/report identities");$lines.Add("- Attempts: ``$($workerRows.Count)``; identity refusals: ``$(@($workerRows|Where-Object Status -eq 'ERROR').Count)``");$lines.Add("- Source SHA-256: ``$expectedSourceSha256``");$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``");$lines.Add('- `$10,000`; 2015-2020; MT5 Model 1; requested reversion risk `0.45%`; real trading disabled');$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |');$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
foreach($row in $summary){$label=switch($row.Candidate){$controlName{'Control 0.10'};$unconditionalName{'Unconditional 0.15'};$lowerName{'Selective 0.12'};$centerName{'**Selective 0.15 center**'};$upperName{'Selective 0.18'}};$lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")}
$lines.Add('');$lines.Add('## Frozen Gate');$lines.Add('');$lines.Add("- Every report profitable: ``$allPositive`` ($(BoolText $allPositive))");$lines.Add("- Unconditional reference active: ``$unconditionalActive`` ($(BoolText $unconditionalActive))");$lines.Add("- Center changed behavior: ``$centerActive`` ($(BoolText $centerActive))");$lines.Add("- Center no worse in both eras: ``$centerNoWorse`` ($(BoolText $centerNoWorse))");$lines.Add("- Center growth/CAGR: ``$centerGrowth / $centerCagr`` ($(BoolText ($centerGrowth -and $centerCagr)))");$lines.Add("- Center PF/recovery/return-DD: ``$centerEfficiency`` ($(BoolText $centerEfficiency))");$lines.Add("- Center drawdown: ``$centerRisk`` ($(BoolText $centerRisk))");$lines.Add("- Center trade count: ``$centerTrades`` ($(BoolText $centerTrades))");$lines.Add("- Retains 50% of unconditional increment: ``$retention`` ($(BoolText $retention))");$lines.Add("- Improves efficiency versus unconditional: ``$improvesUnconditional`` ($(BoolText $improvesUnconditional))");$lines.Add("- Selective 0.12 neighbor: ``$lowerGate`` ($(BoolText $lowerGate))");$lines.Add("- Selective 0.18 neighbor: ``$upperGate`` ($(BoolText $upperGate))");$lines.Add('');$lines.Add('## Boundary');$lines.Add('');$lines.Add('The feature uses only the completed signal candle body ratio to select a lot ceiling. It never raises requested risk above 0.45%, and every size still passes broker-valued initial-stop sizing, account-wide exposure checks, and post-fill reconciliation.');$lines.Add('');$lines.Add($(if($passed){'The frozen center and both neighbors passed sealed discovery. Recent-data validation is required before Model 4; this is not yet a new best.'}else{'The family failed at least one frozen growth, risk, efficiency, or neighborhood requirement. Recent data and Model 4 remain sealed, and neither threshold nor cap may be changed from these results.'}));$lines.Add('');$lines.Add('ATB150 and the registered forward candidate remain unchanged; real-account trading remains disabled.')
$lines|Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
