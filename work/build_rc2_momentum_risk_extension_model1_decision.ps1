param(
   [string]$QueuePath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\rc2_momentum_risk_extension_model1_package\reports_here",
   [string]$ResultsPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_DECISION.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path }
function Format-Money([double]$Value) { return $(if($Value-ge 0){'+'}else{'-'})+'$'+[math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture) }

$rawResults = "work\MRE_RAW_RESULTS.csv"
$rawSummary = "work\MRE_RAW_SUMMARY.csv"
$rawMetrics = "work\MRE_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}
$runnerPaths = @(
   Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "RC2_MOMENTUM_RISK_PORTABLE_*.csv" -ErrorAction SilentlyContinue
   Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "RC2_MOMENTUM_RISK_RERUN_*.csv" -ErrorAction SilentlyContinue
) | Sort-Object LastWriteTime
foreach($path in $runnerPaths) {
   foreach($row in (Import-Csv -LiteralPath $path.FullName)) { $runnerByRank[[string]$row.QueueRank] = $row }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object {[int]$_.QueueRank})) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   if($null -eq $parsed) { throw "Collector row missing: $($item.ExpectedReportName)" }
   $runner = $runnerByRank[[string]$item.QueueRank]
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256
      RVRiskPercent=$item.RVRiskPercent;MORiskPercent=$item.MORiskPercent;PortfolioOpenRiskPercent=$item.PortfolioOpenRiskPercent
      Status=$parsed.Status;ReportPath=$parsed.ReportPath;InitialDeposit=$parsed.InitialDeposit;CalendarDays=$parsed.CalendarDays
      NetProfit=$parsed.NetProfit;Balance=$parsed.Balance;TotalReturnPercent=$parsed.TotalReturnPercent
      AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent;CagrPercent=$parsed.CagrPercent;ProfitFactor=$parsed.ProfitFactor
      ExpectedPayoff=$parsed.ExpectedPayoff;SharpeRatio=$parsed.SharpeRatio;WinRatePercent=$parsed.WinRatePercent
      TotalTrades=$parsed.TotalTrades;MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses
      MaxDrawdownMoney=$parsed.MaxDrawdownMoney;MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      RecoveryFactor=$parsed.RecoveryFactor;RunnerStatus=$runner.Status;RunnerEvidence=$runner.Evidence
   }) | Out-Null
}
if($results.Count -ne 28 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 28 parsed reports." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$groups = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $byWindow = @{}
   foreach($row in $group.Group) { $byWindow[[string]$row.Window] = $row }
   $groups[$group.Name] = $byWindow
}
$controlName = "mre_mo015_control"
$centerName = "mre_mo020_center"
$control = $groups[$controlName]
$controlContinuous = [double]$control["continuous_2015_2026"].NetProfit
$broad = @("older_2015_2018","middle_2019_2022","recent_2023_2026")

function Test-Center([string]$Name) {
   $g=$groups[$Name];$c=$g["continuous_2015_2026"]
   return @($broad | Where-Object {[double]$g[$_].NetProfit -lt [double]$control[$_].NetProfit}).Count -eq 0 -and `
      [double]$c.NetProfit -ge 1.10*$controlContinuous -and [double]$c.ProfitFactor -ge 1.50 -and `
      [int]$c.TotalTrades -ge 350 -and [double]$c.MaxDrawdownPercent -le 4.00 -and [double]$c.RecoveryFactor -ge 4.00
}
function Test-Neighbor([string]$Name) {
   $g=$groups[$Name];$c=$g["continuous_2015_2026"]
   return @($broad | Where-Object {[double]$g[$_].NetProfit -le 0}).Count -eq 0 -and `
      [double]$c.NetProfit -ge 1.05*$controlContinuous -and [double]$c.ProfitFactor -ge 1.45 -and `
      [double]$c.MaxDrawdownPercent -le 4.25 -and [double]$c.RecoveryFactor -ge 3.75
}
$centerPass = Test-Center $centerName
$lowerPass = Test-Neighbor "mre_mo0175"
$upperPass = Test-Neighbor "mre_mo0225"
$model4Permitted = $centerPass -and $lowerPass -and $upperPass

$summary = [System.Collections.Generic.List[object]]::new()
foreach($name in ($groups.Keys | Sort-Object)) {
   $g=$groups[$name];$c=$g["continuous_2015_2026"]
   $improvement=100.0*([double]$c.NetProfit-$controlContinuous)/$controlContinuous
   $summary.Add([pscustomobject]@{
      Candidate=$name;Role=$c.Role;MORiskPercent=$c.MORiskPercent
      OlderNetProfit=$g["older_2015_2018"].NetProfit;MiddleNetProfit=$g["middle_2019_2022"].NetProfit
      RecentNetProfit=$g["recent_2023_2026"].NetProfit;ContinuousNetProfit=$c.NetProfit
      ImprovementPercent=[math]::Round($improvement,3);ProfitFactor=$c.ProfitFactor;Trades=$c.TotalTrades
      MaxDrawdownPercent=$c.MaxDrawdownPercent;RecoveryFactor=$c.RecoveryFactor
      GatePass=$(if($name-eq$centerName){$centerPass}elseif($name-in @("mre_mo0175","mre_mo0225")){Test-Neighbor $name}else{$false})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision=[pscustomobject]@{
   Status=$(if($model4Permitted){"MODEL1_GATE_PASSED"}else{"REJECTED_IN_MODEL1"})
   ReportsParsed=$results.Count;CenterPass=$centerPass;LowerNeighborPass=$lowerPass;UpperNeighborPass=$upperPass
   Model4Permitted=$model4Permitted;CandidateChanged=$false;ControlNetProfit=$controlContinuous
   CenterNetProfit=[double]$groups[$centerName]["continuous_2015_2026"].NetProfit
   SourceSha256=$queue[0].SourceSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md=[System.Collections.Generic.List[string]]::new()
$md.Add("# RC2 Momentum-Risk Extension Model1 Decision");$md.Add("")
$md.Add($(if($model4Permitted){"**Decision: MODEL1 GATE PASSED. Exact Model4 is permitted only for the frozen center and two neighbors; no candidate is promoted.**"}else{"**Decision: REJECTED IN MODEL1. No Model4 test, candidate change, or live approval is permitted.**"}))
$md.Add("");$md.Add("The exact RC2 source was tested with unchanged signals, exits, stops, sessions, safety controls, and the same 0.75% shared open-risk cap. Only momentum requested risk varied.");$md.Add("")
$md.Add("- Source SHA-256: ``$($queue[0].SourceSha256)``");$md.Add("- Reports: ``$($results.Count) / 28`` parsed");$md.Add("- Control net: ``$(Format-Money $controlContinuous)``");$md.Add("- Center pass: ``$centerPass``; lower neighbor: ``$lowerPass``; upper neighbor: ``$upperPass``");$md.Add("")
$md.Add("| Profile | MOM risk | 2015-18 | 2019-22 | 2023-26 | Continuous | Improvement | PF | Trades | DD | Recovery | Gate |");$md.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|")
foreach($row in ($summary | Sort-Object {[double]$_.MORiskPercent})) {
   $md.Add("| ``$($row.Candidate)`` | $($row.MORiskPercent)% | $(Format-Money ([double]$row.OlderNetProfit)) | $(Format-Money ([double]$row.MiddleNetProfit)) | $(Format-Money ([double]$row.RecentNetProfit)) | $(Format-Money ([double]$row.ContinuousNetProfit)) | $($row.ImprovementPercent)% | $($row.ProfitFactor) | $($row.Trades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.GatePass) |")
}
$md.Add("");$md.Add("The operational RC2 source/profile, unregistered forward drafts, evidence logs, and real-account lock remain unchanged.")
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
$decision
