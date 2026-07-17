param(
   [string]$QueuePath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\transferable_portfolio_growth_discovery_model1_package\reports_here",
   [string]$ResultsPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Get-Field([object]$Row,[string]$Name,[object]$Default="") {
   if($null -eq $Row) { return $Default }
   $p=$Row.PSObject.Properties[$Name]
   if($null -eq $p -or "$($p.Value)" -eq "") { return $Default }
   return $p.Value
}
function Format-Money([object]$Value) {
   $n=[double]$Value
   return $(if($n -ge 0){'+'}else{'-'}) + '$' + [math]::Abs($n).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$rawResults="work\TPG_RAW_RESULTS.csv"
$rawSummary="work\TPG_RAW_SUMMARY.csv"
$rawMetrics="work\TPG_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue=@(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw=@(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
$rawByReport=@{}
foreach($row in $raw){$rawByReport[[string]$row.ExpectedReportName]=$row}
$runnerByRank=@{}
foreach($path in (Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "TRANSFERABLE_GROWTH_PORTABLE_*.csv" -ErrorAction SilentlyContinue)) {
   foreach($row in (Import-Csv -LiteralPath $path.FullName)) {
      $key=[string]$row.QueueRank
      if(!$runnerByRank.ContainsKey($key) -or [string]$row.Status -eq 'REPORT_FOUND'){$runnerByRank[$key]=$row}
   }
}

$results=[System.Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object {[int]$_.QueueRank})) {
   $reportName=[string]$item.ExpectedReportName
   if(!$rawByReport.ContainsKey($reportName)){throw "Collector row missing: $reportName"}
   $parsed=$rawByReport[$reportName]
   $runner=$runnerByRank[[string]$item.QueueRank]
   $reportPath=[string](Get-Field $parsed 'ReportPath')
   $reportHash=if($reportPath -and (Test-Path -LiteralPath (Resolve-RepoPath $reportPath))){(Get-FileHash -LiteralPath (Resolve-RepoPath $reportPath) -Algorithm SHA256).Hash}else{''}
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank; Control=$item.Control
      Phase=$item.Phase; Window=$item.Window; From=$item.From; To=$item.To; Model=$item.Model; Deposit=$item.Deposit
      Config=$item.Config; ExpectedReportName=$reportName; ProfileSnapshot=$item.ProfileSnapshot
      ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
      RVRiskPercent=$item.RVRiskPercent; MORiskPercent=$item.MORiskPercent
      PortfolioOpenRiskPercent=$item.PortfolioOpenRiskPercent; StopRule=$item.StopRule
      Status=$parsed.Status; ReportPath=$reportPath; ReportSha256=$reportHash
      InitialDeposit=$parsed.InitialDeposit; CalendarDays=$parsed.CalendarDays; Years=$parsed.Years
      NetProfit=$parsed.NetProfit; Balance=$parsed.Balance; TotalReturnPercent=$parsed.TotalReturnPercent
      AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent; CagrPercent=$parsed.CagrPercent
      ProfitFactor=$parsed.ProfitFactor; ExpectedPayoff=$parsed.ExpectedPayoff; SharpeRatio=$parsed.SharpeRatio
      WinRatePercent=$parsed.WinRatePercent; TotalTrades=$parsed.TotalTrades
      MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses; MaxDrawdownMoney=$parsed.MaxDrawdownMoney
      MaxDrawdownPercent=$parsed.MaxDrawdownPercent; BalanceDrawdownMaximal=$parsed.BalanceDrawdownMaximal
      EquityDrawdownMaximal=$parsed.EquityDrawdownMaximal; RecoveryFactor=$parsed.RecoveryFactor
      RunnerStatus=(Get-Field $runner 'Status'); RunnerEvidence=(Get-Field $runner 'Evidence')
   }) | Out-Null
}
if($results.Count -ne 28 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0){throw "Expected 28 parsed reports."}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$groups=@{}
foreach($group in ($results | Group-Object Candidate)) {
   $rows=@{}
   foreach($row in $group.Group){$rows[[string]$row.Window]=$row}
   foreach($required in @('older_2015_2018','middle_2019_2022','recent_2023_2026','continuous_2015_2026')){
      if(!$rows.ContainsKey($required)){throw "Missing $required for $($group.Name)"}
   }
   $groups[$group.Name]=$rows
}
$controlName='tpg_rv045_mo015_control'
$controlNet=[double]$groups[$controlName]['continuous_2015_2026'].NetProfit
if($controlNet -le 0){throw "Control must be profitable for a relative growth gate."}

$numericPass=@{}
foreach($candidate in $groups.Keys) {
   $g=$groups[$candidate]
   $c=$g['continuous_2015_2026']
   $isControl=$candidate -eq $controlName
   $numericPass[$candidate]=!$isControl -and `
      [double]$g['older_2015_2018'].NetProfit -gt 0 -and `
      [double]$g['middle_2019_2022'].NetProfit -gt 0 -and `
      [double]$g['recent_2023_2026'].NetProfit -gt 0 -and `
      [double]$c.NetProfit -ge 1.15*$controlNet -and [double]$c.ProfitFactor -ge 1.50 -and `
      [int]$c.TotalTrades -ge 330 -and [double]$c.MaxDrawdownPercent -le 4.00 -and [double]$c.RecoveryFactor -ge 4.00
}
$adjacency=@{
   tpg_rv050_mo010=@('tpg_rv050_mo015','tpg_rv055_mo010')
   tpg_rv050_mo015=@('tpg_rv050_mo010','tpg_rv055_mo015')
   tpg_rv055_mo010=@('tpg_rv050_mo010','tpg_rv055_mo015','tpg_rv060_mo010')
   tpg_rv055_mo015=@('tpg_rv050_mo015','tpg_rv055_mo010','tpg_rv060_mo015')
   tpg_rv060_mo010=@('tpg_rv055_mo010','tpg_rv060_mo015')
   tpg_rv060_mo015=@('tpg_rv055_mo015','tpg_rv060_mo010')
}

$summary=[System.Collections.Generic.List[object]]::new()
foreach($candidate in ($groups.Keys | Sort-Object)) {
   $g=$groups[$candidate]; $c=$g['continuous_2015_2026']; $isControl=$candidate -eq $controlName
   $neighbors=@(if($isControl){@()}else{$adjacency[$candidate] | Where-Object {$numericPass[$_]}})
   $supported=$neighbors.Count -gt 0
   $eligible=!$isControl -and $numericPass[$candidate] -and $supported
   $improvement=100.0*([double]$c.NetProfit-$controlNet)/$controlNet
   $summary.Add([pscustomobject]@{
      Candidate=$candidate; Control=$isControl; RVRiskPercent=$c.RVRiskPercent; MORiskPercent=$c.MORiskPercent
      OlderNetProfit=$g['older_2015_2018'].NetProfit; MiddleNetProfit=$g['middle_2019_2022'].NetProfit
      RecentNetProfit=$g['recent_2023_2026'].NetProfit; ContinuousNetProfit=$c.NetProfit
      ImprovementVsControlPercent=[math]::Round($improvement,3); ContinuousCagrPercent=$c.CagrPercent
      ContinuousProfitFactor=$c.ProfitFactor; ContinuousTrades=$c.TotalTrades
      ContinuousMaxDrawdownPercent=$c.MaxDrawdownPercent; ContinuousRecoveryFactor=$c.RecoveryFactor
      NumericPass=$numericPass[$candidate]; AdjacentPass=$supported; PassingNeighbors=($neighbors -join ';')
      Decision=$(if($isControl){'CONTROL'}elseif($eligible){'MODEL4_ELIGIBLE'}else{'REJECT_BEFORE_MODEL4'})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$eligible=@($summary | Where-Object Decision -eq 'MODEL4_ELIGIBLE')
$numericCount=@($summary | Where-Object NumericPass -eq $true).Count
$sourceHash=@($queue.SourceSha256 | Sort-Object -Unique)[0]
$resultsHash=(Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$status=if($eligible.Count -gt 0){'MODEL1_GATE_PASSED'}else{'REJECTED_IN_MODEL1'}
$decision=[pscustomobject]@{
   Status=$status; Profiles=$summary.Count; ReportsParsed=$results.Count; NumericPasses=$numericCount
   Model4Eligible=$eligible.Count; Model4Permitted=($eligible.Count -gt 0); ReleasedCandidateChanged=$false
   ControlNetProfit=$controlNet; SourceSha256=$sourceHash; ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md=[System.Collections.Generic.List[string]]::new()
$md.Add('# Transferable Portfolio Growth Allocation Model1 Decision')
$md.Add('')
$md.Add($(if($eligible.Count -gt 0){'**Decision: MODEL 1 GATE PASSED. Exact Model 4 validation is permitted for the supported growth neighborhood; the released and forward candidates remain unchanged.**'}else{'**Decision: REJECTED IN MODEL 1. No Model 4 growth test, new best, or live approval was opened.**'}))
$md.Add('')
$md.Add('The exact released source was tested without changing signals, exits, stops, schedules, or safety controls. Only reversion and momentum requested-risk allocations varied inside the unchanged `0.75%` shared open-risk cap.')
$md.Add('')
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Reports: `28 / 28` parsed with embedded exact-source identity')
$md.Add("- Same-source control net: ``$(Format-Money $controlNet)``")
$md.Add("- Numeric growth passes: ``$numericCount / 6``")
$md.Add("- Neighbor-supported Model 4 profiles: ``$($eligible.Count) / 6``")
$md.Add('')
$md.Add('| Profile | RV | MOM | 2015-18 | 2019-22 | 2023-26 | Continuous | Improvement | CAGR | PF | Trades | DD | Recovery | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $($row.RVRiskPercent)% | $($row.MORiskPercent)% | $(Format-Money $row.OlderNetProfit) | $(Format-Money $row.MiddleNetProfit) | $(Format-Money $row.RecentNetProfit) | $(Format-Money $row.ContinuousNetProfit) | $($row.ImprovementVsControlPercent)% | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ContinuousRecoveryFactor) | $($row.Decision) |")
}
$md.Add('')
$md.Add('Passing this screen does not promote a profile. It only freezes the supported neighborhood for exact Model 4, deterministic cost stress, and Monte Carlo validation. The existing forward-demo candidate and its identity remain unchanged.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

@(
   '# Transferable Portfolio Growth Discovery Metrics','',
   "- Parsed reports: ``$($results.Count) / $($queue.Count)``",
   "- Results SHA-256: ``$resultsHash``",
   "- Source SHA-256: ``$sourceHash``",
   '- Starting deposit: `$10,000` in every report',
   '- Shared open-risk cap: `0.75%` in every profile',
   '- Real-account trading default: disabled',
   '',
   'See `outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.md` for the gated interpretation.'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
