param(
   [string]$QueuePath="outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_QUEUE.csv",
   [string]$ReportDir="outputs\rc2_momentum_risk_extension_model4_package\reports_here",
   [string]$ResultsPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_RESULTS.csv",
   [string]$SummaryPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_SUMMARY.csv",
   [string]$DecisionCsvPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_DECISION.csv",
   [string]$DecisionMarkdownPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_DECISION.md"
)
$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path;$controlNet=1615.36
function Resolve-RepoPath([string]$p){if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $repo $p}
function Money([double]$v){$(if($v-ge 0){'+'}else{'-'})+'$'+[math]::Abs($v).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)}
$rawResults="work\MRE_M4_RAW_RESULTS.csv";$rawSummary="work\MRE_M4_RAW_SUMMARY.csv";$rawMetrics="work\MRE_M4_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics|Out-Null
if($LASTEXITCODE-ne 0){throw "Shared report collector failed."}
$queue=@(Import-Csv (Resolve-RepoPath $QueuePath));$raw=@(Import-Csv (Resolve-RepoPath $rawResults));$rawBy=@{};foreach($row in $raw){$rawBy[[string]$row.ExpectedReportName]=$row}
$runnerBy=@{};foreach($path in @(Get-ChildItem (Join-Path $repo "outputs") -Filter "RC2_MOMENTUM_RISK_MODEL4_*.csv" -ErrorAction SilentlyContinue|Sort-Object LastWriteTime)){foreach($row in @(Import-Csv $path.FullName)){$runnerBy[[string]$row.QueueRank]=$row}}
$results=[Collections.Generic.List[object]]::new()
foreach($item in ($queue|Sort-Object{[int]$_.QueueRank})) {
   $x=$rawBy[[string]$item.ExpectedReportName];$run=$runnerBy[[string]$item.QueueRank]
   if($null-eq$x -or $null-eq$run){throw "Evidence missing for rank $($item.QueueRank)."}
   $results.Add([pscustomobject]@{QueueRank=$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window;ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;MORiskPercent=$item.MORiskPercent;Status=$x.Status;ReportPath=$x.ReportPath;InitialDeposit=$x.InitialDeposit;NetProfit=$x.NetProfit;Balance=$x.Balance;TotalReturnPercent=$x.TotalReturnPercent;AnnualizedReturnPercent=$x.AnnualizedReturnPercent;CagrPercent=$x.CagrPercent;ProfitFactor=$x.ProfitFactor;ExpectedPayoff=$x.ExpectedPayoff;TotalTrades=$x.TotalTrades;MaxDrawdownPercent=$x.MaxDrawdownPercent;RecoveryFactor=$x.RecoveryFactor;SharpeRatio=$x.SharpeRatio;RunnerStatus=$run.Status;RunnerEvidence=$run.Evidence})|Out-Null
}
if($results.Count-ne 12 -or @($results|Where-Object{$_.Status-ne"PARSED" -or $_.RunnerStatus-ne"REPORT_FOUND"}).Count-ne 0){throw "Expected 12 parsed identity-valid reports."}
$results|Export-Csv (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$groups=@{};foreach($group in ($results|Group-Object Candidate)){$by=@{};foreach($row in $group.Group){$by[[string]$row.Window]=$row};$groups[$group.Name]=$by}
$broad=@("older_2015_2018","middle_2019_2022","recent_2023_2026")
function CenterPass([string]$name){$g=$groups[$name];$c=$g["continuous_2015_2026"];@($broad|Where-Object{[double]$g[$_].NetProfit-le 0}).Count-eq 0 -and [double]$c.NetProfit-ge 1.10*$controlNet -and [double]$c.ProfitFactor-ge 1.50 -and [int]$c.TotalTrades-ge 340 -and [double]$c.MaxDrawdownPercent-le 4.00 -and [double]$c.RecoveryFactor-ge 4.00}
function NeighborPass([string]$name){$g=$groups[$name];$c=$g["continuous_2015_2026"];@($broad|Where-Object{[double]$g[$_].NetProfit-le 0}).Count-eq 0 -and [double]$c.NetProfit-ge 1.05*$controlNet -and [double]$c.ProfitFactor-ge 1.45 -and [int]$c.TotalTrades-ge 340 -and [double]$c.MaxDrawdownPercent-le 4.25 -and [double]$c.RecoveryFactor-ge 3.75}
$center=CenterPass "mre_mo020_center";$lower=NeighborPass "mre_mo0175";$upper=NeighborPass "mre_mo0225";$passed=$center-and$lower-and$upper
$summary=[Collections.Generic.List[object]]::new();foreach($name in ($groups.Keys|Sort-Object)){$g=$groups[$name];$c=$g["continuous_2015_2026"];$gate=if($name-eq"mre_mo020_center"){$center}elseif($name-eq"mre_mo0175"){$lower}else{$upper};$summary.Add([pscustomobject]@{Candidate=$name;Role=$c.Role;MORiskPercent=$c.MORiskPercent;OlderNetProfit=$g["older_2015_2018"].NetProfit;MiddleNetProfit=$g["middle_2019_2022"].NetProfit;RecentNetProfit=$g["recent_2023_2026"].NetProfit;ContinuousNetProfit=$c.NetProfit;TotalReturnPercent=$c.TotalReturnPercent;AnnualizedReturnPercent=$c.AnnualizedReturnPercent;CagrPercent=$c.CagrPercent;ImprovementPercent=[math]::Round(100*([double]$c.NetProfit-$controlNet)/$controlNet,3);ProfitFactor=$c.ProfitFactor;Trades=$c.TotalTrades;MaxDrawdownPercent=$c.MaxDrawdownPercent;RecoveryFactor=$c.RecoveryFactor;GatePass=$gate})|Out-Null}
$summary|Export-Csv (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$centerProfileSha256=$groups["mre_mo020_center"]["continuous_2015_2026"].ProfileSha256
$publishedProfile=Resolve-RepoPath "outputs\RC2_MOMENTUM_RISK_EXTENSION_RESEARCH_PROFILE.set"
if($passed) {
   $centerProfileSource=Resolve-RepoPath "outputs\rc2_momentum_risk_extension_model4_package\profiles\mre_mo020_center_model4.set"
   if((Get-FileHash $centerProfileSource -Algorithm SHA256).Hash-ne$centerProfileSha256){throw "Center profile source identity changed."}
   Copy-Item -LiteralPath $centerProfileSource -Destination $publishedProfile -Force
} else {
   Remove-Item -LiteralPath $publishedProfile -Force -ErrorAction SilentlyContinue
}
$decision=[pscustomobject]@{Status=$(if($passed){"MODEL4_GATE_PASSED"}else{"REJECTED_IN_MODEL4"});ReportsParsed=12;CenterPass=$center;LowerNeighborPass=$lower;UpperNeighborPass=$upper;ResearchPromotionPermitted=$passed;ForwardCandidateChanged=$false;ControlNetProfit=$controlNet;CenterNetProfit=[double]$groups["mre_mo020_center"]["continuous_2015_2026"].NetProfit;CenterProfileSha256=$centerProfileSha256;SourceSha256=$queue[0].SourceSha256}
$decision|Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$md=[Collections.Generic.List[string]]::new();$md.Add("# RC2 Momentum-Risk Extension Model4 Decision");$md.Add("");$md.Add($(if($passed){"**Decision: MODEL4 GATE PASSED. The 0.20% center is a research promotion; the frozen forward candidate remains unchanged.**"}else{"**Decision: REJECTED IN MODEL4. No research promotion, forward change, or live approval is permitted.**"}));$md.Add("");$md.Add("- Exact-source Model4 control: ``$(Money $controlNet)``");$md.Add("- Center profile SHA-256: ``$centerProfileSha256``");$md.Add("- Source SHA-256: ``$($queue[0].SourceSha256)``");$md.Add("- Reports: ``12 / 12`` parsed and source-identity valid");$md.Add("- Center: ``$center``; lower neighbor: ``$lower``; upper neighbor: ``$upper``");$md.Add("");$md.Add("| Profile | MOM risk | 2015-18 | 2019-22 | 2023-26 | Continuous | Total | CAGR | Improvement | PF | Trades | DD | Recovery | Gate |");$md.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|");foreach($row in ($summary|Sort-Object{[double]$_.MORiskPercent})){$md.Add("| ``$($row.Candidate)`` | $($row.MORiskPercent)% | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ImprovementPercent)% | $($row.ProfitFactor) | $($row.Trades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.GatePass) |")};$md.Add("");$md.Add("The registered candidate, forward evidence, account contract, and real-account lock remain unchanged.");$md|Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
$decision
