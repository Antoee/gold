param(
   [string]$ReleaseDecisionPath = "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.csv",
   [string]$ScorecardPath = "outputs\MONEY_READY_STATUS_SCORECARD.csv",
   [string]$LiveReadinessPath = "outputs\TRADE_READY_LIVE_READINESS_DECISION.csv",
   [string]$FirstPassStatusPath = "outputs\FIRST_PASS_REFRESH_STATUS.csv",
   [string]$NextRunManifestPath = "outputs\FIRST_PASS_NEXT_RUN_PACKAGE_MANIFEST.csv",
   [string]$FirstPassHiddenRunPlanPath = "outputs\FIRST_PASS_HIDDEN_RUN_PLAN.csv",
   [string]$ParallelLaneManifestPath = "outputs\FIRST_PASS_PARALLEL_LANE_MANIFEST.csv",
   [string]$ParallelLaneRunManifestPath = "outputs\FIRST_PASS_PARALLEL_LANE_RUN_MANIFEST.csv",
   [string]$ValidationDecisionPath = "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv",
   [string]$OutCsv = "outputs\MONEY_READY_PROOF_RUNWAY.csv",
   [string]$OutMarkdown = "outputs\MONEY_READY_PROOF_RUNWAY.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Summarize-Statuses {
   param([object[]]$Rows)
   $fail = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
   $pending = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
   $pass = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
   $ready = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "READY" }).Count
   $wait = @($Rows | Where-Object { ([string](Get-Value $_ "Status")) -match "WAIT|PENDING" }).Count
   return [pscustomobject]@{
      Rows = $Rows.Count
      Pass = $pass
      Ready = $ready
      Pending = $pending
      Fail = $fail
      Wait = $wait
   }
}

function Add-RunwayRow {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [int]$Priority,
      [string]$Step,
      [string]$Status,
      [string]$EvidenceNeeded,
      [string]$PackageOrInput,
      [string]$ExpectedReturnPath,
      [string]$ConsumerScript,
      [string]$Unlocks,
      [string]$Notes
   )

   $Rows.Add([pscustomobject]@{
      Priority = $Priority
      Step = $Step
      Status = $Status
      EvidenceNeeded = $EvidenceNeeded
      PackageOrInput = $PackageOrInput
      ExpectedReturnPath = $ExpectedReturnPath
      ConsumerScript = $ConsumerScript
      Unlocks = $Unlocks
      Notes = $Notes
   }) | Out-Null
}

$releaseRows = @(Read-CsvSafe $ReleaseDecisionPath)
$scoreRows = @(Read-CsvSafe $ScorecardPath)
$liveRows = @(Read-CsvSafe $LiveReadinessPath)
$firstPassRows = @(Read-CsvSafe $FirstPassStatusPath)
$nextManifestRows = @(Read-CsvSafe $NextRunManifestPath)
$hiddenRunRows = @(Read-CsvSafe $FirstPassHiddenRunPlanPath)
$parallelLaneRows = @(Read-CsvSafe $ParallelLaneManifestPath)
$parallelLaneRunRows = @(Read-CsvSafe $ParallelLaneRunManifestPath)
$validationRows = @(Read-CsvSafe $ValidationDecisionPath)

$releaseSummary = Summarize-Statuses $releaseRows
$scoreSummary = Summarize-Statuses $scoreRows
$liveSummary = Summarize-Statuses $liveRows
$validationSummary = Summarize-Statuses $validationRows
$requiredTesterStats = "Exported MT5 reports must include net profit, profit factor, expected payoff, Sharpe ratio, profit trades (% of total) / win rate, total trades, maximal consecutive losses, balance/equity drawdown maximal with percent, and recovery factor."
$strictReportRule = "Screenshots, balance-only logs, and log-only profit rows cannot clear the strict trade-ready report gates."
$continuousTradeRule = "The exact continuous real-tick conservative run must have at least 20 trades."
$firstPassThresholdRule = "First-pass efficiency floors: fast Model1 continuous must clear annualized return >= 8% and return/DD >= 1.5; exact real-tick continuous must clear annualized return >= 12%, CAGR >= 10%, return/DD >= 3.0, worst parsed DD <= 6%, PF >= 1.20, and recovery >= 1.25."

$releaseStatus = if($releaseRows.Count -eq 0) {
   "PENDING"
} elseif($releaseSummary.Fail -gt 0) {
   "FAILED"
} elseif($releaseSummary.Pending -gt 0) {
   "PENDING"
} else {
   "PASS"
}

$scoreStatus = if($scoreRows.Count -eq 0) {
   "PENDING"
} elseif($scoreSummary.Fail -gt 0) {
   "FAILED"
} elseif($scoreSummary.Pending -gt 0) {
   "PENDING"
} else {
   "PASS"
}

$liveStatus = if($liveRows.Count -eq 0) {
   "PENDING"
} elseif($liveSummary.Fail -gt 0) {
   "FAILED"
} elseif($liveSummary.Pending -gt 0) {
   "PENDING"
} else {
   "PASS"
}

$firstPassReports = $firstPassRows | Where-Object Area -eq "first_pass_reports" | Select-Object -First 1
$firstPassDecision = $firstPassRows | Where-Object Area -eq "first_pass_decision" | Select-Object -First 1
$nextBatch = $firstPassRows | Where-Object Area -eq "next_run_batch" | Select-Object -First 1
$nextPackage = $firstPassRows | Where-Object Area -eq "next_run_package" | Select-Object -First 1
$firstPassFailed = ([string](Get-Value $firstPassDecision "Status") -eq "FAIL")
$firstPassReady = (
   $nextManifestRows.Count -gt 0 -and
   [string](Get-Value $nextBatch "Status") -eq "READY" -and
   [string](Get-Value $nextPackage "Status") -eq "READY"
)
$parallelLanesReady = ($parallelLaneRows.Count -gt 0 -and $parallelLaneRunRows.Count -eq $nextManifestRows.Count)
$hiddenRunPlanExists = Test-Path -LiteralPath (Resolve-RepoPath $FirstPassHiddenRunPlanPath)
$hiddenRunLocked = @($hiddenRunRows | Where-Object { [string](Get-Value $_ "Status") -eq "LOCKED" }).Count
$hiddenRunReady = @($hiddenRunRows | Where-Object { [string](Get-Value $_ "Status") -eq "READY" }).Count
$hiddenRunReports = @($hiddenRunRows | Where-Object { [string](Get-Value $_ "Status") -eq "REPORT_FOUND" }).Count
$hiddenRunState = if($hiddenRunRows.Count -eq 0 -and $hiddenRunPlanExists) {
   "empty"
} elseif($hiddenRunRows.Count -eq 0) {
   "missing"
} elseif($hiddenRunReports -eq $hiddenRunRows.Count) {
   "reports-returned"
} elseif($hiddenRunLocked -gt 0) {
   "locked"
} elseif($hiddenRunReady -gt 0) {
   "ready"
} else {
   "pending"
}

$runway = [System.Collections.Generic.List[object]]::new()

$firstPassStep = if($firstPassFailed) { "Replace failed first-pass candidate" } else { "Run current first-pass package" }
$firstPassRunwayStatus = if($firstPassFailed) { "FAILED" } elseif($firstPassReady) { "READY" } else { "PENDING" }
$firstPassEvidenceNeeded = if($firstPassFailed) {
   "The current first-pass candidate failed the fast Model1 screen; create or select a new candidate profile before spending more tester time. Current parsed status: {0}; parallel lanes: {1} lanes / {2} configs" -f $(if($firstPassReports) { [string](Get-Value $firstPassReports "Actual") } else { "missing" }), $parallelLaneRows.Count, $parallelLaneRunRows.Count
} else {
   "{0} fast Model1 sanity reports as exported .htm/.html/.xml MT5 reports with full tester stats; the continuous fast row must clear annualized return >= 8% and return/DD >= 1.5 before slower real-tick stages are selected; currently parsed status: {1}; parallel lanes: {2} lanes / {3} configs" -f $nextManifestRows.Count, $(if($firstPassReports) { [string](Get-Value $firstPassReports "Actual") } else { "missing" }), $parallelLaneRows.Count, $parallelLaneRunRows.Count
}

Add-RunwayRow $runway 1 $firstPassStep $firstPassRunwayStatus `
   $firstPassEvidenceNeeded `
   "outputs\first_pass_next_run_package or outputs\first_pass_parallel_lanes; optional plan/run helper: work\run_first_pass_package_hidden.ps1; after export use work\advance_first_pass_after_report.ps1" `
   "outputs\returned_mt5_reports\first_pass_inbox\<ExpectedReportName>.htm/.html/.xml, then routed to outputs\first_pass_validation_queue\<candidate>\reports_here\" `
   "work\run_first_pass_package_hidden.ps1; work\advance_first_pass_after_report.ps1; work\route_first_pass_returned_reports.ps1; work\refresh_first_pass_validation_state.ps1" `
   "Trusted first-pass promotion or rejection before spending full Model4 time" `
   ("Next package manifest rows={0}; candidates={1}; parallelLanesReady={2}; hiddenRunner={3}; hiddenRunnerRows={4}" -f $nextManifestRows.Count, ((@($nextManifestRows | ForEach-Object { [string](Get-Value $_ "Candidate") } | Sort-Object -Unique)) -join ", "), $parallelLanesReady, $hiddenRunState, $hiddenRunRows.Count)

Add-RunwayRow $runway 2 "Import fresh current-source compile proof" "PENDING" `
   "MetaEditor compile proof for current source hash with 0 errors and 0 warnings" `
   "Professional_XAUUSD_EA.mq5 + outputs\Professional_XAUUSD_EA.mq5" `
   "outputs\MT5_COMPILE_STATUS.csv" `
   "work\import_mt5_compile_log.ps1; work\analyze_trade_ready_live_readiness.ps1" `
   "Clears live:current-source-compile" `
   "Current live-readiness compile proof is stale until the compile hash equals the current source hash."

Add-RunwayRow $runway 3 "Run conservative full validation only after first-pass passes" ($(if($validationSummary.Pending -gt 0) { "WAITING_ON_FIRST_PASS" } elseif($validationSummary.Fail -gt 0) { "FAILED" } else { "READY_OR_DONE" })) `
   ("53 conservative validation reports plus 10 broker-proxy reports with full parsed tester stats. {0} {1}" -f $requiredTesterStats, $continuousTradeRule) `
   "outputs\trade_ready_conservative_validation_package + outputs\trade_ready_conservative_broker_proxy_package" `
   "outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv" `
   "work\import_trade_ready_conservative_validation_reports.ps1" `
   "Clears model4-validation and quality return/drawdown/PF/recovery gates" `
   ("Conservative validation decision rows={0}; pass={1}; pending={2}; fail={3}" -f $validationSummary.Rows, $validationSummary.Pass, $validationSummary.Pending, $validationSummary.Fail)

Add-RunwayRow $runway 4 "Return conservative closed-trade/deal logs" "PENDING" `
   "Closed trade logs with profile_id, source_hash, run_label, realized R, held bars, spread/MFE/MAE when available" `
   "EA trade/deal log export from conservative profile runs" `
   "outputs\trade_ready_conservative_trade_logs\*.csv" `
   "work\analyze_trade_ready_conservative_trade_quality.ps1; work\analyze_trade_ready_conservative_monte_carlo.ps1" `
   "Clears trade-quality and Monte Carlo stress gates" `
   "Monte Carlo cannot be meaningful until realized-R trade rows exist."

Add-RunwayRow $runway 5 "Return forward paper/demo evidence" "PENDING" `
   "Forward/demo performance evidence with enough calendar days, trades, non-red net profit, PF floor, expected-payoff floor, Sharpe floor, win-rate floor, drawdown cap, loss-streak cap, and matching hashes" `
   "Paper/demo account export" `
   "outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv" `
   "work\analyze_trade_ready_conservative_forward_test.ps1" `
   "Clears forward-paper-demo gate" `
   "This is separate from backtesting and should remain unseen by optimization."

Add-RunwayRow $runway 6 "Return second-broker XAUUSD evidence" "PENDING" `
   "Evidence from a non-primary broker/symbol specification with acceptable profit, PF, expected payoff, Sharpe, win rate, drawdown, loss-streak, and identity checks" `
   "Second broker tester/demo export" `
   "outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv" `
   "work\analyze_trade_ready_conservative_second_broker.ps1" `
   "Clears second-broker-validation gate" `
   "Gold contract specs vary a lot; this gate is intentionally separate."

Add-RunwayRow $runway 7 "Restore reproducible source sync" "PENDING" `
   "Valid source/profile reproducibility path with matching hashes; local .git is currently not valid, so connector/raw publication audit must prove exact source/profile hashes" `
   ".git or connector-based source publication plus outputs\GITHUB_PUBLICATION_SYNC.md" `
   "outputs\GITHUB_PUBLICATION_SYNC.csv; outputs\SOURCE_MANIFEST.md plus release/source hashes" `
   "work\analyze_trade_ready_live_readiness.ps1; work\build_trade_ready_release_candidate.ps1" `
   "Clears reproducible-github-sync and release review reproducibility" `
   "Do not use GitHub Actions for heavy tester work; keep runs local. If raw GitHub files are inaccessible, keep this gate pending until connector-published source/profile hashes are independently verified."

Add-RunwayRow $runway 8 "Regenerate final gates after evidence import" "WAITING_ON_EVIDENCE" `
   ("Release={0}; scorecard={1}; live={2}" -f $releaseStatus, $scoreStatus, $liveStatus) `
   "All returned evidence above" `
   "outputs\MONEY_READY_STATUS_SCORECARD.md; outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md" `
   "work\build_money_ready_status_scorecard.ps1; work\build_trade_ready_release_candidate.ps1" `
   "Allows manual live-review profile only if all gates pass and explicit approval identity matches" `
   "A live-review profile should not exist while this row is waiting."

$outCsvPath = Resolve-RepoPath $OutCsv
$outMarkdownPath = Resolve-RepoPath $OutMarkdown
foreach($path in @($outCsvPath, $outMarkdownPath)) {
   $parent = Split-Path -Parent $path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

$runway | Export-Csv -LiteralPath $outCsvPath -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Money-Ready Proof Runway")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.")
$md.Add("")
$md.Add(('- Release status: `{0}`' -f $releaseStatus))
$md.Add(('- Money-ready scorecard status: `{0}`' -f $scoreStatus))
$md.Add(('- Live-readiness status: `{0}`' -f $liveStatus))
$md.Add(('- First-pass next package rows: `{0}`' -f $nextManifestRows.Count))
$md.Add(('- First-pass parallel lanes: `{0}` lanes / `{1}` configs' -f $parallelLaneRows.Count, $parallelLaneRunRows.Count))
$md.Add(('- First-pass hidden runner: `{0}` (`{1}` rows)' -f $hiddenRunState, $hiddenRunRows.Count))
$md.Add("")
$md.Add("## Next Action")
$md.Add("")
if($firstPassReady) {
   if($parallelLanesReady) {
      $md.Add(('Run either the `{0}` configs in `outputs\first_pass_next_run_package` or the `{1}` window-based lane folders in `outputs\first_pass_parallel_lanes`. Export each report into `outputs\returned_mt5_reports\first_pass_inbox` using the matching `ExpectedReportName`, then run `work\advance_first_pass_after_report.ps1`; it routes the report, refreshes first-pass state, refreshes money-ready status, and writes `outputs\FIRST_PASS_ADVANCE_STATUS.md`.' -f $nextManifestRows.Count, $parallelLaneRows.Count))
   } else {
      $md.Add(('Run the `{0}` configs in `outputs\first_pass_next_run_package`, export each report into `outputs\returned_mt5_reports\first_pass_inbox` using the matching `ExpectedReportName`, then run `work\advance_first_pass_after_report.ps1`; it routes the report, refreshes first-pass state, refreshes money-ready status, and writes `outputs\FIRST_PASS_ADVANCE_STATUS.md`.' -f $nextManifestRows.Count))
   }
   $md.Add(('Optional local hidden runner: `work\run_first_pass_package_hidden.ps1` writes `outputs\FIRST_PASS_HIDDEN_RUN_PLAN.md`; current runner state is `{0}`. It will not launch MT5 unless rerun with `-Run` and the existing MT5 unlock requirements are satisfied.' -f $hiddenRunState))
   $md.Add($firstPassThresholdRule)
   $md.Add($requiredTesterStats)
   $md.Add($strictReportRule)
} elseif($firstPassFailed) {
   $md.Add("The current first-pass candidate failed the fast Model1 screen. Do not run the stale first-pass package; it has been cleared. The next useful tester work is building a new candidate/profile or relaxing/reworking the strategy logic, then rebuilding the first-pass queue.")
} else {
   $md.Add("Refresh or rebuild the first-pass next package before running tester work.")
}
$md.Add("")
$md.Add("## Runway")
$md.Add("")
$md.Add("| Priority | Step | Status | Evidence Needed | Package/Input | Expected Return Path | Consumer Script | Unlocks | Notes |")
$md.Add("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
foreach($row in $runway) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f
      (Escape-MarkdownCell $row.Priority),
      (Escape-MarkdownCell $row.Step),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.EvidenceNeeded),
      (Escape-MarkdownCell $row.PackageOrInput),
      (Escape-MarkdownCell $row.ExpectedReturnPath),
      (Escape-MarkdownCell $row.ConsumerScript),
      (Escape-MarkdownCell $row.Unlocks),
      (Escape-MarkdownCell $row.Notes)))
}

$md.Add("")
$md.Add("## First-Pass Configs To Run")
$md.Add("")
if($nextManifestRows.Count -eq 0) {
   $md.Add("No next-run manifest rows found.")
} else {
   $md.Add("| Rank | Candidate | Window | Model | Config | Expected Report Name | Report Destination |")
   $md.Add("| --- | --- | --- | --- | --- | --- | --- |")
   foreach($row in $nextManifestRows) {
      $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f
         (Escape-MarkdownCell (Get-Value $row "QueueRank")),
         (Escape-MarkdownCell (Get-Value $row "Candidate")),
         (Escape-MarkdownCell (Get-Value $row "Window")),
         (Escape-MarkdownCell (Get-Value $row "Model")),
         (Escape-MarkdownCell (Get-Value $row "PackageConfig")),
         (Escape-MarkdownCell (Get-Value $row "ExpectedReportName")),
         (Escape-MarkdownCell (Get-Value $row "ReportDestination"))))
   }
}

$md | Set-Content -LiteralPath $outMarkdownPath -Encoding ASCII

[pscustomobject]@{
   ReleaseStatus = $releaseStatus
   ScorecardStatus = $scoreStatus
   LiveReadinessStatus = $liveStatus
   FirstPassReady = $firstPassReady
   NextRunConfigs = $nextManifestRows.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
