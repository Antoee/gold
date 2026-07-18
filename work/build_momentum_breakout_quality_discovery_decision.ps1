param(
   [string]$QueuePath = "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\momentum_breakout_quality_discovery_model1_package\reports_here",
   [string]$SourcePath = "work\Professional_XAUUSD_Momentum_Breakout_Quality_Portfolio.mq5",
   [string]$ResultsPath = "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\MOMENTUM_BREAKOUT_QUALITY_DISCOVERY_DECISION.md"
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){$(if($Value-ge0){'+'}else{'-'})+'$'+[math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
$rawPath = Join-Path $repo "work\MBQ_RAW_RESULTS.csv"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" -OutResults "work\MBQ_RAW_RESULTS.csv" -OutSummary "work\MBQ_RAW_SUMMARY.csv" -OutMarkdown "work\MBQ_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE-ne0){throw "Shared report collector failed."}
$queue=@(Import-Csv (Resolve-RepoPath $QueuePath));$raw=@(Import-Csv $rawPath)
$rawByReport=@{};foreach($row in $raw){$rawByReport[[string]$row.ExpectedReportName]=$row}
$sourceHash=(Get-FileHash (Resolve-RepoPath $SourcePath) -Algorithm SHA256).Hash
if(@($queue.SourceSha256|Sort-Object -Unique).Count-ne1-or$queue[0].SourceSha256-ne$sourceHash){throw "Queue/source identity mismatch."}
$results=[Collections.Generic.List[object]]::new()
foreach($item in ($queue|Sort-Object {[int]$_.QueueRank})){
   $parsed=$rawByReport[[string]$item.ExpectedReportName]
   if($null-eq$parsed-or$parsed.Status-ne"PARSED"){throw "Report did not parse: $($item.ExpectedReportName)"}
   $report=Resolve-RepoPath ([string]$parsed.ReportPath);$text=Get-Content $report -Raw
   $identity=$text.IndexOf($sourceHash,[StringComparison]::OrdinalIgnoreCase)-ge0-and$text.IndexOf('InpMOUseBreakoutCandleQuality=',[StringComparison]::Ordinal)-ge0-and$text.IndexOf('InpMOUseTickVolumeConfirmation=',[StringComparison]::Ordinal)-ge0
   if(!$identity){throw "Report identity failed: $($item.ExpectedReportName)"}
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;From=$item.From;To=$item.To;Model=$item.Model;Deposit=$item.Deposit
      ExpectedReportName=$item.ExpectedReportName;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;ContractSha256=$item.ContractSha256
      QualityEnabled=$item.QualityEnabled;MinimumBodyPercent=$item.MinimumBodyPercent;MinimumCloseLocation=$item.MinimumCloseLocation
      MinimumRangeATR=$item.MinimumRangeATR;VolumeEnabled=$item.VolumeEnabled;MinimumVolumeRatio=$item.MinimumVolumeRatio
      Status=$parsed.Status;ReportSha256=(Get-FileHash $report -Algorithm SHA256).Hash;ReportSourceIdentityPass=$identity
      ReportDisposition=$(if([int]$item.QueueRank-in2,3){'REPRODUCED_AFTER_IDENTITY_RETRY'}else{'FIRST_VALID_EXPORT'})
      InitialDeposit=$parsed.InitialDeposit;NetProfit=$parsed.NetProfit;TotalReturnPercent=$parsed.TotalReturnPercent;CagrPercent=$parsed.CagrPercent
      ProfitFactor=$parsed.ProfitFactor;TotalTrades=$parsed.TotalTrades;MaxDrawdownPercent=$parsed.MaxDrawdownPercent;RecoveryFactor=$parsed.RecoveryFactor
   })|Out-Null
}
if($results.Count-ne21){throw "Expected 21 parsed reports."}
$results|Export-Csv (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$sets=@{};foreach($group in ($results|Group-Object Candidate)){
   $sets[$group.Name]=[pscustomobject]@{
      Older=$group.Group|Where-Object Window -eq 'older_2015_2018'|Select-Object -First 1
      Repair=$group.Group|Where-Object Window -eq 'repair_2019_2020'|Select-Object -First 1
      Continuous=$group.Group|Where-Object Window -eq 'continuous_2015_2020'|Select-Object -First 1
   }
}
$control=$sets['mbq_fixed_control'].Continuous
$controlEfficiency=[double]$control.TotalReturnPercent/[double]$control.MaxDrawdownPercent
$adjacency=@{
   mbq_fixed_control=@();mbq_price_loose=@('mbq_price_center');mbq_price_center=@('mbq_price_loose','mbq_price_strict');mbq_price_strict=@('mbq_price_center')
   mbq_center_vol090=@('mbq_center_vol100');mbq_center_vol100=@('mbq_center_vol090','mbq_center_vol110');mbq_center_vol110=@('mbq_center_vol100')
}
$basic=@{};$quality=@{}
foreach($name in $sets.Keys){
   $set=$sets[$name];$continuous=$set.Continuous
   $basic[$name]=$name-ne'mbq_fixed_control'-and[double]$set.Older.NetProfit-gt0-and[double]$set.Repair.NetProfit-gt0-and[double]$continuous.ProfitFactor-ge1.45-and[int]$continuous.TotalTrades-ge150-and[double]$continuous.MaxDrawdownPercent-le2.80-and[double]$continuous.NetProfit-ge[double]$control.NetProfit*0.85
   $efficiency=[double]$continuous.TotalReturnPercent/[double]$continuous.MaxDrawdownPercent
   $quality[$name]=$efficiency-ge$controlEfficiency*1.05-or([double]$continuous.ProfitFactor-ge[double]$control.ProfitFactor+0.05-and[double]$continuous.MaxDrawdownPercent-le[double]$control.MaxDrawdownPercent)
}
$summary=[Collections.Generic.List[object]]::new()
foreach($name in ($sets.Keys|Sort-Object)){
   $set=$sets[$name];$continuous=$set.Continuous
   $neighbors=@($adjacency[$name]|Where-Object{$basic[$_]-and$quality[$_]})
   $eligible=$basic[$name]-and$quality[$name]-and$neighbors.Count-gt0
   $summary.Add([pscustomobject]@{
      Candidate=$name;OlderNetProfit=$set.Older.NetProfit;RepairNetProfit=$set.Repair.NetProfit;ContinuousNetProfit=$continuous.NetProfit
      ContinuousReturnPercent=$continuous.TotalReturnPercent;ContinuousCagrPercent=$continuous.CagrPercent;ContinuousProfitFactor=$continuous.ProfitFactor
      ContinuousTrades=$continuous.TotalTrades;ContinuousMaxDrawdownPercent=$continuous.MaxDrawdownPercent
      ReturnDrawdown=[math]::Round([double]$continuous.TotalReturnPercent/[double]$continuous.MaxDrawdownPercent,4)
      BasicGatePass=$basic[$name];QualityGatePass=$quality[$name];AdjacentPass=$neighbors.Count-gt0;PassingNeighbors=$neighbors-join';'
      Decision=$(if($eligible){'DISCOVERY_ELIGIBLE'}elseif($name-eq'mbq_fixed_control'){'CONTROL_ONLY'}else{'REJECT_BEFORE_HOLDOUT'})
   })|Out-Null
}
$summary|Export-Csv (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$eligible=@($summary | Where-Object Decision -eq 'DISCOVERY_ELIGIBLE')
$status=if($eligible.Count-gt0){'DISCOVERY_ELIGIBLE'}else{'REJECTED_IN_DISCOVERY'}
$decision=[pscustomobject]@{Status=$status;Profiles=$summary.Count;ReportsParsed=$results.Count;EligibleProfiles=$eligible.Count;HoldoutOpened=$false;SourceSha256=$sourceHash;ContractSha256=$queue[0].ContractSha256;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false}
$decision|Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$md=[Collections.Generic.List[string]]::new();$md.Add('# Momentum Breakout Quality Discovery Decision');$md.Add('');$md.Add("**Decision: $($status.Replace('_',' ')). The frozen forward candidate and real-account lock are unchanged.**");$md.Add('');$md.Add("- Exact source: ``$sourceHash``");$md.Add("- Reports parsed: ``$($results.Count) / 21``; identity retries: ``2``");$md.Add("- Discovery-eligible profiles: ``$($eligible.Count)``");$md.Add('');$md.Add('| Profile | Older net | 2019-20 net | Continuous net | Return | PF | Trades | DD | Return/DD | Basic | Quality | Neighbor | Decision |');$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|')
foreach($row in $summary){$md.Add("| ``$($row.Candidate)`` | $(Money $row.OlderNetProfit) | $(Money $row.RepairNetProfit) | $(Money $row.ContinuousNetProfit) | $($row.ContinuousReturnPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ReturnDrawdown) | $($row.BasicGatePass) | $($row.QualityGatePass) | $($row.AdjacentPass) | $($row.Decision) |")}
$bestCandidate=$summary|Where-Object Candidate -ne 'mbq_fixed_control'|Sort-Object {[double]$_.ContinuousNetProfit} -Descending|Select-Object -First 1
$bestRepair=$summary|Where-Object Candidate -ne 'mbq_fixed_control'|Sort-Object {[double]$_.RepairNetProfit} -Descending|Select-Object -First 1
$md.Add('');$md.Add('## Interpretation');$md.Add('');$md.Add("- Highest non-control continuous net: ``$($bestCandidate.Candidate)`` at $(Money $bestCandidate.ContinuousNetProfit), PF ``$($bestCandidate.ContinuousProfitFactor)``, versus control $(Money $control.NetProfit), PF ``$($control.ProfitFactor)``.");$md.Add("- No filter repaired 2019-2020. The least-negative candidate was ``$($bestRepair.Candidate)`` at $(Money $bestRepair.RepairNetProfit), versus control $(Money $sets['mbq_fixed_control'].Repair.NetProfit).");$md.Add('- Tick-volume confirmation reduced activity and did not improve the weak era. Recent data therefore remains unopened.')
$md.Add('');if($eligible.Count-gt0){$md.Add('Only the named eligible profiles may enter the separately packaged 2021-2026 holdout. No Model4 or candidate promotion is authorized.')}else{$md.Add('The family is closed before post-2020 holdout and Model4. No threshold may be changed after seeing this decision.')};$md.Add('');$md.Add('This discovery result is not forward evidence and is not a real-money approval.');$md|Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
$decision
