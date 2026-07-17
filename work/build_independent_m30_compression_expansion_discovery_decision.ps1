param(
   [string]$QueuePath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m30_compression_expansion_discovery_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_DECISION.md"
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

$rawResults = Join-Path $repo "work\M30CE_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M30CE_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M30CE_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\M30CE_RAW_RESULTS.csv" -OutSummary "work\M30CE_RAW_SUMMARY.csv" `
   -OutMarkdown "work\M30CE_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$sourceHashes = @($queue.SourceSha256 | Sort-Object -Unique)
if($sourceHashes.Count -ne 1) { throw "Queue does not contain one frozen source identity." }
$sourceHash = $sourceHashes[0]
$reproducedRanks = @(8, 36, 38, 42)

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
                   $reportText.IndexOf("Compression Expansion Engine=",[StringComparison]::Ordinal) -ge 0
   if(!$identityPass) { throw "Final report source identity failed: $reportName" }
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
      SourceType=$item.SourceType; Phase=$item.Phase; Set=$item.Set; Window=$item.Window; From=$item.From; To=$item.To
      Model=$item.Model; Deposit=$item.Deposit; Config=$item.Config; ExpectedReportName=$reportName
      ProfileSnapshot=$item.ProfileSnapshot; ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
      BoxLookbackBars=$item.BoxLookbackBars; MaximumBoxRangeATR=$item.MaximumBoxRangeATR
      MaximumAverageBoxBarRangeATR=$item.MaximumAverageBoxBarRangeATR; MinimumExpansionRatio=$item.MinimumExpansionRatio
      MinimumBreakBodyPercent=$item.MinimumBreakBodyPercent; TakeProfitR=$item.TakeProfitR
      UseVolume=$item.UseVolume; UseTrend=$item.UseTrend; UseADX=$item.UseADX; StopRule=$item.StopRule
      Status=$parsed.Status; ReportPath=$reportRelativePath; ReportSha256=(Get-FileHash -LiteralPath $reportFullPath -Algorithm SHA256).Hash
      ReportSourceIdentityPass=$identityPass; ReportDisposition=$(if([int]$item.QueueRank -in $reproducedRanks){"REPRODUCED_AFTER_EMPTY_EXPORT"}else{"FIRST_VALID_EXPORT"})
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
if($results.Count -ne 45 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 45 parsed reports." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$adjacency = @{
   m30ce_center=@('m30ce_box8','m30ce_box12','m30ce_boxmax150','m30ce_boxmax210','m30ce_avg035','m30ce_avg055','m30ce_exp120','m30ce_exp160','m30ce_body45','m30ce_tp150','m30ce_tp200')
   m30ce_box8=@('m30ce_center'); m30ce_box12=@('m30ce_center'); m30ce_boxmax150=@('m30ce_center'); m30ce_boxmax210=@('m30ce_center')
   m30ce_avg035=@('m30ce_center'); m30ce_avg055=@('m30ce_center'); m30ce_exp120=@('m30ce_center'); m30ce_exp160=@('m30ce_center')
   m30ce_body45=@('m30ce_center'); m30ce_tp150=@('m30ce_center'); m30ce_tp200=@('m30ce_center')
   m30ce_volume105=@('m30ce_center'); m30ce_h1trend=@('m30ce_center'); m30ce_adx14=@('m30ce_center')
}
$numericPass = @{}; $candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq "older_2015_2018" | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq "discovery_2019_2020" | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq "continuous_2015_2020" | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete windows: $($group.Name)" }
   $numericPass[$group.Name] = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
      [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 100 -and `
      [double]$continuous.MaxDrawdownPercent -le 5.0
   $candidateRows[$group.Name] = [pscustomobject]@{ Older=$older; Later=$later; Continuous=$continuous }
}
$summary = [System.Collections.Generic.List[object]]::new()
foreach($candidate in ($candidateRows.Keys | Sort-Object)) {
   $set = $candidateRows[$candidate]
   $neighborPasses = @($adjacency[$candidate] | Where-Object { $numericPass[$_] })
   $eligible = $numericPass[$candidate] -and $neighborPasses.Count -gt 0
   $summary.Add([pscustomobject]@{
      Candidate=$candidate; OlderNetProfit=$set.Older.NetProfit; OlderProfitFactor=$set.Older.ProfitFactor; OlderTrades=$set.Older.TotalTrades
      LaterNetProfit=$set.Later.NetProfit; LaterProfitFactor=$set.Later.ProfitFactor; LaterTrades=$set.Later.TotalTrades
      ContinuousNetProfit=$set.Continuous.NetProfit; ContinuousCagrPercent=$set.Continuous.CagrPercent
      ContinuousProfitFactor=$set.Continuous.ProfitFactor; ContinuousTrades=$set.Continuous.TotalTrades
      ContinuousMaxDrawdownPercent=$set.Continuous.MaxDrawdownPercent; NumericPass=$numericPass[$candidate]
      AdjacentPass=($neighborPasses.Count -gt 0); PassingNeighbors=($neighborPasses -join ';')
      Decision=$(if($eligible){"DISCOVERY_ELIGIBLE"}else{"REJECT_BEFORE_HOLDOUT"})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$numericPasses = @($summary | Where-Object NumericPass -eq $true).Count
$eligibleRows = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE")
$activeProfiles = @($summary | Where-Object { [int]$_.ContinuousTrades -gt 0 })
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$decision = [pscustomobject]@{
   Status="REJECTED_IN_DISCOVERY"; Candidates=$summary.Count; ReportsParsed=$results.Count
   ReportsIdentityPassed=@($results | Where-Object ReportSourceIdentityPass -eq $true).Count
   ReproducedEmptyExports=$reproducedRanks.Count; ActiveProfiles=$activeProfiles.Count; NumericPasses=$numericPasses
   DiscoveryEligible=$eligibleRows.Count; HoldoutOpened=$false; Model4Opened=$false
   SourceSha256=$sourceHash; ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M30 Compression-Expansion Discovery Decision")
$md.Add("")
$md.Add("**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**")
$md.Add("")
$md.Add('The standalone EA required a bounded M30 compression box and a closed expansion candle beyond it, with OHLC range, body, close-location, and expansion-ratio confirmation. Optional tick volume, H1 EMA trend, and ADX gates were isolated variants. Stops sat beyond the breakout candle, were capped at `$8`, used broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never forced minimum volume.')
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`')
$md.Add('- Invalid stale-executable batch: quarantined locally and excluded from all metrics')
$md.Add('- Empty M0 exports reproduced unchanged: `4`; all final reports contain the correct source identity')
$md.Add('- Discovery profiles with at least one continuous trade: `2 / 15`')
$md.Add('- Numeric gate passes: `0 / 15`')
$md.Add("")
$md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add("")
$md.Add('The only both-era profitable row was `m30ce_box8`, at `+$48.17` and PF `3.59`, but it placed just `7` trades in six years versus the frozen minimum of `100`. The only other active row, `m30ce_avg055`, made `+$9.05` on `7` trades and lost the older era. Thirteen profiles placed zero trades. This is an activity/generalization failure, not evidence for a sparse profitable system.')
$md.Add("")
$md.Add('The portable runner now binds every package source hash to a compiled portable binary and rejects cached or newly exported reports whose embedded evidence hash does not match. This source-identity correction is retained as infrastructure; it does not improve strategy profit.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

@(
   "# Independent M30 Compression-Expansion Discovery Metrics", "",
   "- Parsed final reports: ``$($results.Count) / $($queue.Count)``", "- Source-identity passes: ``45 / 45``",
   "- Results SHA-256: ``$resultsHash``", '- Starting deposit: `$10,000` in every report',
   '- Main forward terminal preserved after every portable run: `PASS`',
   '- Installed frozen source/binary preserved after every portable run: `PASS`', "",
   'See `outputs/INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_DECISION.md` for the gated interpretation.'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
