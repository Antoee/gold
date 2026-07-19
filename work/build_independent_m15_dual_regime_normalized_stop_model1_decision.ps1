param(
   [string]$ManifestPath='outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_MANIFEST.csv',
   [string]$ReportDir='outputs\independent_m15_dual_regime_normalized_stop_model1_package\reports_here',
   [string]$ResultsPath='outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_RESULTS.csv',
   [string]$SummaryPath='outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath='outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_DECISION.md',
   [string]$RunAttestationPath='outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256='E6AB84CA7780A47FDE04A01CB74966204220B91B2DA97B65F1095066A10D2F50'
$expectedBinarySha256='7DB6E68B540055739E9D4F6F6A74B37358DE1F9B286E22684009ADCDFDC5D7D4'
$controlName='drns_fixed6';$candidateName='drns_pct030';$continuousWindow='continuous_2015_2026'
$eras=@('older_2015_2018','pre_2019_2020','transition_2021_2023','recent_2024_2026')
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){$sign=if($Value-ge 0){'+'}else{'-'};return $sign+'$'+[math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
function GateText([bool]$Value){if($Value){return 'PASS'};return 'FAIL'}

$manifest=@(Import-Csv (Resolve-RepoPath $ManifestPath))
if($manifest.Count-ne 25 -or @($manifest.Candidate|Sort-Object -Unique).Count-ne 5 -or @($manifest.Window|Sort-Object -Unique).Count-ne 5){throw 'Frozen manifest topology changed.'}
if(@($manifest|Where-Object{$_.SourceSha256-ne$expectedSourceSha256 -or [int]$_.Model-ne 1}).Count-ne 0){throw 'Manifest source/model identity changed.'}

$rawResults='work\DRNS_RAW_RESULTS.csv';$rawSummary='work\DRNS_RAW_SUMMARY.csv';$rawMetrics='work\DRNS_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics|Out-Null
if($LASTEXITCODE-ne 0){throw 'Shared report collector failed.'}
$raw=@(Import-Csv (Resolve-RepoPath $rawResults));if($raw.Count-ne 25 -or @($raw|Where-Object Status -ne 'PARSED').Count-ne 0){throw 'Expected 25 parsed reports.'}
$rawBy=@{};foreach($row in $raw){$rawBy[[string]$row.ExpectedReportName]=$row}

$attempts=[Collections.Generic.List[object]]::new()
foreach($pattern in @('INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_EXACT_?.csv','INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_RETRY_?.csv')){
   foreach($file in @(Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File|Sort-Object Name)){foreach($row in @(Import-Csv $file.FullName)){$attempts.Add($row)|Out-Null}}
}
$identityRetries=@($attempts|Where-Object{$_.Status-eq'ERROR' -and $_.Evidence-eq'Portable report does not embed the expected package-source identity.'}).Count
$workers=[Collections.Generic.List[object]]::new()
foreach($group in ($attempts|Group-Object QueueRank)){$valid=@($group.Group|Where-Object Status -eq 'REPORT_FOUND'|Sort-Object{[datetime]$_.Finished}-Descending);if($valid.Count-lt 1){throw "No valid attempt for rank $($group.Name)."};$workers.Add($valid[0])|Out-Null}
if($workers.Count-ne 25 -or @($workers|Where-Object{$_.PackageSourceSha256-ne$expectedSourceSha256 -or $_.PortableBinarySha256-ne$expectedBinarySha256 -or $_.PortableExpertRecompiled-ne'False'}).Count-ne 0){throw 'Runner identity mismatch.'}
$workerBy=@{};foreach($row in $workers){$workerBy[[string]$row.QueueRank]=$row}

$results=[Collections.Generic.List[object]]::new();$attestation=[Collections.Generic.List[object]]::new()
foreach($item in ($manifest|Sort-Object{[int]$_.QueueRank})){
   $parsed=$rawBy[[string]$item.ExpectedReportName];$run=$workerBy[[string]$item.QueueRank];if($null-eq$parsed-or$null-eq$run){throw "Missing rank $($item.QueueRank)."}
   $identity=Get-Content ([string]$run.ReportIdentityPath) -Raw|ConvertFrom-Json
   if($identity.SourceSha256-ne$expectedSourceSha256 -or $identity.PortableBinarySha256-ne$expectedBinarySha256 -or $identity.ReportSha256-ne$run.ReportSha256){throw "Sidecar mismatch rank $($item.QueueRank)."}
   $returnDD=if([double]$parsed.MaxDrawdownPercent-gt 0){[double]$parsed.TotalReturnPercent/[double]$parsed.MaxDrawdownPercent}else{0}
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;From=$item.From;To=$item.To;Model=1
      PriceNormalizedStopCap=$item.PriceNormalizedStopCap;MaximumStopPriceDistance=$item.MaximumStopPriceDistance
      MaximumStopPricePercent=$item.MaximumStopPricePercent;Promotable=$item.Promotable;ProfileSha256=$item.ProfileSha256
      SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256;Status=$parsed.Status
      NetProfit=[math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2)
      CagrPercent=[math]::Round([double]$parsed.CagrPercent,2);ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2)
      TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownMoney=[math]::Round([double]$parsed.MaxDrawdownMoney,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDD,4);ReportSha256=$run.ReportSha256
   })|Out-Null
   $rankAttempts=@($attempts|Where-Object QueueRank -eq $item.QueueRank).Count
   $attestation.Add([pscustomobject][ordered]@{QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status;Attempts=$rankAttempts;IdentityRetries=$rankAttempts-1;SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished})|Out-Null
}
$results|Export-Csv (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation|Export-Csv (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII
$by=@{};foreach($row in $results){$by["$($row.Candidate)|$($row.Window)"]=$row}
$control=$by["$controlName|$continuousWindow"];$candidate=$by["$candidateName|$continuousWindow"];$recent=$by["$candidateName|recent_2024_2026"]
function ProfilePass([string]$Name){$continuous=$by["$Name|$continuousWindow"];$recentRow=$by["$Name|recent_2024_2026"];return @($eras|Where-Object{[double]$by["$Name|$_"].NetProfit-le 0}).Count-eq 0 -and [double]$recentRow.ProfitFactor-ge 1.05 -and [double]$continuous.NetProfit-ge 1.25*[double]$control.NetProfit -and [double]$continuous.ProfitFactor-ge 1.25 -and [int]$continuous.TotalTrades-ge 300 -and [double]$continuous.MaxDrawdownPercent-le 2.00}
$centerPass=ProfilePass $candidateName;$lowerPass=ProfilePass 'drns_pct025';$upperPass=ProfilePass 'drns_pct035';$neighborPass=$lowerPass-or$upperPass;$passed=$centerPass-and$neighborPass
$order=@('drns_fixed6','drns_pct025','drns_pct030','drns_pct035','drns_atr_only')
$summary=foreach($name in $order){$c=$by["$name|$continuousWindow"];[pscustomobject][ordered]@{Candidate=$name;OlderNetProfit=$by["$name|older_2015_2018"].NetProfit;PreNetProfit=$by["$name|pre_2019_2020"].NetProfit;TransitionNetProfit=$by["$name|transition_2021_2023"].NetProfit;RecentNetProfit=$by["$name|recent_2024_2026"].NetProfit;ContinuousNetProfit=$c.NetProfit;TotalReturnPercent=$c.TotalReturnPercent;CagrPercent=$c.CagrPercent;ProfitFactor=$c.ProfitFactor;TotalTrades=$c.TotalTrades;MaxDrawdownPercent=$c.MaxDrawdownPercent;RecoveryFactor=$c.RecoveryFactor;ReturnDrawdown=$c.ReturnDrawdown;ProfileGatePass=if($name-in@('drns_pct025','drns_pct030','drns_pct035')){ProfilePass $name}else{$false}}}
$summary|Export-Csv (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$decision=[pscustomobject][ordered]@{Status=if($passed){'MODEL1_GATE_PASSED'}else{'REJECTED_IN_MODEL1'};ReportsParsed=25;IdentityValidReports=25;IdentityRetries=$identityRetries;CenterAllErasPositive=@($eras|Where-Object{[double]$by["$candidateName|$_"].NetProfit-le 0}).Count-eq 0;CenterRecentPositive=[double]$recent.NetProfit-gt 0;CenterRecentProfitFactorAtLeast1Point05=[double]$recent.ProfitFactor-ge 1.05;CenterContinuousNetAtLeastControlPlus25Percent=[double]$candidate.NetProfit-ge 1.25*[double]$control.NetProfit;CenterContinuousProfitFactorAtLeast1Point25=[double]$candidate.ProfitFactor-ge 1.25;CenterContinuousTradesAtLeast300=[int]$candidate.TotalTrades-ge 300;CenterDrawdownAtMost2Percent=[double]$candidate.MaxDrawdownPercent-le 2.0;LowerNeighborPass=$lowerPass;UpperNeighborPass=$upperPass;Model4Permitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit;CandidateNetProfit=$candidate.NetProfit;SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CandidateProfileSha256=$candidate.ProfileSha256}
$decision|Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$labels=@{drns_fixed6='Fixed $6 control';drns_pct025='Price cap 0.25%';drns_pct030='Price cap 0.30% center';drns_pct035='Price cap 0.35%';drns_atr_only='ATR-only diagnostic'}
$lines=[Collections.Generic.List[string]]::new();$lines.Add('# Independent M15 Dual-Regime Normalized-Stop Model 1 Decision');$lines.Add('');$lines.Add($(if($passed){'**Decision: MODEL 1 GATE PASSED. The fixed center and supporting neighbor may enter Model 4; no promotion is authorized.**'}else{'**Decision: REJECTED IN MODEL 1. No Model 4 run, portfolio integration, promotion, forward change, or live approval is permitted.**'}));$lines.Add('');$lines.Add("- Reports: ``25 / 25`` parsed and exact source/binary identity valid; identity retries: ``$identityRetries``");$lines.Add("- Source SHA-256: ``$expectedSourceSha256``");$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``");$lines.Add('- Real-account trading: disabled');$lines.Add('- Evidence class: historical structural repair; 2024-2026 is not untouched holdout data');$lines.Add('');$lines.Add('| Profile | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Gate |');$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|');foreach($row in $summary){$lines.Add("| $($labels[$row.Candidate]) | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.PreNetProfit)) | $(Money ([double]$row.TransitionNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ProfileGatePass) |")};$lines.Add('');$lines.Add('## Frozen Gate');$lines.Add('');$lines.Add('| Requirement | Result | Status |');$lines.Add('|---|---|---|');$lines.Add("| Center positive in all four eras | ``$($decision.CenterAllErasPositive)`` | $(GateText ([bool]$decision.CenterAllErasPositive)) |");$lines.Add("| Recent net > 0 | $(Money ([double]$recent.NetProfit)) | $(GateText ([bool]$decision.CenterRecentPositive)) |");$lines.Add("| Recent PF >= 1.05 | ``$($recent.ProfitFactor)`` | $(GateText ([bool]$decision.CenterRecentProfitFactorAtLeast1Point05)) |");$lines.Add("| Continuous net >= control +25% | $(Money ([double]$candidate.NetProfit)) vs required $(Money (1.25*[double]$control.NetProfit)) | $(GateText ([bool]$decision.CenterContinuousNetAtLeastControlPlus25Percent)) |");$lines.Add("| Continuous PF >= 1.25 | ``$($candidate.ProfitFactor)`` | $(GateText ([bool]$decision.CenterContinuousProfitFactorAtLeast1Point25)) |");$lines.Add("| Trades >= 300 | ``$($candidate.TotalTrades)`` | $(GateText ([bool]$decision.CenterContinuousTradesAtLeast300)) |");$lines.Add("| DD <= 2.00% | ``$($candidate.MaxDrawdownPercent)%`` | $(GateText ([bool]$decision.CenterDrawdownAtMost2Percent)) |");$lines.Add("| At least one adjacent percentage profile passes | lower=$lowerPass; upper=$upperPass | $(GateText $neighborPass) |");$lines.Add('');$lines.Add('## Interpretation');$lines.Add('');$lines.Add('The structural rewrite worked mechanically. The 0.30% center increased recent trades from 54 to 71, improved recent PF from `0.76` to `0.98`, reduced the recent loss from `-$66.41` to `-$7.93`, raised continuous net from `+$364.60` to `+$430.93`, and reduced continuous drawdown from `1.07%` to `1.01%.`');$lines.Add('');$lines.Add('It did not restore a positive recent edge. The center, upper neighbor, and ATR-only diagnostic all remained negative in 2024-2026, while the lower neighbor was worse. The center also missed the frozen +25% continuous-net hurdle. The fixed price ceiling was a real geometry weakness, but not the root cause of the signal-family decay.');$lines.Add('');$lines.Add('This family is rejected without Model 4 or portfolio integration. ATB150 remains the historical champion, and the registered forward candidate, invalid-account boundary, and real-account lock remain unchanged.');$lines|Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
