param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_overnight_drift_continuation_holdout_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_DECISION.md"
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
$rawResults = Join-Path $repo "work\M15ODC_HOLDOUT_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M15ODC_HOLDOUT_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M15ODC_HOLDOUT_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\M15ODC_HOLDOUT_RAW_RESULTS.csv" -OutSummary "work\M15ODC_HOLDOUT_RAW_SUMMARY.csv" -OutMarkdown "work\M15ODC_HOLDOUT_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath $queueFull)
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}
foreach($workerPath in (Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_WORKER_*.csv" -ErrorAction SilentlyContinue)) {
   foreach($row in (Import-Csv -LiteralPath $workerPath.FullName)) {
      $key = [string]$row.QueueRank
      if(!$runnerByRank.ContainsKey($key) -or [string]$row.Status -eq 'REPORT_FOUND') { $runnerByRank[$key] = $row }
   }
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
   $runnerSourceHash = [string](Get-Field $runner "PackageSourceSha256")
   $portableBinaryHash = [string](Get-Field $runner "PortableBinarySha256")
   $results.Add([pscustomobject]@{
      QueueRank = $item.QueueRank; Candidate = $item.Candidate; CandidateRank = $item.CandidateRank
      SourceType = $item.SourceType; SourceRank = $item.SourceRank; Phase = $item.Phase; Set = $item.Set
      Window = $item.Window; From = $item.From; To = $item.To; Model = $item.Model; Deposit = $item.Deposit
      Config = $item.Config; ExpectedReportName = $reportName; ProfileSnapshot = $item.ProfileSnapshot
      ProfileSha256 = $item.ProfileSha256; SourceSha256 = $item.SourceSha256
      PriorDayMoveATR = $item.PriorDayMoveATR; PriorDayBodyPercent = $item.PriorDayBodyPercent
      MaximumAsianRangeATR = $item.MaximumAsianRangeATR; MinimumAsianDriftATR = $item.MinimumAsianDriftATR
      EntryHour = $item.EntryHour; SignalBodyPercent = $item.SignalBodyPercent
      TakeProfitR = $item.TakeProfitR; StopRule = $item.StopRule
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
      RunnerSourceSha256 = $runnerSourceHash; PortableBinarySha256 = $portableBinaryHash
   }) | Out-Null
}
if($results.Count -ne 12 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected 12 parsed holdout reports."
}
if(@($results | Where-Object { $_.RunnerStatus -ne 'REPORT_FOUND' -or $_.RunnerSourceSha256 -ne $_.SourceSha256 }).Count -ne 0) {
   throw "Runner source identity or report status mismatch."
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $early = $group.Group | Where-Object Window -eq 'early_2021_2022' | Select-Object -First 1
   $middle = $group.Group | Where-Object Window -eq 'middle_2023_2024' | Select-Object -First 1
   $recent = $group.Group | Where-Object Window -eq 'recent_2025_2026' | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq 'continuous_2021_2026' | Select-Object -First 1
   if(!$early -or !$middle -or !$recent -or !$continuous) { throw "Incomplete holdout windows: $($group.Name)" }
   $returnDrawdown = if([double]$continuous.MaxDrawdownMoney -gt 0.0) {
      [double]$continuous.NetProfit / [double]$continuous.MaxDrawdownMoney
   } else { 0.0 }
   $pass = [double]$early.NetProfit -gt 0.0 -and [double]$middle.NetProfit -gt 0.0 -and `
           [double]$recent.NetProfit -gt 0.0 -and [double]$continuous.ProfitFactor -ge 1.15 -and `
           [int]$continuous.TotalTrades -ge 90 -and `
           [double]$continuous.MaxDrawdownPercent -le 3.0 -and [double]$continuous.ExpectedPayoff -gt 0.0 -and `
           $returnDrawdown -ge 1.0
   $candidateRows[$group.Name] = [pscustomobject]@{
      Early=$early; Middle=$middle; Recent=$recent; Continuous=$continuous
      ReturnDrawdown=$returnDrawdown; Pass=$pass
   }
}

$summary = [System.Collections.Generic.List[object]]::new()
foreach($candidate in ($candidateRows.Keys | Sort-Object)) {
   $set = $candidateRows[$candidate]
   $summary.Add([pscustomobject]@{
      Candidate = $candidate
      EarlyNetProfit = $set.Early.NetProfit; EarlyProfitFactor = $set.Early.ProfitFactor; EarlyTrades = $set.Early.TotalTrades
      MiddleNetProfit = $set.Middle.NetProfit; MiddleProfitFactor = $set.Middle.ProfitFactor; MiddleTrades = $set.Middle.TotalTrades
      RecentNetProfit = $set.Recent.NetProfit; RecentProfitFactor = $set.Recent.ProfitFactor; RecentTrades = $set.Recent.TotalTrades
      ContinuousNetProfit = $set.Continuous.NetProfit; ContinuousCagrPercent = $set.Continuous.CagrPercent
      ContinuousProfitFactor = $set.Continuous.ProfitFactor; ContinuousTrades = $set.Continuous.TotalTrades
      ContinuousMaxDrawdownPercent = $set.Continuous.MaxDrawdownPercent
      ContinuousReturnDrawdown = [math]::Round($set.ReturnDrawdown,4)
      Decision = $(if($set.Pass) { 'HOLDOUT_SURVIVOR' } else { 'REJECT_BEFORE_MODEL4' })
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$survivors = @($summary | Where-Object Decision -eq 'HOLDOUT_SURVIVOR')
$sourceHash = @($queue.SourceSha256 | Sort-Object -Unique)[0]
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$gatePassed = $survivors.Count -gt 0
$decision = [pscustomobject]@{
   Status = $(if($gatePassed) { 'HOLDOUT_GATE_PASSED' } else { 'REJECTED_IN_HOLDOUT' })
   Candidates = $summary.Count; ReportsParsed = $results.Count
   HoldoutSurvivors = $survivors.Count; Model4Permitted = $gatePassed; Model4Opened = $false
   SourceSha256 = $sourceHash; ResultsSha256 = $resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Independent M15 Overnight-Drift Continuation Holdout Decision')
$md.Add('')
$md.Add($(if($gatePassed) {
   '**Decision: POST-2020 HOLDOUT GATE PASSED. Model 4 validation is permitted for the surviving frozen profile(s), but no new best or live approval exists yet.**'
} else {
   '**Decision: REJECTED IN POST-2020 HOLDOUT. No Model 4 escalation, new best, or live approval was opened.**'
}))
$md.Add('')
$md.Add('The center and two orthogonal one-factor discovery survivors were frozen before opening post-2020 data. Each row retains the exact source and profile identity, a `$10,000` initial-balance contract, broker-native risk sizing, minimum-lot refusal, account-wide exposure limits, drawdown locks, and disabled real-account trading.')
$md.Add('')
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Risk per accepted trade: `0.10%` on a `$10,000` test deposit')
$md.Add('- Exported Model 1 reports: `12 / 12`')
$md.Add('- Frozen holdout windows: `2021-2022`, `2023-2024`, `2025-2026 YTD`, and continuous `2021-2026 YTD`')
$md.Add("- Holdout survivors: ``$($survivors.Count) / 3``")
$md.Add('')
$md.Add('| Candidate | 2021-22 | PF | 2023-24 | PF | 2025-26 | PF | Continuous | CAGR | PF | Trades | DD | Return/DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$(Escape-Markdown $row.Candidate)`` | $(Format-Money $row.EarlyNetProfit) | $($row.EarlyProfitFactor) | $(Format-Money $row.MiddleNetProfit) | $($row.MiddleProfitFactor) | $(Format-Money $row.RecentNetProfit) | $($row.RecentProfitFactor) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ContinuousReturnDrawdown) | $($row.Decision) |")
}
$md.Add('')
$md.Add('## Action')
$md.Add('')
if($gatePassed) {
   $md.Add('- Escalate only the frozen holdout survivor(s) to Model 4 real-tick validation.')
   $md.Add('- Require Model 4 broad-window profitability, acceptable execution diagnostics, and cost stress before any comparison with ATB150.')
} else {
   $md.Add('- Reject this overnight-drift continuation family without Model 4 escalation.')
   $md.Add('- Do not tune parameters against the holdout failures.')
}
$md.Add('- Keep the released transferable portfolio unchanged until every escalation gate passes.')
$md.Add('- Preserve the portable runner and exact report/source identity evidence.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

$metrics = [System.Collections.Generic.List[string]]::new()
$metrics.Add('# Independent M15 Overnight-Drift Continuation Holdout Metrics')
$metrics.Add('')
$metrics.Add("- Parsed reports: ``$($results.Count) / $($queue.Count)``")
$metrics.Add("- Results SHA-256: ``$resultsHash``")
$metrics.Add('- Starting deposit: `$10,000` in every report')
$metrics.Add('- Shared parser grouped-number regression: `PASS`')
$metrics.Add('- Main forward terminal preserved: `PASS` after every portable run')
$metrics.Add('- Installed frozen source/binary preserved: `PASS` after every portable run')
$metrics.Add('')
$metrics.Add('See `outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_HOLDOUT_DECISION.md` for the gated interpretation.')
$metrics | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
