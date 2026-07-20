[CmdletBinding()]
param(
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_MANIFEST.csv',
   [string]$ReportDir='outputs\three_lane_reversion_strong_signal_lot_cap_model4_package\reports_here',
   [string]$CompileAuditPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_COMPILE_AUDIT.csv',
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RESULTS.csv',
   [string]$SummaryPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_SUMMARY.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_DECISION.md',
   [string]$RunAttestationPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RUN_ATTESTATION.csv'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceHash='C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$controlName='sslc_control';$centerName='sslc_center015';$continuous='continuous_2015_2026'
$windows=@('older_2015_2018','middle_2019_2022','recent_2023_2026',$continuous)
function Resolve-P([string]$p){if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $repo $p}
function Money([double]$v){$sign=if($v-ge 0){'+'}else{'-'};return $sign+'$'+[Math]::Abs($v).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
function PassText([bool]$v){if($v){return 'PASS'};return 'FAIL'}

$manifest=@(Import-Csv (Resolve-P $ManifestPath));$audit=Import-Csv (Resolve-P $CompileAuditPath)
if($manifest.Count-ne 8){throw 'Expected eight Model 4 rows.'}
if($audit.Status-ne'COMPILE_PASS'-or$audit.SourceSha256-ne$sourceHash-or$audit.CompileErrors-ne'0'-or$audit.CompileWarnings-ne'0'-or$audit.LaunchLocksRestored-ne'True'){throw 'Compile audit invalid.'}
$binary=[string]$audit.PortableBinarySha256
foreach($item in $manifest){if($item.SourceSha256-ne$sourceHash-or[int]$item.Model-ne 4){throw 'Manifest identity changed.'};$config=Resolve-P([string]$item.PackageConfig);if((Get-FileHash $config -Algorithm SHA256).Hash-ne$item.ConfigSha256){throw "Config changed at rank $($item.QueueRank)."}}

$rawResults='work\SSLC_M4_RAW_RESULTS.csv';$rawSummary='work\SSLC_M4_RAW_SUMMARY.csv';$rawMetrics='work\SSLC_M4_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics|Out-Null
if($LASTEXITCODE-ne 0){throw 'Collector failed.'}
$raw=@(Import-Csv (Resolve-P $rawResults));if($raw.Count-ne 8-or@($raw|Where-Object{$_.Status-ne'PARSED'}).Count){throw 'Expected eight parsed reports.'}
$rawBy=@{};foreach($row in $raw){$rawBy[[string]$row.ExpectedReportName]=$row}
$workers=[Collections.Generic.List[object]]::new()
foreach($pattern in @('THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_EXACT_?.csv','THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_RETRY_?.csv')){foreach($file in Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File){foreach($row in @(Import-Csv $file.FullName)){$workers.Add($row)|Out-Null}}}
if($workers.Count-lt 8-or@($workers|Where-Object{$_.PackageSourceSha256-ne$sourceHash-or$_.PortableExpertRecompiled-ne'False'-or($_.Status-eq'REPORT_FOUND'-and$_.PortableBinarySha256-ne$binary)}).Count){throw 'Runner identity invalid.'}
$validBy=@{};foreach($rank in 1..8){$attempts=@($workers|Where-Object{[int]$_.QueueRank-eq$rank});$valid=@($attempts|Where-Object{$_.Status-eq'REPORT_FOUND'});if($valid.Count-ne 1){throw "Rank $rank valid count $($valid.Count)."};$validBy[[string]$rank]=$valid[0]}

$results=[Collections.Generic.List[object]]::new();$attestation=[Collections.Generic.List[object]]::new()
foreach($item in $manifest|Sort-Object{[int]$_.QueueRank}){
   $parsed=$rawBy[[string]$item.ExpectedReportName];$run=$validBy[[string]$item.QueueRank]
   $identity=Get-Content ([string]$run.ReportIdentityPath) -Raw|ConvertFrom-Json
   if($identity.SourceSha256-ne$sourceHash-or$identity.PortableBinarySha256-ne$binary-or$identity.ReportSha256-ne$run.ReportSha256-or$identity.ConfigSha256-ne$run.PackageConfigSha256){throw "Sidecar mismatch at rank $($item.QueueRank)."}
   $returnDrawdown=if([double]$parsed.MaxDrawdownPercent-gt 0){[double]$parsed.TotalReturnPercent/[double]$parsed.MaxDrawdownPercent}else{0}
   $results.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window;From=$item.From;To=$item.To;Model=4;ProfileSha256=$item.ProfileSha256;SourceSha256=$sourceHash;BinarySha256=$binary;NetProfit=[math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[math]::Round([double]$parsed.CagrPercent,2);ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2);RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDrawdown,4);SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses;ReportSha256=$run.ReportSha256})|Out-Null
   $attempts=@($workers|Where-Object{[int]$_.QueueRank-eq[int]$item.QueueRank})
   $attestation.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status;Attempts=$attempts.Count;IdentityRetries=@($attempts|Where-Object{$_.Status-eq'ERROR'}).Count;SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished})|Out-Null
}
$results|Export-Csv (Resolve-P $ResultsPath)-NoTypeInformation -Encoding ASCII;$attestation|Export-Csv (Resolve-P $RunAttestationPath)-NoTypeInformation -Encoding ASCII
$by=@{};foreach($row in $results){$by["$($row.Candidate)|$($row.Window)"]=$row};$control=$by["$controlName|$continuous"];$center=$by["$centerName|$continuous"]
$allCenterPositive=@($results|Where-Object{$_.Candidate-eq$centerName-and[double]$_.NetProfit-le 0}).Count-eq 0
$noWorse=$true;foreach($window in $windows){if([double]$by["$centerName|$window"].NetProfit-lt[double]$by["$controlName|$window"].NetProfit){$noWorse=$false}}
$growth=[double]$center.NetProfit-ge 1.05*[double]$control.NetProfit;$cagr=[double]$center.CagrPercent-ge[double]$control.CagrPercent+0.08
$efficiency=[double]$center.ProfitFactor-ge[double]$control.ProfitFactor-and[double]$center.RecoveryFactor-ge[double]$control.RecoveryFactor-and[double]$center.ReturnDrawdown-ge[double]$control.ReturnDrawdown
$risk=[double]$center.MaxDrawdownPercent-le 1.25-and[double]$center.MaxDrawdownPercent-le[double]$control.MaxDrawdownPercent+0.10;$trades=[int]$center.TotalTrades-ge[int]$control.TotalTrades-2
$passed=$allCenterPositive-and$noWorse-and$growth-and$cagr-and$efficiency-and$risk-and$trades
$summary=foreach($name in @($controlName,$centerName)){$c=$by["$name|$continuous"];[pscustomobject][ordered]@{Candidate=$name;Role=$c.Role;OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;MiddleNetProfit=$by["$name|middle_2019_2022"].NetProfit;RecentNetProfit=$by["$name|recent_2023_2026"].NetProfit;ContinuousNetProfit=$c.NetProfit;TotalReturnPercent=$c.TotalReturnPercent;CagrPercent=$c.CagrPercent;ProfitFactor=$c.ProfitFactor;TotalTrades=$c.TotalTrades;MaxDrawdownPercent=$c.MaxDrawdownPercent;RecoveryFactor=$c.RecoveryFactor;ReturnDrawdown=$c.ReturnDrawdown}}
$summary|Export-Csv (Resolve-P $SummaryPath)-NoTypeInformation -Encoding ASCII
$decision=[pscustomobject][ordered]@{Status=if($passed){'MODEL4_GATE_PASSED'}else{'REJECTED_IN_MODEL4'};ReportsParsed=$results.Count;IdentityValidReports=$attestation.Count;TotalAttempts=$workers.Count;IdentityRefusals=@($workers|Where-Object{$_.Status-eq'ERROR'}).Count;AllCenterWindowsPositive=$allCenterPositive;CenterNoWorseEveryWindow=$noWorse;CenterGrowthGate=$growth;CenterCagrGate=$cagr;CenterEfficiencyGate=$efficiency;CenterRiskGate=$risk;CenterTradeCountGate=$trades;AnnualStressValidationPermitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit;SourceSha256=$sourceHash;BinarySha256=$binary;CenterProfileSha256=$center.ProfileSha256}
$decision|Export-Csv (Resolve-P $DecisionCsvPath)-NoTypeInformation -Encoding ASCII
$lines=[Collections.Generic.List[string]]::new();$lines.Add('# Strong-Signal Selective Lot-Cap Model 4 Decision');$lines.Add('');$lines.Add($(if($passed){'**Decision: MODEL 4 GATE PASSED. Annual and stress validation may open; promotion remains closed.**'}else{'**Decision: REJECTED IN MODEL 4. Annual/stress expansion, promotion, forward change, and live approval remain closed.**'}));$lines.Add('');$lines.Add("- Reports: ``$($results.Count) / 8``; attempts: ``$($workers.Count)``; refusals: ``$(@($workers|Where-Object{$_.Status-eq'ERROR'}).Count)``");$lines.Add("- Source: ``$sourceHash``; EX5: ``$binary``");$lines.Add('- XAUUSD, `$10,000`, Model 4 real ticks through `2026-07-18`; real trading disabled');$lines.Add('');$lines.Add('| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD |');$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');foreach($row in $summary){$label=if($row.Candidate-eq$centerName){'**Selective center**'}else{'Control'};$lines.Add("| $label | $(Money([double]$row.OlderNetProfit)) | $(Money([double]$row.MiddleNetProfit)) | $(Money([double]$row.RecentNetProfit)) | $(Money([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")};$lines.Add('');$lines.Add('## Frozen Gate');$lines.Add('');$lines.Add("- Center positive/no worse every era: ``$allCenterPositive / $noWorse`` ($(PassText($allCenterPositive-and$noWorse)))");$lines.Add("- Growth/CAGR: ``$growth / $cagr`` ($(PassText($growth-and$cagr)))");$lines.Add("- PF/recovery/return-DD: ``$efficiency`` ($(PassText $efficiency))");$lines.Add("- Drawdown/trades: ``$risk / $trades`` ($(PassText($risk-and$trades)))");$lines.Add('');$lines.Add($(if($passed){'This exact center must still pass annual restarts, execution-cost stress, Monte Carlo, hard-risk auditing, and broker variation before historical promotion can be considered.'}else{'No threshold or cap rescue is permitted from this result.'}));$lines.Add('');$lines.Add('ATB150 and the forward candidate remain unchanged; real trading remains disabled.');$lines|Set-Content (Resolve-P $DecisionMarkdownPath)-Encoding ASCII
Remove-Item (Resolve-P $rawResults),(Resolve-P $rawSummary),(Resolve-P $rawMetrics)-Force -ErrorAction SilentlyContinue
$decision
