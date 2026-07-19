param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_usd_consensus_lead_lag_discovery_model1_package\reports_here",
   [string]$RunnerPath = "outputs\USDCLL_DISCOVERY_EXACT_1.csv",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_DECISION.md",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_METRICS.md",
   [string]$FeasibilityResultsPath = "outputs\XAUUSD_USD_PROXY_HISTORY_FEASIBILITY_RESULTS.csv",
   [string]$FeasibilityMarkdownPath = "outputs\XAUUSD_USD_PROXY_HISTORY_FEASIBILITY.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Get-Field([object]$Row,[string]$Name,[object]$Default="") {
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property -or "$($property.Value)" -eq "") { return $Default }
   return $property.Value
}
function Format-Money([object]$Value) {
   $number = [double]$Value
   return $(if($number -ge 0.0) { "+" } else { "-" }) + '$' + [Math]::Abs($number).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$rawResults = Join-Path $repo "work\USDCLL_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\USDCLL_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\USDCLL_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\USDCLL_RAW_RESULTS.csv" -OutSummary "work\USDCLL_RAW_SUMMARY.csv" `
   -OutMarkdown "work\USDCLL_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$runnerRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunnerPath))
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}
foreach($row in $runnerRows) { $runnerByRank[[string]$row.QueueRank] = $row }

$results = [Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $reportName = [string]$item.ExpectedReportName
   if(!$rawByReport.ContainsKey($reportName)) { throw "Collector row missing: $reportName" }
   if(!$runnerByRank.ContainsKey([string]$item.QueueRank)) { throw "Runner row missing for queue rank $($item.QueueRank)" }
   $parsed = $rawByReport[$reportName]
   $runner = $runnerByRank[[string]$item.QueueRank]
   $reportPath = [string](Get-Field $parsed "ReportPath")
   $reportFull = Resolve-RepoPath $reportPath
   $reportHash = if($reportPath -and (Test-Path -LiteralPath $reportFull -PathType Leaf)) {
      (Get-FileHash -LiteralPath $reportFull -Algorithm SHA256).Hash
   } else { "" }
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
      SourceType=$item.SourceType; Phase=$item.Phase; Set=$item.Set; Window=$item.Window; From=$item.From; To=$item.To
      Model=$item.Model; Deposit=$item.Deposit; Config=$item.Config; ExpectedReportName=$reportName
      ProfileSnapshot=$item.ProfileSnapshot; ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
      ProxyLookbackBars=$item.ProxyLookbackBars; MinimumProxyComponentATR=$item.MinimumProxyComponentATR
      MinimumConsensusATR=$item.MinimumConsensusATR; MaximumGoldExtensionATR=$item.MaximumGoldExtensionATR
      BreakoutLookbackBars=$item.BreakoutLookbackBars; BreakoutBufferATR=$item.BreakoutBufferATR; TakeProfitR=$item.TakeProfitR
      Status=$parsed.Status; ReportPath=$reportPath; ReportSha256=$reportHash
      InitialDeposit=$parsed.InitialDeposit; CalendarDays=$parsed.CalendarDays; Years=$parsed.Years
      NetProfit=$parsed.NetProfit; Balance=$parsed.Balance; TotalReturnPercent=$parsed.TotalReturnPercent
      AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent; CagrPercent=$parsed.CagrPercent
      ProfitFactor=$parsed.ProfitFactor; ExpectedPayoff=$parsed.ExpectedPayoff; SharpeRatio=$parsed.SharpeRatio
      WinRatePercent=$parsed.WinRatePercent; TotalTrades=$parsed.TotalTrades; MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses
      MaxDrawdownMoney=$parsed.MaxDrawdownMoney; MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      BalanceDrawdownMaximal=$parsed.BalanceDrawdownMaximal; EquityDrawdownMaximal=$parsed.EquityDrawdownMaximal
      RecoveryFactor=$parsed.RecoveryFactor; RunnerStatus=$runner.Status; RunnerEvidence=$runner.Evidence
      RunnerSourceSha256=$runner.PackageSourceSha256; PortableBinarySha256=$runner.PortableBinarySha256
   }) | Out-Null
}
if($results.Count -ne 45 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected 45 parsed discovery reports."
}
if(@($results | Where-Object { $_.RunnerStatus -ne "REPORT_FOUND" -or $_.RunnerSourceSha256 -ne $_.SourceSha256 }).Count -ne 0) {
   throw "Runner report status or source identity mismatch."
}
if(@($results | Where-Object { [int]$_.TotalTrades -le 0 }).Count -ne 0) { throw "Discovery contains a zero-trade report." }
$sourceHashes = @($results.SourceSha256 | Sort-Object -Unique)
$binaryHashes = @($results.PortableBinarySha256 | Sort-Object -Unique)
if($sourceHashes.Count -ne 1 -or $binaryHashes.Count -ne 1) { throw "Exact source/binary identity is not uniform." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$summary = [Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq "older_2015_2018" | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq "discovery_2019_2020" | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq "continuous_2015_2020" | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete candidate windows: $($group.Name)" }
   $returnDrawdown = if([double]$continuous.MaxDrawdownMoney -gt 0.0) { [double]$continuous.NetProfit / [double]$continuous.MaxDrawdownMoney } else { 0.0 }
   $pass = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
           [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 80 -and `
           [double]$continuous.MaxDrawdownPercent -le 3.0 -and [double]$continuous.ExpectedPayoff -gt 0.0 -and `
           $returnDrawdown -ge 1.0
   $summary.Add([pscustomobject]@{
      Candidate=$group.Name; OlderNetProfit=$older.NetProfit; OlderProfitFactor=$older.ProfitFactor; OlderTrades=$older.TotalTrades
      LaterNetProfit=$later.NetProfit; LaterProfitFactor=$later.ProfitFactor; LaterTrades=$later.TotalTrades
      ContinuousNetProfit=$continuous.NetProfit; ContinuousCagrPercent=$continuous.CagrPercent
      ContinuousProfitFactor=$continuous.ProfitFactor; ContinuousTrades=$continuous.TotalTrades
      ContinuousMaxDrawdownPercent=$continuous.MaxDrawdownPercent; ContinuousExpectedPayoff=$continuous.ExpectedPayoff
      ReturnDrawdown=$returnDrawdown.ToString('F2',[Globalization.CultureInfo]::InvariantCulture)
      NumericPass=$pass; AdjacentPass=$false; Decision=$(if($pass) { "PENDING_ADJACENCY" } else { "REJECT_BEFORE_HOLDOUT" })
   }) | Out-Null
}
$numericPasses = @($summary | Where-Object NumericPass -eq $true)
if($numericPasses.Count -gt 0) { throw "Adjacency evaluation is required because a numeric profile unexpectedly passed." }
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$feasibilityRows = [Collections.Generic.List[object]]::new()
$commonFiles = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files"
foreach($name in @("XAUUSD_EURUSD_History_Feasibility.csv","XAUUSD_USDJPY_History_Feasibility.csv")) {
   $sourceRows = @(Import-Csv -LiteralPath (Join-Path $commonFiles $name))
   foreach($year in 2015..2020) {
      $best = $sourceRows | Where-Object { [int]$_.year -eq $year } | Sort-Object { [int]$_.xau_closed_bars } -Descending | Select-Object -First 1
      if(!$best) { throw "Feasibility evidence missing for $name year $year" }
      $feasibilityRows.Add($best) | Out-Null
   }
}
$feasibilityRows | Sort-Object reference_symbol,{[int]$_.year} | Export-Csv -LiteralPath (Resolve-RepoPath $FeasibilityResultsPath) -NoTypeInformation -Encoding ASCII
$feasibilityMinimum = ($feasibilityRows | Measure-Object alignment_percent -Minimum).Minimum
$lookbackMinimum = ($feasibilityRows | Measure-Object lookback_ready_percent -Minimum).Minimum

$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$decision = [pscustomobject]@{
   Status="REJECTED_IN_DISCOVERY"; Candidates=$summary.Count; ReportsParsed=$results.Count; NumericPasses=0
   DiscoveryEligible=0; HoldoutPermitted=$false; Model4Opened=$false; NewBest=$false
   SourceSha256=$sourceHashes[0]; PortableBinarySha256=$binaryHashes[0]; ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 USD-Consensus Lead-Lag Discovery Decision")
$md.Add("")
$md.Add("**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**")
$md.Add("")
$md.Add('The EA tested a date-independent cross-market premise: completed H1 EURUSD strength plus USDJPY weakness as a USD-weakness proxy for gold buys, the inverse for sells, a gold lag constraint, and completed M15 breakout confirmation. All profiles retained broker-native risk sizing, minimum-lot refusal, a `$10,000` contract, account-wide exposure protection, daily/equity loss caps, one trade per day, and disabled real trading.')
$md.Add("")
$md.Add("- Source SHA-256: ``$($sourceHashes[0])``")
$md.Add("- Exact report binary SHA-256: ``$($binaryHashes[0])``")
$md.Add('- Controlled run: `45 / 45` reports, one worker, zero runner errors')
$md.Add('- Risk per accepted trade: `0.10%` on a `$10,000` test deposit')
$md.Add('- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`')
$md.Add('- Numeric gate passes: `0 / 15`')
$md.Add('- History feasibility: EURUSD and USDJPY aligned on at least `99.9023%` of yearly XAUUSD M15 bars; lookback readiness `100%`')
$md.Add("")
$md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add("")
$md.Add("## Interpretation")
$md.Add("")
$md.Add('- Every profile lost money in 2015-2018; no parameter neighbor produced a broad-era plateau.')
$md.Add('- Most profiles improved in 2019-2020, but continuous profit factors remained below `1.0`, so this is regime dependence rather than a durable edge.')
$md.Add('- Reject this family without inspecting 2021-2026 or spending real-tick time on it. Keep Three-Lane Trade-Ready RC2 ATB150 as the research best.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

@(
   '# Independent M15 USD-Consensus Lead-Lag Metrics','',
   "- Parsed reports: ``$($results.Count) / $($queue.Count)``",
   "- Results SHA-256: ``$resultsHash``",
   "- Source SHA-256: ``$($sourceHashes[0])``",
   "- Portable binary SHA-256: ``$($binaryHashes[0])``",
   '- Exact binary identities: `1`','- Starting deposit: `$10,000` in every report',
   '- Holdout opened: `NO`','- Model 4 opened: `NO`','- New best: `NO`'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII
@(
   '# XAUUSD USD-Proxy History Feasibility','',
   'The broker history supports aligned XAUUSD/EURUSD and XAUUSD/USDJPY M15 research over the sealed 2015-2020 discovery period. This proves data availability only; it does not prove the trading strategy.','',
   "- Rows: ``$($feasibilityRows.Count)``", "- Minimum yearly alignment: ``$feasibilityMinimum%``",
   "- Minimum yearly lookback readiness: ``$lookbackMinimum%``", '- Missing yearly evidence: `0`'
) | Set-Content -LiteralPath (Resolve-RepoPath $FeasibilityMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath $rawResults,$rawSummary,$rawMarkdown -Force -ErrorAction SilentlyContinue
$decision
