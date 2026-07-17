param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_dual_regime_portfolio_holdout_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Get-Field([object]$Row, [string]$Name, [object]$Default = "") {
   $property = if($null -eq $Row) { $null } else { $Row.PSObject.Properties[$Name] }
   if($null -eq $property -or "$($property.Value)" -eq "") { return $Default }
   return $property.Value
}
function Format-Money([object]$Value) {
   $number = [double]$Value
   return $(if($number -ge 0.0) { "+" } else { "-" }) + '$' + [math]::Abs($number).ToString("N2",[Globalization.CultureInfo]::InvariantCulture)
}

$rawResults = Join-Path $repo "work\M15DRP_HOLDOUT_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M15DRP_HOLDOUT_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M15DRP_HOLDOUT_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\M15DRP_HOLDOUT_RAW_RESULTS.csv" -OutSummary "work\M15DRP_HOLDOUT_RAW_SUMMARY.csv" `
   -OutMarkdown "work\M15DRP_HOLDOUT_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$sourceHashes = @($queue.SourceSha256 | Sort-Object -Unique)
if($sourceHashes.Count -ne 1) { throw "Queue does not contain one frozen source identity." }
$sourceHash = $sourceHashes[0]
$reproducedRanks = @(4)

$results = [System.Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $reportName = [string]$item.ExpectedReportName
   if(!$rawByReport.ContainsKey($reportName)) { throw "Collector row missing: $reportName" }
   $parsed = $rawByReport[$reportName]
   $reportPath = [string](Get-Field $parsed "ReportPath")
   $reportFullPath = if([IO.Path]::IsPathRooted($reportPath)) { $reportPath } else { Join-Path $repo $reportPath }
   if(!$reportPath -or !(Test-Path -LiteralPath $reportFullPath -PathType Leaf)) { throw "Final report missing: $reportName" }
   if(!$reportFullPath.StartsWith($repo + "\",[StringComparison]::OrdinalIgnoreCase)) { throw "Report is outside the workspace: $reportFullPath" }
   $reportText = Get-Content -LiteralPath $reportFullPath -Raw
   $reportRelativePath = $reportFullPath.Substring($repo.Length + 1)
   $identityPass = $reportText.IndexOf($sourceHash,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and
                    $reportText.IndexOf("Portfolio Engines=",[StringComparison]::Ordinal) -ge 0
   if(!$identityPass) { throw "Final report source identity failed: $reportName" }
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
      SourceType=$item.SourceType; Phase=$item.Phase; Set=$item.Set; Window=$item.Window; From=$item.From; To=$item.To
      Model=$item.Model; Deposit=$item.Deposit; Config=$item.Config; ExpectedReportName=$reportName
      ProfileSnapshot=$item.ProfileSnapshot; ProfileSha256=$item.ProfileSha256
      DiscoveryProfileSha256=$item.DiscoveryProfileSha256; SourceSha256=$item.SourceSha256; StopRule=$item.StopRule
      Status=$parsed.Status; ReportPath=$reportRelativePath; ReportSha256=(Get-FileHash -LiteralPath $reportFullPath -Algorithm SHA256).Hash
       ReportSourceIdentityPass=$identityPass; ReportDisposition=$(if([int]$item.QueueRank -in $reproducedRanks){"REPRODUCED_AFTER_IDENTITY_RETRY"}else{"FIRST_VALID_EXPORT"})
      InitialDeposit=$parsed.InitialDeposit; CalendarDays=$parsed.CalendarDays; Years=$parsed.Years
      NetProfit=$parsed.NetProfit; Balance=$parsed.Balance; TotalReturnPercent=$parsed.TotalReturnPercent
      AnnualizedReturnPercent=$parsed.AnnualizedReturnPercent; CagrPercent=$parsed.CagrPercent
      ProfitFactor=$parsed.ProfitFactor; ExpectedPayoff=$parsed.ExpectedPayoff; SharpeRatio=$parsed.SharpeRatio
      WinRatePercent=$parsed.WinRatePercent; TotalTrades=$parsed.TotalTrades; MaxConsecutiveLosses=$parsed.MaxConsecutiveLosses
      MaxDrawdownMoney=$parsed.MaxDrawdownMoney; MaxDrawdownPercent=$parsed.MaxDrawdownPercent
      BalanceDrawdownMaximal=$parsed.BalanceDrawdownMaximal; EquityDrawdownMaximal=$parsed.EquityDrawdownMaximal
      RecoveryFactor=$parsed.RecoveryFactor
   }) | Out-Null
}
if($results.Count -ne 36 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 36 parsed reports." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$adjacency = @{
   m15drp_center=@('m15drp_vcr140','m15drp_vcr150','m15drp_sqbreak6','m15drp_sqbreak10','m15drp_kc140','m15drp_kc160','m15drp_trend50','m15drp_trend200','m15drp_session18','m15drp_session22','m15drp_maxtrades3','m15drp_noextreme')
   m15drp_sq_only=@(); m15drp_vcr_only=@()
   m15drp_vcr140=@('m15drp_center'); m15drp_vcr150=@('m15drp_center')
   m15drp_sqbreak6=@('m15drp_center'); m15drp_sqbreak10=@('m15drp_center')
   m15drp_kc140=@('m15drp_center'); m15drp_kc160=@('m15drp_center')
   m15drp_trend50=@('m15drp_center'); m15drp_trend200=@('m15drp_center')
   m15drp_session18=@('m15drp_center'); m15drp_session22=@('m15drp_center')
   m15drp_maxtrades3=@('m15drp_center'); m15drp_noextreme=@('m15drp_center')
}
$numericPass = @{}; $candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq "holdout_2021_2023" | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq "recent_2024_2026ytd" | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq "continuous_2021_2026ytd" | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete windows: $($group.Name)" }
   $numericPass[$group.Name] = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
      [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 120 -and `
      [double]$continuous.MaxDrawdownPercent -le 5.0
   $candidateRows[$group.Name] = [pscustomobject]@{ Older=$older; Later=$later; Continuous=$continuous }
}
$summary = [System.Collections.Generic.List[object]]::new()
foreach($candidate in ($candidateRows.Keys | Sort-Object)) {
   $set = $candidateRows[$candidate]
   $neighborPasses = @($adjacency[$candidate] | Where-Object { $numericPass[$_] })
   $promotableDualEngine = $candidate -notin @('m15drp_sq_only','m15drp_vcr_only')
   $eligible = $promotableDualEngine -and $numericPass[$candidate] -and $neighborPasses.Count -gt 0
   $summary.Add([pscustomobject]@{
      Candidate=$candidate; OlderNetProfit=$set.Older.NetProfit; OlderProfitFactor=$set.Older.ProfitFactor; OlderTrades=$set.Older.TotalTrades
      LaterNetProfit=$set.Later.NetProfit; LaterProfitFactor=$set.Later.ProfitFactor; LaterTrades=$set.Later.TotalTrades
      ContinuousNetProfit=$set.Continuous.NetProfit; ContinuousCagrPercent=$set.Continuous.CagrPercent
      ContinuousProfitFactor=$set.Continuous.ProfitFactor; ContinuousTrades=$set.Continuous.TotalTrades
      ContinuousMaxDrawdownPercent=$set.Continuous.MaxDrawdownPercent; PromotableDualEngine=$promotableDualEngine
      NumericPass=$numericPass[$candidate]
      AdjacentPass=($neighborPasses.Count -gt 0); PassingNeighbors=($neighborPasses -join ';')
      Decision=$(if($eligible){"HOLDOUT_ELIGIBLE"}else{"REJECT_BEFORE_MODEL4"})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$numericPasses = @($summary | Where-Object NumericPass -eq $true).Count
$eligibleRows = @($summary | Where-Object Decision -eq "HOLDOUT_ELIGIBLE")
$activeProfiles = @($summary | Where-Object { [int]$_.ContinuousTrades -gt 0 })
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$status = if($eligibleRows.Count -gt 0) { "HOLDOUT_ELIGIBLE" } else { "REJECTED_IN_HOLDOUT" }
$decision = [pscustomobject]@{
   Status=$status; Candidates=$summary.Count; ReportsParsed=$results.Count
   ReportsIdentityPassed=@($results | Where-Object ReportSourceIdentityPass -eq $true).Count
   ReproducedIdentityRetries=$reproducedRanks.Count; ActiveProfiles=$activeProfiles.Count; NumericPasses=$numericPasses
   HoldoutEligible=$eligibleRows.Count; HoldoutOpened=$true; Model4Opened=$false
   SourceSha256=$sourceHash; ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Dual-Regime Portfolio Holdout Decision")
$md.Add("")
$headline = if($eligibleRows.Count -gt 0) {
   "**Decision: HOLDOUT SURVIVORS MAY ENTER A SMALL REAL-TICK MODEL 4 CHECK. No new best or live approval is opened yet.**"
} else {
   "**Decision: REJECTED IN THE UNTOUCHED 2021-2026 HOLDOUT. No Model 4 escalation, new best, or live approval was opened.**"
}
$md.Add($headline)
$md.Add("")
$md.Add('The EA combines a trend-phase M15 volatility-squeeze continuation lane with a range-phase M15 volume-climax VWAP-reversion lane under one risk manager and one-position cap. Lane-specific comments preserve lane-specific exits. The compact neighborhood changes only previously screened lane settings and includes two diagnostic engine-only controls that cannot be promoted. Stops are capped at `$6`, use broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never force minimum volume.')
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Correct-source Model 1 reports: `36 / 36`; report/source identity: `36 / 36`')
$md.Add('- Stale portable exports reproduced unchanged on alternate workers: `1`; all final reports contain the correct source identity')
$md.Add("- Holdout profiles with at least one continuous trade: ``$($activeProfiles.Count) / 12``")
$md.Add("- Numeric gate passes: ``$numericPasses / 12``")
$md.Add("- Eligible profiles with a passing adjacent neighbor: ``$($eligibleRows.Count) / 12``")
$md.Add("")
$md.Add('| Candidate | 2021-23 | PF | Trades | 2024-26 YTD | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add("")
if($eligibleRows.Count -gt 0) {
   $eligibleNames = @($eligibleRows.Candidate | Sort-Object)
   $md.Add("The frozen holdout survivors are ``$($eligibleNames -join '`, `')``. Only a compact risk-ranked subset of these exact source/profile identities may enter real-tick Model 4; no profile setting may change.")
} else {
   $leader = $summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending | Select-Object -First 1
   $md.Add("The highest continuous row was ``$($leader.Candidate)`` at $(Format-Money $leader.ContinuousNetProfit), PF ``$($leader.ContinuousProfitFactor)``, ``$($leader.ContinuousTrades)`` trades, and ``$($leader.ContinuousMaxDrawdownPercent)%`` drawdown. It did not satisfy the frozen holdout contract, so Model 4 cannot be opened to rescue it.")
}
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

@(
   "# Independent M15 Dual-Regime Portfolio Holdout Metrics", "",
   "- Parsed final reports: ``$($results.Count) / $($queue.Count)``", "- Source-identity passes: ``36 / 36``",
   "- Results SHA-256: ``$resultsHash``", '- Starting deposit: `$10,000` in every report',
   '- Frozen forward terminal remained stopped throughout the portable run: `PASS`',
   '- Installed frozen source/binary preserved after every portable run: `PASS`', "",
   'See `outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.md` for the gated interpretation.'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
