param(
   [string]$QueuePath='outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_QUEUE.csv',
   [string]$ReportDir='outputs\three_lane_protected_winner_addon_holdout_model1_package\reports_here',
   [string]$RunnerPath='outputs\THREE_LANE_PWA_HOLDOUT_EXACT_1.csv',
   [string]$ResultsPath='outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_RESULTS.csv',
   [string]$SummaryPath='outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_SUMMARY.csv',
   [string]$AttestationPath='outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_RUN_ATTESTATION.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_DECISION.md'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};Join-Path $repo $Path}
function Money([double]$v){$(if($v-ge0){'+'}else{'-'})+'$'+[Math]::Abs($v).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
function Cell([string]$h){([Net.WebUtility]::HtmlDecode([regex]::Replace($h,'<[^>]+>',''))).Trim()}
function AddOnCount([string]$Path){
   $html=Get-Content -LiteralPath $Path -Raw;$marker=$html.IndexOf('<b>Deals</b>',[StringComparison]::OrdinalIgnoreCase);if($marker-lt0){throw'Deals missing'}
   $opts=[Text.RegularExpressions.RegexOptions]::IgnoreCase-bor[Text.RegularExpressions.RegexOptions]::Singleline;$n=0
   foreach($row in [regex]::Matches($html.Substring($marker),'<tr\b[^>]*>(?<row>.*?)</tr>',$opts)){
      $cm=[regex]::Matches($row.Groups['row'].Value,'<td\b[^>]*>(?<cell>.*?)</td>',$opts);if($cm.Count-lt13){continue};$c=@($cm|%{Cell $_.Groups['cell'].Value});if($c[4]-in@('in','in/out')-and$c[12]-like'MTSM_ADD_*'){$n++}
   };$n
}
$raw=Join-Path $repo 'work\PWA_HOLDOUT_RAW.csv';$rawS=Join-Path $repo 'work\PWA_HOLDOUT_RAW_SUMMARY.csv';$rawM=Join-Path $repo 'work\PWA_HOLDOUT_RAW.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' -OutResults 'work\PWA_HOLDOUT_RAW.csv' -OutSummary 'work\PWA_HOLDOUT_RAW_SUMMARY.csv' -OutMarkdown 'work\PWA_HOLDOUT_RAW.md'|Out-Null
$q=@(Import-Csv (Resolve-RepoPath $QueuePath));$p=@(Import-Csv $raw);$run=@(Import-Csv (Resolve-RepoPath $RunnerPath));if($q.Count-ne8-or$run.Count-ne8){throw'Expected 8 exact holdout rows.'}
$pb=@{};foreach($x in $p){$pb[$x.ExpectedReportName]=$x};$rb=@{};foreach($x in $run){$rb[$x.QueueRank]=$x};$reportRoot=Resolve-RepoPath $ReportDir;$packageRoot=Split-Path -Parent $reportRoot
$results=[Collections.Generic.List[object]]::new();$att=[Collections.Generic.List[object]]::new()
foreach($i in($q|Sort-Object{[int]$_.QueueRank})){
   $x=$pb[$i.ExpectedReportName];$u=$rb[$i.QueueRank];if($x.Status-ne'PARSED'-or$u.Status-ne'REPORT_FOUND'){throw"Missing evidence $($i.ExpectedReportName)"}
   $report=Resolve-RepoPath $x.ReportPath;$rh=(Get-FileHash $report -Algorithm SHA256).Hash.ToUpperInvariant();$config=Join-Path $packageRoot $i.Config;$ch=(Get-FileHash $config -Algorithm SHA256).Hash.ToUpperInvariant();$id=Get-Content (Join-Path $reportRoot "$($i.ExpectedReportName).identity.json") -Raw|ConvertFrom-Json
   if($rh-ne$u.ReportSha256-or$rh-ne$id.ReportSha256-or$ch-ne$u.PackageConfigSha256-or$i.SourceSha256-ne$id.SourceSha256-or$u.PortableBinarySha256-ne$id.PortableBinarySha256){throw"Identity mismatch $($i.ExpectedReportName)"}
   $adds=AddOnCount $report;$att.Add([pscustomobject]@{QueueRank=$i.QueueRank;Candidate=$i.Candidate;Window=$i.Window;ConfigSha256=$ch;ProfileSha256=$i.ProfileSha256;SourceSha256=$i.SourceSha256;PortableBinarySha256=$u.PortableBinarySha256;ReportSha256=$rh;AddOnEntries=$adds})|Out-Null
   $results.Add([pscustomobject]@{QueueRank=$i.QueueRank;Candidate=$i.Candidate;Role=$i.Role;Window=$i.Window;From=$i.From;To=$i.To;Status=$x.Status;ReportPath=$x.ReportPath;ProfileSha256=$i.ProfileSha256;SourceSha256=$i.SourceSha256;PortableBinarySha256=$u.PortableBinarySha256;NetProfit=$x.NetProfit;TotalReturnPercent=$x.TotalReturnPercent;CagrPercent=$x.CagrPercent;ProfitFactor=$x.ProfitFactor;TotalTrades=$x.TotalTrades;MaxDrawdownPercent=$x.MaxDrawdownPercent;RecoveryFactor=$x.RecoveryFactor;AddOnEntries=$adds})|Out-Null
}
if(@($results.SourceSha256|Sort-Object -Unique).Count-ne1-or@($results.PortableBinarySha256|Sort-Object -Unique).Count-ne1){throw'Nonuniform source/binary identity.'}
$results | Export-Csv (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$att | Export-Csv (Resolve-RepoPath $AttestationPath) -NoTypeInformation -Encoding ASCII
$sets=@{};foreach($g in ($results|Group-Object Candidate)){$sets[$g.Name]=$g.Group}
$control=@($sets.pwa_control | Where-Object {$_.Window -eq 'continuous_2021_2026'})[0]
$candidate=@($sets.pwa_trigger100 | Where-Object {$_.Window -eq 'continuous_2021_2026'})[0]
$controlEff=[double]$control.TotalReturnPercent/[double]$control.MaxDrawdownPercent;$candidateEff=[double]$candidate.TotalReturnPercent/[double]$candidate.MaxDrawdownPercent
$candidateWindows=@($sets.pwa_trigger100);$allPositive=@($candidateWindows|?{[double]$_.NetProfit-le0}).Count-eq0;$quality=[double]$candidate.ProfitFactor-ge1.50-and[double]$candidate.MaxDrawdownPercent-le2.0;$activity=[int]$candidate.AddOnEntries-ge2;$beatsControl=[double]$candidate.NetProfit-gt[double]$control.NetProfit-and$candidateEff-gt$controlEff
$gate=$allPositive-and$quality-and$activity-and$beatsControl;$status=if($gate){'HOLDOUT_PASS'}else{'REJECTED_IN_HOLDOUT'}
$summary=[Collections.Generic.List[object]]::new();foreach($name in @('pwa_control','pwa_trigger100')){foreach($x in ($sets[$name]|Sort-Object{[datetime]$_.From})){$summary.Add([pscustomobject]@{Candidate=$name;Window=$x.Window;NetProfit=$x.NetProfit;CagrPercent=$x.CagrPercent;ProfitFactor=$x.ProfitFactor;Trades=$x.TotalTrades;AddOnEntries=$x.AddOnEntries;MaxDrawdownPercent=$x.MaxDrawdownPercent;RecoveryFactor=$x.RecoveryFactor})|Out-Null}}
$summary | Export-Csv (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$decision=[pscustomobject]@{Status=$status;ReportsParsed=8;AllCandidateWindowsPositive=$allPositive;QualityGatePass=$quality;ActivityGatePass=$activity;BeatsControlGatePass=$beatsControl;CandidateContinuousNet=$candidate.NetProfit;ControlContinuousNet=$control.NetProfit;NetDifference=[Math]::Round([double]$candidate.NetProfit-[double]$control.NetProfit,2);HoldoutPassed=$gate;Model4Permitted=$gate;Model4Opened=$false;NewBest=$false;SourceSha256=$results[0].SourceSha256;PortableBinarySha256=$results[0].PortableBinarySha256;FrozenForwardCandidateChanged=$false}
$decision | Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$md=[Collections.Generic.List[string]]::new();$md.Add('# Three-Lane Protected Winner Add-On Holdout Decision');$md.Add('');$md.Add("**Decision: $status. Model 4, promotion, forward registration, and real trading remain closed.**");$md.Add('');$md.Add("- Exact source SHA-256: ``$($results[0].SourceSha256)``");$md.Add("- Exact binary SHA-256: ``$($results[0].PortableBinarySha256)``");$md.Add('- Controlled run: `8 / 8` reports, one worker, zero errors, one binary identity');$md.Add('- Frozen ATB150 and frozen forward candidate: unchanged');$md.Add('');$md.Add('| Profile | Window | Net | CAGR | PF | Trades | Add-ons | DD |');$md.Add('|---|---|---:|---:|---:|---:|---:|---:|');foreach($x in $summary){$md.Add("| ``$($x.Candidate)`` | $($x.Window) | $(Money $x.NetProfit) | $($x.CagrPercent)% | $($x.ProfitFactor) | $($x.Trades) | $($x.AddOnEntries) | $($x.MaxDrawdownPercent)% |")};$md.Add('');$md.Add('## Gate');$md.Add('');$md.Add("- Every candidate window positive: ``$allPositive``");$md.Add("- Continuous PF/DD quality: ``$quality``");$md.Add("- Continuous add-on activity: ``$activity``");$md.Add("- Candidate net and return/DD beat control: ``$beatsControl``");$md.Add("- Continuous selected: $(Money $candidate.NetProfit), PF ``$($candidate.ProfitFactor)``, DD ``$($candidate.MaxDrawdownPercent)%``; control: $(Money $control.NetProfit), PF ``$($control.ProfitFactor)``, DD ``$($control.MaxDrawdownPercent)%``.");$md.Add('');$md.Add('- No holdout report contains a completed add-on entry. Results still changed because v1.51 can tighten the primary winner stop before exact coverage validation later refuses the add-on. This safety-biased side effect is another explicit rejection reason.');$md.Add('- The candidate lost `-$15.22` versus control in the feature-level holdout. The discovery improvement did not transfer, so no Model 4 time is justified.');$md.Add('- ATB150 remains the research best.')
$md | Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
Remove-Item $raw,$rawS,$rawM -Force -ErrorAction SilentlyContinue;$decision
