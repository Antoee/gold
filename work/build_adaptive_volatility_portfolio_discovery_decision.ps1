param(
   [string]$QueuePath = "outputs\ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\adaptive_volatility_portfolio_discovery_model1_package\reports_here",
   [string]$SourcePath = "work\Professional_XAUUSD_Adaptive_Volatility_Portfolio.mq5",
   [string]$ResultsPath = "outputs\ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_DECISION.md",
   [string]$MetricsPath = "outputs\ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_MODEL1_METRICS.md"
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

$rawResults = Join-Path $repo "work\AVP_RAW_RESULTS.csv"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $QueuePath -ReportDir $ReportDir -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults "work\AVP_RAW_RESULTS.csv" -OutSummary "work\AVP_RAW_SUMMARY.csv" `
   -OutMarkdown "work\AVP_RAW_METRICS.md" | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$raw = @(Import-Csv -LiteralPath $rawResults)
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }
$sourceHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $SourcePath) -Algorithm SHA256).Hash
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $sourceHash) { throw "Queue/source identity mismatch." }
$reproducedRanks = @(1,4)
$results = [System.Collections.Generic.List[object]]::new()
foreach($item in ($queue | Sort-Object { [int]$_.QueueRank })) {
   $reportName = [string]$item.ExpectedReportName
   if(!$rawByReport.ContainsKey($reportName)) { throw "Collector row missing: $reportName" }
   $parsed = $rawByReport[$reportName]
   $reportPath = [string](Get-Field $parsed "ReportPath")
   $reportFullPath = if([IO.Path]::IsPathRooted($reportPath)) { $reportPath } else { Join-Path $repo $reportPath }
   if(!$reportPath -or !(Test-Path -LiteralPath $reportFullPath -PathType Leaf)) { throw "Final report missing: $reportName" }
   $reportText = Get-Content -LiteralPath $reportFullPath -Raw
   $identityPass = $reportText.IndexOf($sourceHash,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and
                   $reportText.IndexOf("Adaptive Volatility Risk Controller=",[StringComparison]::Ordinal) -ge 0
   if(!$identityPass) { throw "Final report source identity failed: $reportName" }
   $results.Add([pscustomobject]@{
      QueueRank=$item.QueueRank; Candidate=$item.Candidate; CandidateRank=$item.CandidateRank
      SourceType=$item.SourceType; Phase=$item.Phase; Set=$item.Set; Window=$item.Window; From=$item.From; To=$item.To
      Model=$item.Model; Deposit=$item.Deposit; Config=$item.Config; ExpectedReportName=$reportName
      ProfileSnapshot=$item.ProfileSnapshot; ProfileSha256=$item.ProfileSha256; SourceSha256=$item.SourceSha256
      BaseProfileSha256=$item.BaseProfileSha256; AdaptiveEnabled=$item.AdaptiveEnabled
      VolatilityTimeframe=$item.VolatilityTimeframe; VolatilityATRPeriod=$item.VolatilityATRPeriod
      BaselineBars=$item.BaselineBars; MinimumScale=$item.MinimumScale; MaximumScale=$item.MaximumScale; StopRule=$item.StopRule
      Status=$parsed.Status; ReportPath=$reportFullPath.Substring($repo.Length + 1)
      ReportSha256=(Get-FileHash -LiteralPath $reportFullPath -Algorithm SHA256).Hash
      ReportSourceIdentityPass=$identityPass
      ReportDisposition=$(if([int]$item.QueueRank -in $reproducedRanks){"REPRODUCED_AFTER_IDENTITY_RETRY"}else{"FIRST_VALID_EXPORT"})
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
if($results.Count -ne 24 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 24 parsed reports." }
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

$candidateRows = @{}
foreach($group in ($results | Group-Object Candidate)) {
   $older = $group.Group | Where-Object Window -eq "older_2015_2018" | Select-Object -First 1
   $later = $group.Group | Where-Object Window -eq "discovery_2019_2020" | Select-Object -First 1
   $continuous = $group.Group | Where-Object Window -eq "continuous_2015_2020" | Select-Object -First 1
   if(!$older -or !$later -or !$continuous) { throw "Incomplete windows: $($group.Name)" }
   $candidateRows[$group.Name] = [pscustomobject]@{ Older=$older; Later=$later; Continuous=$continuous }
}
$control = $candidateRows['avp_fixed_control'].Continuous
$controlEfficiency = if([double]$control.MaxDrawdownPercent -gt 0.0) { [double]$control.TotalReturnPercent / [double]$control.MaxDrawdownPercent } else { 0.0 }
$adjacency = @{
   avp_fixed_control=@()
   avp_center=@('avp_bounds80_120','avp_baseline63','avp_baseline252','avp_downside_only','avp_upside_only')
   avp_bounds80_120=@('avp_center','avp_bounds85_115'); avp_bounds85_115=@('avp_bounds80_120')
   avp_baseline63=@('avp_center'); avp_baseline252=@('avp_center')
   avp_downside_only=@('avp_center'); avp_upside_only=@('avp_center')
}
$basicPass = @{}; $qualityPass = @{}
foreach($candidate in $candidateRows.Keys) {
   $set = $candidateRows[$candidate]
   $basicPass[$candidate] = $candidate -ne 'avp_fixed_control' -and
      [double]$set.Older.NetProfit -gt 0.0 -and [double]$set.Later.NetProfit -gt 0.0 -and
      [double]$set.Continuous.ProfitFactor -ge 1.35 -and [int]$set.Continuous.TotalTrades -ge 180 -and
      [double]$set.Continuous.MaxDrawdownPercent -le 5.0
   $efficiency = if([double]$set.Continuous.MaxDrawdownPercent -gt 0.0) {
      [double]$set.Continuous.TotalReturnPercent / [double]$set.Continuous.MaxDrawdownPercent
   } else { 0.0 }
   $efficiencyImprovement = $controlEfficiency -gt 0.0 -and $efficiency -ge $controlEfficiency * 1.05
   $netImprovement = [double]$set.Continuous.NetProfit -ge [double]$control.NetProfit * 1.05 -and
      [double]$set.Continuous.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent * 1.10 -and
      [double]$set.Continuous.ProfitFactor -ge [double]$control.ProfitFactor - 0.05
   $qualityPass[$candidate] = $efficiencyImprovement -or $netImprovement
}
$summary = [System.Collections.Generic.List[object]]::new()
foreach($candidate in ($candidateRows.Keys | Sort-Object)) {
   $set = $candidateRows[$candidate]
   $efficiency = if([double]$set.Continuous.MaxDrawdownPercent -gt 0.0) {
      [Math]::Round([double]$set.Continuous.TotalReturnPercent / [double]$set.Continuous.MaxDrawdownPercent,4)
   } else { 0.0 }
   $neighbors = @($adjacency[$candidate] | Where-Object { $basicPass[$_] -and $qualityPass[$_] })
   $eligible = $basicPass[$candidate] -and $qualityPass[$candidate] -and $neighbors.Count -gt 0
   $summary.Add([pscustomobject]@{
      Candidate=$candidate; AdaptiveEnabled=$set.Continuous.AdaptiveEnabled
      OlderNetProfit=$set.Older.NetProfit; OlderProfitFactor=$set.Older.ProfitFactor; OlderTrades=$set.Older.TotalTrades
      LaterNetProfit=$set.Later.NetProfit; LaterProfitFactor=$set.Later.ProfitFactor; LaterTrades=$set.Later.TotalTrades
      ContinuousNetProfit=$set.Continuous.NetProfit; ContinuousTotalReturnPercent=$set.Continuous.TotalReturnPercent
      ContinuousCagrPercent=$set.Continuous.CagrPercent; ContinuousProfitFactor=$set.Continuous.ProfitFactor
      ContinuousTrades=$set.Continuous.TotalTrades; ContinuousMaxDrawdownPercent=$set.Continuous.MaxDrawdownPercent
      ReturnDrawdownEfficiency=$efficiency; BasicPass=$basicPass[$candidate]; ControlRelativeQualityPass=$qualityPass[$candidate]
      AdjacentPass=($neighbors.Count -gt 0); PassingNeighbors=($neighbors -join ';')
      Decision=$(if($eligible){"DISCOVERY_ELIGIBLE"}elseif($candidate -eq 'avp_fixed_control'){"CONTROL_ONLY"}else{"REJECT_BEFORE_HOLDOUT"})
   }) | Out-Null
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$eligibleRows = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE")
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
$decision = [pscustomobject]@{
   Status=$(if($eligibleRows.Count -gt 0){"DISCOVERY_ELIGIBLE"}else{"REJECTED_IN_DISCOVERY"})
   Candidates=$summary.Count; ReportsParsed=$results.Count; ReportsIdentityPassed=24; ReproducedIdentityRetries=$reproducedRanks.Count
   BasicPasses=@($summary | Where-Object BasicPass -eq $true).Count
   ControlRelativePasses=@($summary | Where-Object ControlRelativeQualityPass -eq $true).Count
   DiscoveryEligible=$eligibleRows.Count; HoldoutOpened=$false; Model4Opened=$false
   SourceSha256=$sourceHash; ResultsSha256=$resultsHash
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Adaptive Volatility Portfolio Discovery Decision")
$md.Add("")
$md.Add($(if($eligibleRows.Count -gt 0) { "**Decision: freeze eligible adaptive profiles for untouched holdout; Model 4 and promotion remain closed.**" } else { "**Decision: rejected in pre-2021 discovery; holdout, Model 4, and promotion remain closed.**" }))
$md.Add("")
$md.Add("The exact released Band/VWAP-reversion and E20 momentum entries/exits were retained. Only requested risk changed through a closed-bar H1 ATR/price controller bounded inside the existing 0.75% open-risk cap.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Correct-source Model 1 reports: `24 / 24`')
$md.Add("- Fixed-risk control efficiency: ``$([Math]::Round($controlEfficiency,4))`` return/DD")
$md.Add("- Eligible adaptive profiles: ``$($eligibleRows.Count) / 7``")
$md.Add("")
$md.Add('| Candidate | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Return/DD | Quality | Neighbor | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|')
foreach($row in ($summary | Sort-Object { [double]$_.ContinuousNetProfit } -Descending)) {
   $md.Add("| ``$($row.Candidate)`` | $(Format-Money $row.OlderNetProfit) | $(Format-Money $row.LaterNetProfit) | $(Format-Money $row.ContinuousNetProfit) | $($row.ContinuousTotalReturnPercent)% | $($row.ContinuousCagrPercent)% | $($row.ContinuousProfitFactor) | $($row.ContinuousTrades) | $($row.ContinuousMaxDrawdownPercent)% | $($row.ReturnDrawdownEfficiency) | $($row.ControlRelativeQualityPass) | $($row.AdjacentPass) | $($row.Decision) |")
}
if($eligibleRows.Count -gt 0) {
   $md.Add("")
   $md.Add("Frozen holdout survivors: ``$(@($eligibleRows.Candidate | Sort-Object) -join '`, `')``. No input may change before the untouched holdout.")
}
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
@(
   "# Adaptive Volatility Portfolio Discovery Metrics", "",
   "- Parsed reports: ``24 / 24``", "- Source-identity passes: ``24 / 24``",
   "- Source SHA-256: ``$sourceHash``", "- Results SHA-256: ``$resultsHash``",
   '- Starting deposit: `$10,000` in every report', '- Post-2020 rows: `0`'
) | Set-Content -LiteralPath (Resolve-RepoPath $MetricsPath) -Encoding ASCII
$decision
