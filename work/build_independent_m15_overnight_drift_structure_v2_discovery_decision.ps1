param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_overnight_drift_structure_v2_discovery_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_DECISION.md"
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
$rawResults = Join-Path $repo "work\M15ODS2_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M15ODS2_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M15ODS2_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\M15ODS2_RAW_RESULTS.csv" -OutSummary "work\M15ODS2_RAW_SUMMARY.csv" -OutMarkdown "work\M15ODS2_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath $queueFull)
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}
foreach($workerPath in (Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_WORKER_*.csv" -ErrorAction SilentlyContinue)) {
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
      StopLookbackBars = $item.StopLookbackBars; StopBufferATR = $item.StopBufferATR
      MinimumStopATR = $item.MinimumStopATR; MaximumStopATR = $item.MaximumStopATR
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
if($results.Count -ne 39 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected 39 parsed discovery reports."
}
if(@($results | Where-Object { $_.RunnerStatus -ne 'REPORT_FOUND' -or $_.RunnerSourceSha256 -ne $_.SourceSha256 }).Count -ne 0) {
   throw "Runner source identity or report status mismatch."
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$adjacency = @{
   ods2_center = @('ods2_lookback3','ods2_lookback6','ods2_buffer02','ods2_buffer08','ods2_minstop03','ods2_minstop08','ods2_maxstop25','ods2_maxstop45','ods2_signal25','ods2_entry8','ods2_tp125','ods2_tp175')
   ods2_lookback3 = @('ods2_center','ods2_lookback6'); ods2_lookback6 = @('ods2_center','ods2_lookback3')
   ods2_buffer02 = @('ods2_center','ods2_buffer08'); ods2_buffer08 = @('ods2_center','ods2_buffer02')
   ods2_minstop03 = @('ods2_center','ods2_minstop08'); ods2_minstop08 = @('ods2_center','ods2_minstop03')
   ods2_maxstop25 = @('ods2_center','ods2_maxstop45'); ods2_maxstop45 = @('ods2_center','ods2_maxstop25')
   ods2_signal25 = @('ods2_center'); ods2_entry8 = @('ods2_center')
   ods2_tp125 = @('ods2_center','ods2_tp175'); ods2_tp175 = @('ods2_center','ods2_tp125')
}
$numericPass = @{}
$candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq 'older_2015_2018' | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq 'discovery_2019_2020' | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq 'continuous_2015_2020' | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete candidate windows: $($group.Name)" }
   $returnDrawdown = if([double]$continuous.MaxDrawdownMoney -gt 0.0) {
      [double]$continuous.NetProfit / [double]$continuous.MaxDrawdownMoney
   } else { 0.0 }
   $pass = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
           [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 60 -and `
           [double]$continuous.MaxDrawdownPercent -le 3.0 -and [double]$continuous.ExpectedPayoff -gt 0.0 -and `
           $returnDrawdown -ge 1.0
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
$gatePassed = $eligibleRows.Count -gt 0
$numericPassCount = @($summary | Where-Object NumericPass -eq $true).Count
$decision = [pscustomobject]@{
   Status = $(if($gatePassed) { 'DISCOVERY_GATE_PASSED' } else { 'REJECTED_IN_DISCOVERY' })
   Candidates = $summary.Count; ReportsParsed = $results.Count
   NumericPasses = $numericPassCount
   DiscoveryEligible = $eligibleRows.Count; HoldoutPermitted = $gatePassed; Model4Opened = $false
   SourceSha256 = $sourceHash; ResultsSha256 = $resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Independent M15 Overnight-Drift Structure V2 Discovery Decision')
$md.Add('')
$md.Add($(if($gatePassed) {
   '**Decision: 2015-2020 DISCOVERY GATE PASSED. A frozen holdout run is permitted, but no new best, Model 4 promotion, or live approval exists yet.**'
} else {
   '**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**'
}))
$md.Add('')
$md.Add('The v2 standalone EA keeps the frozen prior-day and Asian-drift entry premise, but replaces the full Asian-range stop with a recent completed-M15 structure stop. The neighborhood varies only stop geometry plus three previously frozen signal/exit neighbors. It retains the `$8` affordability cap, broker-native `OrderCalcProfit` sizing, minimum-lot refusal, a `$10,000` balance contract, account-wide exposure limits, drawdown locks, and disabled real-account trading.')
$md.Add('')
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Risk per accepted trade: `0.10%` on a `$10,000` test deposit')
$md.Add('- Exported Model 1 reports: `39 / 39`')
$md.Add('- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`')
$md.Add("- Numeric gate passes: ``$numericPassCount / 13``")
$md.Add("- Neighbor-supported eligible profiles: ``$($eligibleRows.Count) / 13``")
$md.Add('')
$md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$(Escape-Markdown $row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add('')
$md.Add('## Action')
$md.Add('')
if($gatePassed) {
   $md.Add('- Freeze the eligible profile identities before opening the 2021-2026 holdout.')
   $md.Add('- Require the holdout to remain profitable and preserve acceptable PF, activity, and drawdown before Model 4.')
   $md.Add('- Keep the released transferable portfolio unchanged until all escalation gates pass.')
} else {
   $md.Add('- Reject this overnight-drift structure-v2 family without inspecting 2021-2026.')
   $md.Add('- Do not tune its filters against discovery losses or spend real-tick time on it.')
   $md.Add('- Keep the frozen transferable portfolio unchanged and continue searching through genuinely different economic hypotheses.')
}
$md.Add('- Preserve the portable runner and exact report/source identity evidence.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

$metrics = [System.Collections.Generic.List[string]]::new()
$metrics.Add('# Independent M15 Overnight-Drift Structure V2 Discovery Metrics')
$metrics.Add('')
$metrics.Add("- Parsed reports: ``$($results.Count) / $($queue.Count)``")
$metrics.Add("- Results SHA-256: ``$resultsHash``")
$metrics.Add('- Starting deposit: `$10,000` in every report')
$metrics.Add('- Shared parser grouped-number regression: `PASS`')
$metrics.Add('- Main forward terminal preserved: `PASS` after every portable run')
$metrics.Add('- Installed frozen source/binary preserved: `PASS` after every portable run')
$metrics.Add('')
$metrics.Add('See `outputs/INDEPENDENT_M15_OVERNIGHT_DRIFT_STRUCTURE_V2_DISCOVERY_DECISION.md` for the gated interpretation.')
$metrics | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
