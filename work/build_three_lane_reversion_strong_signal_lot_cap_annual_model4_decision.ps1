[CmdletBinding()]
param(
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_MANIFEST.csv',
   [string]$ReportDir='outputs\three_lane_reversion_strong_signal_lot_cap_annual_model4_package\reports_here',
   [string]$ContractPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_CONTRACT.md',
   [string]$CompileAuditPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_COMPILE_AUDIT.csv',
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_RESULTS.csv',
   [string]$SummaryPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_SUMMARY.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_DECISION.md',
   [string]$RunAttestationPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_RUN_ATTESTATION.csv'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceHash='C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$controlHash='AD0289B7A96150C930B54A2C44845C11DF05D42FD9A8D8DE4FA2703C308697F6'
$centerHash='A0099C6701311BAE105F29909166358D4D30050593318F340AD8F3B932F65F04'
$controlName='sslc_control';$centerName='sslc_center015'
function Resolve-P([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){$sign=if($Value-ge 0){'+'}else{'-'};return $sign+'$'+[Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}

$manifest=@(Import-Csv (Resolve-P $ManifestPath));$audit=Import-Csv (Resolve-P $CompileAuditPath)
if($manifest.Count-ne 24){throw 'Expected 24 annual Model 4 rows.'}
if($audit.Status-ne'COMPILE_PASS'-or$audit.SourceSha256-ne$sourceHash-or$audit.CompileErrors-ne'0'-or$audit.CompileWarnings-ne'0'){throw 'Compile audit invalid.'}
$binary=[string]$audit.PortableBinarySha256
$contractHash=(Get-FileHash -LiteralPath (Resolve-P $ContractPath) -Algorithm SHA256).Hash
foreach($item in $manifest){
   if($item.SourceSha256-ne$sourceHash-or[int]$item.Model-ne 4-or$item.AnnualContractSha256-ne$contractHash){throw 'Manifest identity changed.'}
   $expectedProfile=if($item.Candidate-eq$controlName){$controlHash}elseif($item.Candidate-eq$centerName){$centerHash}else{throw "Unexpected candidate $($item.Candidate)."}
   if($item.ProfileSha256-ne$expectedProfile){throw "Profile mismatch at rank $($item.QueueRank)."}
   if((Get-FileHash -LiteralPath (Resolve-P ([string]$item.PackageConfig)) -Algorithm SHA256).Hash-ne$item.ConfigSha256){throw "Config changed at rank $($item.QueueRank)."}
}

$rawResults='work\SSLC_ANNUAL_M4_RAW_RESULTS.csv';$rawSummary='work\SSLC_ANNUAL_M4_RAW_SUMMARY.csv';$rawMetrics='work\SSLC_ANNUAL_M4_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics|Out-Null
if($LASTEXITCODE-ne 0){throw 'Collector failed.'}
$raw=@(Import-Csv (Resolve-P $rawResults));if($raw.Count-ne 24-or@($raw|Where-Object{$_.Status-ne'PARSED'}).Count){throw 'Expected 24 parsed reports.'}
$rawBy=@{};foreach($row in $raw){$rawBy[[string]$row.ExpectedReportName]=$row}
$workers=[Collections.Generic.List[object]]::new()
foreach($pattern in @('THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_EXACT_?.csv','THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_ANNUAL_MODEL4_RETRY_?.csv')){
   foreach($file in Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File -ErrorAction SilentlyContinue){foreach($row in @(Import-Csv $file.FullName)){$workers.Add($row)|Out-Null}}
}
if($workers.Count-lt 24-or@($workers|Where-Object{$_.PackageSourceSha256-ne$sourceHash-or$_.PortableExpertRecompiled-ne'False'-or($_.Status-eq'REPORT_FOUND'-and$_.PortableBinarySha256-ne$binary)}).Count){throw 'Runner identity invalid.'}
$validBy=@{}
foreach($rank in 1..24){
   $attempts=@($workers|Where-Object{[int]$_.QueueRank-eq$rank});$valid=@($attempts|Where-Object{$_.Status-eq'REPORT_FOUND'})
   if($valid.Count-ne 1){throw "Rank $rank valid count $($valid.Count)."}
   $validBy[[string]$rank]=$valid[0]
}

$results=[Collections.Generic.List[object]]::new();$attestation=[Collections.Generic.List[object]]::new()
foreach($item in $manifest|Sort-Object{[int]$_.QueueRank}){
   $parsed=$rawBy[[string]$item.ExpectedReportName];$run=$validBy[[string]$item.QueueRank]
   $identity=Get-Content -LiteralPath ([string]$run.ReportIdentityPath) -Raw|ConvertFrom-Json
   if($identity.SourceSha256-ne$sourceHash-or$identity.PortableBinarySha256-ne$binary-or$identity.ReportSha256-ne$run.ReportSha256-or$identity.ConfigSha256-ne$run.PackageConfigSha256){throw "Sidecar mismatch at rank $($item.QueueRank)."}
   $results.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window;From=$item.From;To=$item.To;Model=4;ProfileSha256=$item.ProfileSha256;SourceSha256=$sourceHash;BinarySha256=$binary;AnnualContractSha256=$contractHash;NetProfit=[math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2);ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2);RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses;ReportSha256=$run.ReportSha256})|Out-Null
   $attempts=@($workers|Where-Object{[int]$_.QueueRank-eq[int]$item.QueueRank})
   $attestation.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status;Attempts=$attempts.Count;IdentityRetries=@($attempts|Where-Object{$_.Status-eq'ERROR'}).Count;SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished})|Out-Null
}
$results|Export-Csv (Resolve-P $ResultsPath)-NoTypeInformation -Encoding ASCII
$attestation|Export-Csv (Resolve-P $RunAttestationPath)-NoTypeInformation -Encoding ASCII

$centerRows=@($results|Where-Object{$_.Candidate-eq$centerName}|Sort-Object From)
$controlRows=@($results|Where-Object{$_.Candidate-eq$controlName}|Sort-Object From)
$by=@{};foreach($row in $results){$by["$($row.Candidate)|$($row.Window)"]=$row}
$paired=[Collections.Generic.List[object]]::new();$noWorseYears=0
foreach($center in $centerRows){
   $control=$by["$controlName|$($center.Window)"];$noWorse=[double]$center.NetProfit-ge[double]$control.NetProfit;if($noWorse){$noWorseYears++}
   $paired.Add([pscustomobject][ordered]@{Window=$center.Window;ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit;Increment=[math]::Round([double]$center.NetProfit-[double]$control.NetProfit,2);CenterProfitFactor=$center.ProfitFactor;CenterTrades=$center.TotalTrades;CenterDrawdownPercent=$center.MaxDrawdownPercent;CenterMaxConsecutiveLosses=$center.MaxConsecutiveLosses;CenterPositive=([double]$center.NetProfit-gt 0);CenterNoWorse=$noWorse})|Out-Null
}
$controlNet=[math]::Round([double](($controlRows|Measure-Object NetProfit -Sum).Sum),2);$centerNet=[math]::Round([double](($centerRows|Measure-Object NetProfit -Sum).Sum),2)
$controlTrades=[int](($controlRows|Measure-Object TotalTrades -Sum).Sum);$centerTrades=[int](($centerRows|Measure-Object TotalTrades -Sum).Sum)
$allPositive=@($centerRows|Where-Object{[double]$_.NetProfit-le 0}).Count-eq 0
$pairGate=$noWorseYears-ge 10;$growthGate=$centerNet-ge[math]::Round(1.10*$controlNet,2);$activityGate=$centerTrades-ge$controlTrades-2
$drawdownGate=@($centerRows|Where-Object{[double]$_.MaxDrawdownPercent-gt 1.50}).Count-eq 0
$lossStreakGate=@($centerRows|Where-Object{[int]$_.MaxConsecutiveLosses-gt 8}).Count-eq 0
$passed=$allPositive-and$pairGate-and$growthGate-and$activityGate-and$drawdownGate-and$lossStreakGate
$summary=@(
   [pscustomobject][ordered]@{Candidate=$controlName;Role='exact_control';SummedAnnualNet=$controlNet;SummedTrades=$controlTrades;PositiveYears=@($controlRows|Where-Object{[double]$_.NetProfit-gt 0}).Count;WorstYearNet=[math]::Round([double](($controlRows|Measure-Object NetProfit -Minimum).Minimum),2);WorstAnnualDrawdownPercent=[math]::Round([double](($controlRows|Measure-Object MaxDrawdownPercent -Maximum).Maximum),2)},
   [pscustomobject][ordered]@{Candidate=$centerName;Role='frozen_center';SummedAnnualNet=$centerNet;SummedTrades=$centerTrades;PositiveYears=@($centerRows|Where-Object{[double]$_.NetProfit-gt 0}).Count;WorstYearNet=[math]::Round([double](($centerRows|Measure-Object NetProfit -Minimum).Minimum),2);WorstAnnualDrawdownPercent=[math]::Round([double](($centerRows|Measure-Object MaxDrawdownPercent -Maximum).Maximum),2)}
)
$summary|Export-Csv (Resolve-P $SummaryPath)-NoTypeInformation -Encoding ASCII
$decision=[pscustomobject][ordered]@{Status=if($passed){'ANNUAL_GATE_PASSED'}else{'REJECTED_IN_ANNUAL_GATE'};ReportsParsed=$results.Count;TotalAttempts=$workers.Count;IdentityRefusals=@($workers|Where-Object{$_.Status-eq'ERROR'}).Count;AllCenterYearsPositive=$allPositive;CenterNoWorseYears=$noWorseYears;PairedYearGate=$pairGate;SummedGrowthGate=$growthGate;ActivityGate=$activityGate;AnnualDrawdownGate=$drawdownGate;LossStreakGate=$lossStreakGate;CostMonteCarloPermitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlSummedAnnualNet=$controlNet;CenterSummedAnnualNet=$centerNet;ControlSummedTrades=$controlTrades;CenterSummedTrades=$centerTrades;SourceSha256=$sourceHash;BinarySha256=$binary;CenterProfileSha256=$centerHash;AnnualContractSha256=$contractHash}
$decision|Export-Csv (Resolve-P $DecisionCsvPath)-NoTypeInformation -Encoding ASCII
$lines=[Collections.Generic.List[string]]::new();$lines.Add('# Strong-Signal Selective Lot-Cap Annual Model 4 Decision');$lines.Add('');$lines.Add($(if($passed){'**Decision: ANNUAL GATE PASSED. Exact ledger cost and Monte Carlo stress may open; promotion remains closed.**'}else{'**Decision: REJECTED IN ANNUAL GATE. Cost/Monte Carlo expansion, promotion, forward change, and live approval remain closed.**'}));$lines.Add('');$lines.Add("- Reports: ``$($results.Count) / 24``; attempts: ``$($workers.Count)``; refusals: ``$(@($workers|Where-Object{$_.Status-eq'ERROR'}).Count)``");$lines.Add("- Control summed annual score: ``$(Money $controlNet)`` on ``$controlTrades`` trades");$lines.Add("- Center summed annual score: ``$(Money $centerNet)`` on ``$centerTrades`` trades");$lines.Add("- Center no-worse years: ``$noWorseYears / 12``");$lines.Add('');$lines.Add('| Year | Control | Center | Increment | Center PF | Trades | DD | Loss streak | Positive | No worse |');$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');foreach($row in $paired){$lines.Add("| ``$($row.Window)`` | $(Money([double]$row.ControlNetProfit)) | $(Money([double]$row.CenterNetProfit)) | $(Money([double]$row.Increment)) | $($row.CenterProfitFactor) | $($row.CenterTrades) | $($row.CenterDrawdownPercent)% | $($row.CenterMaxConsecutiveLosses) | $($row.CenterPositive) | $($row.CenterNoWorse) |")};$lines.Add('');$lines.Add('## Frozen Gate');$lines.Add('');$lines.Add("- All center years positive: ``$allPositive``");$lines.Add("- At least 10 no-worse years: ``$pairGate``");$lines.Add("- Summed annual net at least 110% of control: ``$growthGate``");$lines.Add("- Activity preserved: ``$activityGate``");$lines.Add("- Every annual DD at most 1.50%: ``$drawdownGate``");$lines.Add("- Every loss streak at most eight: ``$lossStreakGate``");$lines.Add('');$lines.Add($(if($passed){'This result permits exact continuous-report trade-ledger stress. Broker variation and valid forward evidence remain required before any live-readiness claim.'}else{'The selective candidate is not promoted and no post-result threshold rescue is permitted.'}));$lines.Add('');$lines.Add('The registered forward candidate is unchanged and real trading remains disabled.');$lines|Set-Content (Resolve-P $DecisionMarkdownPath)-Encoding ASCII
$paired|Export-Csv (Resolve-P ($DecisionCsvPath -replace '\.csv$','_YEARS.csv'))-NoTypeInformation -Encoding ASCII
Remove-Item (Resolve-P $rawResults),(Resolve-P $rawSummary),(Resolve-P $rawMetrics)-Force -ErrorAction SilentlyContinue
$decision
