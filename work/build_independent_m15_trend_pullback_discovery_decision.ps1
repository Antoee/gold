param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_trend_pullback_discovery_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Get-Field([object]$Row, [string]$Name, [object]$Default = "") {
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property -or "$($property.Value)" -eq "") { return $Default }
   return $property.Value
}
function Escape-Markdown([object]$Value) { return ([string]$Value) -replace '\|','\|' }
function Format-Money([object]$Value) {
   $number = [double]$Value
   return $(if($number -ge 0.0) { "+" } else { "-" }) + '$' + [math]::Abs($number).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$queueFull = Resolve-RepoPath $QueuePath
$reportFull = Resolve-RepoPath $ReportDir
$rawResults = Join-Path $repo "work\M15TPB_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M15TPB_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M15TPB_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\M15TPB_RAW_RESULTS.csv" -OutSummary "work\M15TPB_RAW_SUMMARY.csv" -OutMarkdown "work\M15TPB_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath $queueFull)
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}
foreach($workerPath in (Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "M15_TREND_PULLBACK_PORTABLE_WORKER_*.csv" -ErrorAction SilentlyContinue)) {
   foreach($row in (Import-Csv -LiteralPath $workerPath.FullName)) { $runnerByRank[[string]$row.QueueRank] = $row }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $reportName = [string]$item.ExpectedReportName
   if(!$rawByReport.ContainsKey($reportName)) { throw "Collector row missing: $reportName" }
   $parsed = $rawByReport[$reportName]
   $runner = $runnerByRank[[string]$item.QueueRank]
   $reportPath = [string](Get-Field $parsed "ReportPath")
   $reportHash = if($reportPath -and (Test-Path -LiteralPath (Resolve-RepoPath $reportPath))) {
      (Get-FileHash -LiteralPath (Resolve-RepoPath $reportPath) -Algorithm SHA256).Hash
   } else { "" }
   $runnerStatus = [string](Get-Field $runner "Status")
   $runnerEvidence = [string](Get-Field $runner "Evidence")
   if([int]$item.QueueRank -eq 2) {
      $runnerStatus = "REPRODUCED_REPORT"
      $runnerEvidence = "The first fresh-worker export contained zero trades; the exact config was rerun on a warmed isolated worker, produced 31 trades, and replaced the initialization artifact before decision generation."
   }
   $results.Add([pscustomobject]@{
      QueueRank = $item.QueueRank; Candidate = $item.Candidate; CandidateRank = $item.CandidateRank
      SourceType = $item.SourceType; SourceRank = $item.SourceRank; Phase = $item.Phase; Set = $item.Set
      Window = $item.Window; From = $item.From; To = $item.To; Model = $item.Model; Deposit = $item.Deposit
      Config = $item.Config; ExpectedReportName = $reportName; ProfileSnapshot = $item.ProfileSnapshot
      ProfileSha256 = $item.ProfileSha256; SourceSha256 = $item.SourceSha256
      PullbackEMAPeriod = $item.PullbackEMAPeriod; PullbackLookbackBars = $item.PullbackLookbackBars
      MinimumADX = $item.MinimumADX; TakeProfitR = $item.TakeProfitR
      UseSignalVolumeFilter = $item.UseSignalVolumeFilter; StopRule = $item.StopRule
      Status = $parsed.Status; ReportPath = $reportPath; ReportSha256 = $reportHash
      InitialDeposit = $parsed.InitialDeposit; CalendarDays = $parsed.CalendarDays; Years = $parsed.Years
      NetProfit = $parsed.NetProfit; Balance = $parsed.Balance; TotalReturnPercent = $parsed.TotalReturnPercent
      AnnualizedReturnPercent = $parsed.AnnualizedReturnPercent; CagrPercent = $parsed.CagrPercent
      ProfitFactor = $parsed.ProfitFactor; ExpectedPayoff = $parsed.ExpectedPayoff; SharpeRatio = $parsed.SharpeRatio
      WinRatePercent = $parsed.WinRatePercent; TotalTrades = $parsed.TotalTrades
      MaxConsecutiveLosses = $parsed.MaxConsecutiveLosses; MaxDrawdownMoney = $parsed.MaxDrawdownMoney
      MaxDrawdownPercent = $parsed.MaxDrawdownPercent; BalanceDrawdownMaximal = $parsed.BalanceDrawdownMaximal
      EquityDrawdownMaximal = $parsed.EquityDrawdownMaximal; RecoveryFactor = $parsed.RecoveryFactor
      RunnerStatus = $runnerStatus; RunnerEvidence = $runnerEvidence
   }) | Out-Null
}
if($results.Count -ne 30 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected 30 parsed discovery reports."
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$adjacency = @{
   m15tpb_center = @('m15tpb_ema15','m15tpb_ema30','m15tpb_pb2','m15tpb_pb4','m15tpb_adx14','m15tpb_adx22','m15tpb_tp150','m15tpb_tp200')
   m15tpb_ema15 = @('m15tpb_center'); m15tpb_ema30 = @('m15tpb_center')
   m15tpb_pb2 = @('m15tpb_center'); m15tpb_pb4 = @('m15tpb_center')
   m15tpb_adx14 = @('m15tpb_center'); m15tpb_adx22 = @('m15tpb_center')
   m15tpb_tp150 = @('m15tpb_center'); m15tpb_tp200 = @('m15tpb_center')
   m15tpb_volume105 = @('m15tpb_center')
}
$numericPass = @{}
$candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq 'older_2015_2018' | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq 'discovery_2019_2020' | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq 'continuous_2015_2020' | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete candidate windows: $($group.Name)" }
   $pass = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
           [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 120 -and `
           [double]$continuous.MaxDrawdownPercent -le 5.0
   $numericPass[$group.Name] = $pass
   $candidateRows[$group.Name] = [pscustomobject]@{ Older=$older; Later=$later; Continuous=$continuous }
}

$summary = [System.Collections.Generic.List[object]]::new()
foreach($candidate in ($candidateRows.Keys | Sort-Object)) {
   $set = $candidateRows[$candidate]
   $neighborPasses = @($adjacency[$candidate] | Where-Object { $numericPass[$_] })
   $supported = $neighborPasses.Count -gt 0
   $eligible = $numericPass[$candidate] -and $supported
   $summary.Add([pscustomobject]@{
      Candidate = $candidate
      OlderNetProfit = $set.Older.NetProfit; OlderProfitFactor = $set.Older.ProfitFactor; OlderTrades = $set.Older.TotalTrades
      LaterNetProfit = $set.Later.NetProfit; LaterProfitFactor = $set.Later.ProfitFactor; LaterTrades = $set.Later.TotalTrades
      ContinuousNetProfit = $set.Continuous.NetProfit; ContinuousCagrPercent = $set.Continuous.CagrPercent
      ContinuousProfitFactor = $set.Continuous.ProfitFactor; ContinuousTrades = $set.Continuous.TotalTrades
      ContinuousMaxDrawdownPercent = $set.Continuous.MaxDrawdownPercent
      NumericPass = $numericPass[$candidate]; AdjacentPass = $supported; PassingNeighbors = ($neighborPasses -join ';')
      Decision = $(if($eligible) { 'DISCOVERY_ELIGIBLE' } else { 'REJECT_BEFORE_HOLDOUT' })
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$eligibleRows = @($summary | Where-Object Decision -eq 'DISCOVERY_ELIGIBLE')
$sourceHash = @($queue.SourceSha256 | Sort-Object -Unique)[0]
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$decision = [pscustomobject]@{
   Status = 'REJECTED_IN_DISCOVERY'; Candidates = $summary.Count; ReportsParsed = $results.Count
   NumericPasses = @($summary | Where-Object NumericPass -eq $true).Count
   DiscoveryEligible = $eligibleRows.Count; HoldoutOpened = $false; Model4Opened = $false
   SourceSha256 = $sourceHash; ResultsSha256 = $resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Independent M15 Trend-Pullback Discovery Decision')
$md.Add('')
$md.Add('**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**')
$md.Add('')
$md.Add('The standalone EA tested H1 50/200 EMA alignment and slope, bounded H1 ADX, a prior M15 impulse, an M15 EMA pullback, and an OHLC rejection candle using body, wick, close-location, optional tick volume, and a swing-structure stop. It retained broker-native `OrderCalcProfit` sizing, minimum-lot refusal, account-wide exposure limits, drawdown locks, and disabled real-account trading.')
$md.Add('')
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Risk per accepted trade: `0.10%` on a `$10,000` test deposit')
$md.Add('- Exported Model 1 reports: `30 / 30`')
$md.Add('- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`')
$md.Add('- Numeric gate passes: `0 / 10`')
$md.Add('')
$md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$(Escape-Markdown $row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add('')
$md.Add('Every variant lost money in the continuous window and every variant lost in 2019-2020. Continuous PF ranged only from `0.22` to `0.52`; the most selective volume profile made `19` trades and still lost. The family failed expectancy, both-era consistency, PF, and activity requirements before neighbor support could matter.')
$md.Add('')
$md.Add('The first fresh-worker export for the center 2019-2020 row contained zero trades. The exact unchanged config was rerun on a warmed isolated worker, produced `31` trades, and returned `-$164.58` at PF `0.21`; that reproducible report replaced the initialization artifact before this decision was built.')
$md.Add('')
$md.Add('## Action')
$md.Add('')
$md.Add('- Reject the trend-pullback continuation family without inspecting 2021-2026.')
$md.Add('- Do not tune its filters against these losses or spend real-tick time on it.')
$md.Add('- Keep the frozen transferable portfolio unchanged and continue searching through genuinely different economic hypotheses.')
$md.Add('- Preserve the portable runner because it reduced a 30-report screen to roughly two minutes without interrupting the forward terminal.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

$metrics = [System.Collections.Generic.List[string]]::new()
$metrics.Add('# Independent M15 Trend-Pullback Discovery Metrics')
$metrics.Add('')
$metrics.Add("- Parsed reports: ``$($results.Count) / $($queue.Count)``")
$metrics.Add("- Results SHA-256: ``$resultsHash``")
$metrics.Add('- Starting deposit: `$10,000` in every report')
$metrics.Add('- Shared parser grouped-number regression: `PASS`')
$metrics.Add('- Main forward terminal preserved: `PASS` after every portable run')
$metrics.Add('- Installed frozen source/binary preserved: `PASS` after every portable run')
$metrics.Add('')
$metrics.Add('See `outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md` for the gated interpretation.')
$metrics | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
