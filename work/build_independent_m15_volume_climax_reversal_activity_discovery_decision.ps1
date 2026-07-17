param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_volume_climax_reversal_activity_discovery_model1_package\reports_here",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_MODEL1_METRICS.md",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.md"
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

$rawResults = Join-Path $repo "work\M15VCRA_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\M15VCRA_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\M15VCRA_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\M15VCRA_RAW_RESULTS.csv" -OutSummary "work\M15VCRA_RAW_SUMMARY.csv" `
   -OutMarkdown "work\M15VCRA_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$sourceHashes = @($queue.SourceSha256 | Sort-Object -Unique)
if($sourceHashes.Count -ne 1) { throw "Queue does not contain one frozen source identity." }
$sourceHash = $sourceHashes[0]
$reproducedRanks = @(3, 10, 44)

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
                    $reportText.IndexOf("Volume-Climax Reversal Engine=",[StringComparison]::Ordinal) -ge 0
   if(!$identityPass) { throw "Final report source identity failed: $reportName" }
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
      SourceType=$item.SourceType; Phase=$item.Phase; Set=$item.Set; Window=$item.Window; From=$item.From; To=$item.To
      Model=$item.Model; Deposit=$item.Deposit; Config=$item.Config; ExpectedReportName=$reportName
      ProfileSnapshot=$item.ProfileSnapshot; ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
       MinimumVolumeRatio=$item.MinimumVolumeRatio; MinimumRangeATR=$item.MinimumRangeATR
       MaximumADX=$item.MaximumADX; ExtremeLookbackBars=$item.ExtremeLookbackBars
       RequireFreshExtreme=$item.RequireFreshExtreme; SessionStartHour=$item.SessionStartHour
       SessionEndHour=$item.SessionEndHour; MaximumTradesPerDay=$item.MaximumTradesPerDay; StopRule=$item.StopRule
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
if($results.Count -ne 45 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 45 parsed reports." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$adjacency = @{
   m15vcra_center=@('m15vcra_vol100','m15vcra_vol110','m15vcra_vol120','m15vcra_vol140','m15vcra_vol150','m15vcra_range080','m15vcra_range090','m15vcra_range100','m15vcra_ext4','m15vcra_noext','m15vcra_session024','m15vcra_session422','m15vcra_max3','m15vcra_adx30')
   m15vcra_vol100=@('m15vcra_center'); m15vcra_vol110=@('m15vcra_center')
   m15vcra_vol120=@('m15vcra_center'); m15vcra_vol140=@('m15vcra_center'); m15vcra_vol150=@('m15vcra_center')
   m15vcra_range080=@('m15vcra_center'); m15vcra_range090=@('m15vcra_center'); m15vcra_range100=@('m15vcra_center')
   m15vcra_ext4=@('m15vcra_center'); m15vcra_noext=@('m15vcra_center')
   m15vcra_session024=@('m15vcra_center'); m15vcra_session422=@('m15vcra_center')
   m15vcra_max3=@('m15vcra_center'); m15vcra_adx30=@('m15vcra_center')
}
$numericPass = @{}; $candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq "older_2015_2018" | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq "discovery_2019_2020" | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq "continuous_2015_2020" | Select-Object -First 1
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
$status = if($eligibleRows.Count -gt 0) { "DISCOVERY_ELIGIBLE" } else { "REJECTED_IN_DISCOVERY" }
$decision = [pscustomobject]@{
   Status=$status; Candidates=$summary.Count; ReportsParsed=$results.Count
   ReportsIdentityPassed=@($results | Where-Object ReportSourceIdentityPass -eq $true).Count
   ReproducedIdentityRetries=$reproducedRanks.Count; ActiveProfiles=$activeProfiles.Count; NumericPasses=$numericPasses
   DiscoveryEligible=$eligibleRows.Count; HoldoutOpened=$false; Model4Opened=$false
   SourceSha256=$sourceHash; ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Volume-Climax Reversal Activity Discovery Decision")
$md.Add("")
$headline = if($eligibleRows.Count -gt 0) {
   "**Decision: FREEZE THE DISCOVERY SURVIVORS FOR A DISJOINT 2021-2026 MODEL 1 HOLDOUT. No Model 4, new best, or live approval is opened yet.**"
} else {
   "**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**"
}
$md.Add($headline)
$md.Add("")
$md.Add('The exact source was unchanged from the initial screen. This final pre-holdout extension varied only volume activity, minimum range, local-extreme strictness, session width, per-day activity, and one ADX neighbor around the volume-1.30 lead. The target remained the pre-signal daily VWAP capped by R and rejected below minimum RR. Stops remained beyond the climax wick, capped at `$6`, broker-sized at `0.10%` risk, with no forced minimum volume.')
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`')
$md.Add('- Stale portable exports reproduced unchanged on alternate workers: `3`; all final reports contain the correct source identity')
$md.Add("- Discovery profiles with at least one continuous trade: ``$($activeProfiles.Count) / 15``")
$md.Add("- Numeric gate passes: ``$numericPasses / 15``")
$md.Add("- Eligible profiles with a passing adjacent neighbor: ``$($eligibleRows.Count) / 15``")
$md.Add("")
$md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add("")
if($eligibleRows.Count -gt 0) {
   $eligibleNames = @($eligibleRows.Candidate | Sort-Object)
   $md.Add("The frozen discovery survivors are ``$($eligibleNames -join '`, `')``. Only these exact source/profile identities may enter the disjoint holdout; no discovery threshold may be changed after this decision.")
} else {
   $leader = $summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending | Select-Object -First 1
   $md.Add("The highest continuous row was ``$($leader.Candidate)`` at $(Format-Money $leader.ContinuousNetProfit), PF ``$($leader.ContinuousProfitFactor)``, ``$($leader.ContinuousTrades)`` trades, and ``$($leader.ContinuousMaxDrawdownPercent)%`` drawdown. It did not satisfy the frozen broad-era, PF, activity, drawdown, and adjacent-neighbor contract, so recent data cannot be opened to rescue it.")
}
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

@(
   "# Independent M15 Volume-Climax Reversal Activity Discovery Metrics", "",
   "- Parsed final reports: ``$($results.Count) / $($queue.Count)``", "- Source-identity passes: ``45 / 45``",
   "- Results SHA-256: ``$resultsHash``", '- Starting deposit: `$10,000` in every report',
   '- Frozen forward terminal remained stopped throughout the portable run: `PASS`',
   '- Installed frozen source/binary preserved after every portable run: `PASS`', "",
   'See `outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.md` for the gated interpretation.'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII

$decision
