param(
   [string]$QueuePath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_m15_tlt_rates_impulse_discovery_model1_package\reports_here",
   [string]$RunnerPath = "outputs\TLTRI_DISCOVERY_EXACT_1.csv",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$AttestationPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_RUN_ATTESTATION.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_DECISION.md",
   [string]$MetricsPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_METRICS.md",
   [string]$FeasibilityResultsPath = "outputs\XAUUSD_TLT_D1_HISTORY_FEASIBILITY_RESULTS.csv",
   [string]$FeasibilityMarkdownPath = "outputs\XAUUSD_TLT_D1_HISTORY_FEASIBILITY.md"
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

$rawResults = Join-Path $repo "work\TLTRI_RAW_RESULTS.csv"
$rawSummary = Join-Path $repo "work\TLTRI_RAW_SUMMARY.csv"
$rawMarkdown = Join-Path $repo "work\TLTRI_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\TLTRI_RAW_RESULTS.csv" -OutSummary "work\TLTRI_RAW_SUMMARY.csv" `
   -OutMarkdown "work\TLTRI_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$runnerRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunnerPath))
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$runnerByRank = @{}
foreach($row in $runnerRows) { $runnerByRank[[string]$row.QueueRank] = $row }
$packageRoot = Split-Path -Parent (Resolve-RepoPath $ReportDir)

$results = [Collections.Generic.List[object]]::new()
$attestations = [Collections.Generic.List[object]]::new()
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
   $configFull = Join-Path $packageRoot ([string]$item.Config)
   $configHash = (Get-FileHash -LiteralPath $configFull -Algorithm SHA256).Hash.ToUpperInvariant()
   $identityFull = Join-Path (Resolve-RepoPath $ReportDir) ($reportName + ".identity.json")
   if(!(Test-Path -LiteralPath $identityFull -PathType Leaf)) { throw "Report identity missing: $reportName" }
   $identity = Get-Content -LiteralPath $identityFull -Raw | ConvertFrom-Json
   if($configHash -ne ([string]$runner.PackageConfigSha256).ToUpperInvariant() -or
      $reportHash.ToUpperInvariant() -ne ([string]$runner.ReportSha256).ToUpperInvariant() -or
      $reportHash.ToUpperInvariant() -ne ([string]$identity.ReportSha256).ToUpperInvariant() -or
      ([string]$item.SourceSha256).ToUpperInvariant() -ne ([string]$identity.SourceSha256).ToUpperInvariant() -or
      ([string]$runner.PortableBinarySha256).ToUpperInvariant() -ne ([string]$identity.PortableBinarySha256).ToUpperInvariant()) {
      throw "Report/config/source/binary identity mismatch: $reportName"
   }
   $attestations.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; Window=$item.Window
      ExpectedReportName=$reportName; Status=$runner.Status; ConfigSha256=$configHash
      SourceSha256=([string]$item.SourceSha256).ToUpperInvariant()
      PortableBinarySha256=([string]$runner.PortableBinarySha256).ToUpperInvariant()
      ReportSha256=$reportHash.ToUpperInvariant(); ReportBytes=(Get-Item -LiteralPath $reportFull).Length
      IdentityCreatedUtc=$identity.CreatedUtc
      Evidence="Exact portable report identity sidecar and report/config hashes verified."
   }) | Out-Null
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
      SourceType=$item.SourceType; Phase=$item.Phase; Set=$item.Set; Window=$item.Window; From=$item.From; To=$item.To
      Model=$item.Model; Deposit=$item.Deposit; Config=$item.Config; ExpectedReportName=$reportName
      ProfileSnapshot=$item.ProfileSnapshot; ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
      ReferenceSymbol=$item.ReferenceSymbol; ReferenceTimeframe=$item.ReferenceTimeframe
      ReferenceLookbackBars=$item.ReferenceLookbackBars; MinimumReferenceMoveATR=$item.MinimumReferenceMoveATR
      RequireReferenceTrend=$item.RequireReferenceTrend; ReferenceTrendBars=$item.ReferenceTrendBars
      BreakoutLookbackBars=$item.BreakoutLookbackBars; BreakoutBufferATR=$item.BreakoutBufferATR
      TakeProfitR=$item.TakeProfitR; SessionStartHour=$item.SessionStartHour
      Status=$parsed.Status; ReportPath=$reportPath; ReportSha256=$reportHash; ConfigSha256=$configHash
      IdentityPath=$identityFull.Replace($repo + "\", ""); IdentityCreatedUtc=$identity.CreatedUtc
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
$sourcePath = Join-Path $PSScriptRoot "Independent_XAUUSD_M15_TLT_Rates_Impulse.mq5"
$sourceHashes = @($results.SourceSha256 | Sort-Object -Unique)
$binaryHashes = @($results.PortableBinarySha256 | Sort-Object -Unique)
if($sourceHashes.Count -ne 1 -or $binaryHashes.Count -ne 1) { throw "Exact source/binary identity is not uniform." }
if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $sourceHashes[0].ToUpperInvariant()) {
   throw "Current TLT source no longer matches the tested source identity."
}
$attestations | Export-Csv -LiteralPath (Resolve-RepoPath $AttestationPath) -NoTypeInformation -Encoding ASCII
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$summary = [Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq "older_2015_2018" | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq "discovery_2019_2020" | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq "continuous_2015_2020" | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete candidate windows: $($group.Name)" }
   $returnDrawdown = if([double]$continuous.MaxDrawdownMoney -gt 0.0) { [double]$continuous.NetProfit / [double]$continuous.MaxDrawdownMoney } else { 0.0 }
   $pass = [double]$older.NetProfit -gt 0.0 -and [double]$later.NetProfit -gt 0.0 -and `
           [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 100 -and `
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
$centerPass = @($numericPasses | Where-Object Candidate -eq "tltri_center").Count -eq 1
foreach($row in $summary) {
   if($row.NumericPass -ne $true) {
      $row.Decision = "REJECT_BEFORE_HOLDOUT"
      continue
   }
   $adjacent = if($row.Candidate -eq "tltri_center") { $numericPasses.Count -gt 1 } else { $centerPass }
   $row.AdjacentPass = $adjacent
   $row.Decision = if($adjacent) { "DISCOVERY_ELIGIBLE" } else { "REJECT_NO_ADJACENT_SUPPORT" }
}
$eligible = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE" | Sort-Object { [double]$_.ReturnDrawdown } -Descending)
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$feasibilityRows = [Collections.Generic.List[object]]::new()
$commonFiles = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files"
$name = "XAUUSD_TLT_History_Feasibility.csv"
$sourceRows = @(Import-Csv -LiteralPath (Join-Path $commonFiles $name))
foreach($year in 2015..2020) {
   $best = $sourceRows | Where-Object { [int]$_.year -eq $year } | Sort-Object { [int]$_.xau_closed_bars } -Descending | Select-Object -First 1
   if(!$best) { throw "Feasibility evidence missing for $name year $year" }
   $feasibilityRows.Add($best) | Out-Null
}
$feasibilityRows | Sort-Object reference_symbol,{[int]$_.year} | Export-Csv -LiteralPath (Resolve-RepoPath $FeasibilityResultsPath) -NoTypeInformation -Encoding ASCII
$feasibilityMinimum = ($feasibilityRows | Measure-Object alignment_percent -Minimum).Minimum
$lookbackMinimum = ($feasibilityRows | Measure-Object lookback_ready_percent -Minimum).Minimum

$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$attestationHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $AttestationPath) -Algorithm SHA256).Hash
$survivor = $eligible | Select-Object -First 1
$status = if($eligible.Count -gt 0) { "DISCOVERY_SURVIVOR" } else { "REJECTED_IN_DISCOVERY" }
$decision = [pscustomobject]@{
   Status=$status; Candidates=$summary.Count; ReportsParsed=$results.Count; NumericPasses=$numericPasses.Count
   DiscoveryEligible=$eligible.Count; SelectedCandidate=$(if($survivor) { $survivor.Candidate } else { "" })
   HoldoutPermitted=($eligible.Count -gt 0); Model4Opened=$false; NewBest=$false
   SourceSha256=$sourceHashes[0]; PortableBinarySha256=$binaryHashes[0]
   ResultsSha256=$resultsHash; RunAttestationSha256=$attestationHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 TLT Rates-Impulse Discovery Decision")
$md.Add("")
if($eligible.Count -gt 0) {
   $md.Add("**Decision: DISCOVERY SURVIVOR. A frozen 2021+ holdout is permitted for ``$($survivor.Candidate)``; Model 4, new-best promotion, and live approval remain closed.**")
} else {
   $md.Add("**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**")
}
$md.Add("")
$md.Add('The EA tested a date-independent cross-market premise: strength in the last provably completed TLT D1 bar acts as a falling-yields proxy for gold buys, weakness acts as a rising-yields proxy for sells, and a completed XAUUSD M15 breakout confirms entry. All profiles retained broker-native risk sizing, minimum-lot refusal, a `$10,000` contract, account-wide exposure protection, daily/equity loss caps, one trade per day, and disabled real trading.')
$md.Add("")
$md.Add("- Source SHA-256: ``$($sourceHashes[0])``")
$md.Add("- Exact report binary SHA-256: ``$($binaryHashes[0])``")
$md.Add('- Controlled run: `45 / 45` reports, one worker, zero runner errors')
$md.Add('- Risk per accepted trade: `0.10%` on a `$10,000` test deposit')
$md.Add('- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`')
$md.Add("- Numeric gate passes: ``$($numericPasses.Count) / 15``")
$md.Add("- One-factor adjacency passes: ``$($eligible.Count) / 15``")
$md.Add("- History feasibility: TLT D1 aligned on at least ``$feasibilityMinimum%`` of yearly XAUUSD D1 bars; lookback readiness ``$lookbackMinimum%``")
$md.Add("")
$md.Add('| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $($row.OlderProfitFactor) | $($row.OlderTrades) | $(Format-Money $row.LaterNetProfit) | $($row.LaterProfitFactor) | $($row.LaterTrades) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.Decision) |")
}
$md.Add("")
$md.Add("## Interpretation")
$md.Add("")
if($eligible.Count -gt 0) {
   $md.Add("- ``$($survivor.Candidate)`` passed both disjoint eras, the continuous quality/activity gate, and one-factor adjacency.")
   $md.Add('- Freeze the selected source and profile before opening 2021-2026. A holdout failure rejects the family without Model 4 work.')
   $md.Add('- ATB150 remains the research best unless untouched holdout and subsequent real-tick validation both pass.')
} else {
   $best = $summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending | Select-Object -First 1
   $md.Add("- Best continuous result was ``$($best.Candidate)`` at $(Format-Money $best.ContinuousNetProfit), but no profile satisfied the complete broad-era and adjacency contract.")
   $md.Add('- Reject this family without inspecting 2021-2026 or spending real-tick time on it. Keep ATB150 as the research best.')
}
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

@(
   '# Independent M15 TLT Rates-Impulse Metrics','',
   "- Parsed reports: ``$($results.Count) / $($queue.Count)``",
   "- Results SHA-256: ``$resultsHash``",
   "- Run attestation SHA-256: ``$attestationHash``",
   "- Source SHA-256: ``$($sourceHashes[0])``",
   "- Portable binary SHA-256: ``$($binaryHashes[0])``",
   '- Exact binary identities: `1`','- Starting deposit: `$10,000` in every report',
   "- Holdout permitted: ``$(if($eligible.Count -gt 0) { 'YES' } else { 'NO' })``",'- Model 4 opened: `NO`','- New best: `NO`'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII
@(
   '# XAUUSD TLT D1 History Feasibility','',
   'The broker history supports aligned XAUUSD/TLT D1 research over the sealed 2015-2020 discovery period. This proves data availability only; it does not prove the trading strategy. USDX and UUP were unavailable from this broker for the same period.','',
   "- Rows: ``$($feasibilityRows.Count)``", "- Minimum yearly alignment: ``$feasibilityMinimum%``",
   "- Minimum yearly lookback readiness: ``$lookbackMinimum%``", '- Missing yearly evidence: `0`'
) | Set-Content -LiteralPath (Resolve-RepoPath $FeasibilityMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath $rawResults,$rawSummary,$rawMarkdown -Force -ErrorAction SilentlyContinue
$decision
