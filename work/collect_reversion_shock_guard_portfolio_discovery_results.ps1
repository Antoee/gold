param(
   [string]$QueuePath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$ReportDir = "outputs\reversion_shock_guard_portfolio_discovery_model1_package\reports_here",
   [string]$RawResultsPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RAW_RESULTS.csv",
   [string]$ResultsPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv",
   [string]$SummaryPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MarkdownPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = 'A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9'
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
if($queue.Count -ne 56) { throw "Expected 56 frozen queue rows, found $($queue.Count)." }
if(@($queue | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) { throw "Post-2020 data leaked into discovery." }
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity in the queue."
}

$initialRuns = @(Get-ChildItem -LiteralPath (Resolve-RepoPath 'outputs') -Filter 'REVERSION_SHOCK_GUARD_PORTABLE_*.csv' |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$retryRuns = @(Get-ChildItem -LiteralPath (Resolve-RepoPath 'outputs') -Filter 'REVERSION_SHOCK_GUARD_RETRY_*.csv' |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$canonicalRuns = foreach($queued in $queue) {
   $retry = @($retryRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq 'REPORT_FOUND' })
   $initial = @($initialRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq 'REPORT_FOUND' })
   $selected = if($retry.Count -gt 0) { $retry | Select-Object -Last 1 } elseif($initial.Count -gt 0) { $initial | Select-Object -Last 1 } else { $null }
   if($null -eq $selected) { throw "No identity-valid runner result for rank $($queued.QueueRank)." }
   if($selected.PackageSourceSha256 -ne $queued.SourceSha256) { throw "Runner source mismatch at rank $($queued.QueueRank)." }
   $reportPath = [string]$selected.ReportPath
   if($reportPath.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
      $reportPath = $reportPath.Substring($repo.Length + 1)
   }
   [pscustomobject]@{
      Worker=$selected.Worker;QueueRank=$selected.QueueRank;Candidate=$selected.Candidate;Window=$selected.Window
      Status=$selected.Status;ReportPath=$reportPath;Evidence=$selected.Evidence
      PackageSourceSha256=$selected.PackageSourceSha256;PortableBinarySha256=$selected.PortableBinarySha256
      PortableExpertRecompiled=$selected.PortableExpertRecompiled;Started=$selected.Started;Finished=$selected.Finished
   }
}
$canonicalRuns | Sort-Object { [int]$_.QueueRank } | Export-Csv -LiteralPath (Resolve-RepoPath $RunPath) -NoTypeInformation -Encoding ASCII

& (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir `
   -ReportNameTemplate '{ExpectedReportName}' -OutResults $RawResultsPath `
   -OutSummary $SummaryPath -OutMarkdown $MarkdownPath | Out-Null

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $RawResultsPath))
if($raw.Count -ne 56) { throw "Expected 56 parsed result rows, found $($raw.Count)." }
$results = foreach($row in $raw) {
   $queued = @($queue | Where-Object QueueRank -eq $row.Rank)
   if($queued.Count -ne 1) { throw "Queue identity missing or ambiguous for rank $($row.Rank)." }
   $q = $queued[0]
   [pscustomobject]@{
      QueueRank=$q.QueueRank;Candidate=$q.Candidate;Role=$q.Role;Phase=$q.Phase;Window=$q.Window
      From=$q.From;To=$q.To;Model=$q.Model;Deposit=$q.Deposit;ExpectedReportName=$q.ExpectedReportName
      Status=$row.Status;ReportPath=$row.ReportPath;ProfileSha256=$q.ProfileSha256;SourceSha256=$q.SourceSha256
      RunLabel=$q.RunLabel;RVRiskPercent=$q.RVRiskPercent;MORiskPercent=$q.MORiskPercent
      RVMinimumDIEdge=$q.RVMinimumDIEdge;RVUseMinimumBodyGate=$q.RVUseMinimumBodyGate
      RVMinimumBodyPercent=$q.RVMinimumBodyPercent;InitialDeposit=$row.InitialDeposit;CalendarDays=$row.CalendarDays
      Years=$row.Years;NetProfit=$row.NetProfit;Balance=$row.Balance;TotalReturnPercent=$row.TotalReturnPercent
      AnnualizedReturnPercent=$row.AnnualizedReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;ExpectedPayoff=$row.ExpectedPayoff;SharpeRatio=$row.SharpeRatio
      WinRatePercent=$row.WinRatePercent;TotalTrades=$row.TotalTrades;MaxConsecutiveLosses=$row.MaxConsecutiveLosses
      MaxDrawdownMoney=$row.MaxDrawdownMoney;MaxDrawdownPercent=$row.MaxDrawdownPercent;RecoveryFactor=$row.RecoveryFactor
   }
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0) {
   $bad = @($results | Where-Object Status -ne 'PARSED' | ForEach-Object { "$($_.QueueRank):$($_.Status)" }) -join ', '
   throw "Every identity-valid report must parse before a decision: $bad"
}
$results | Sort-Object { [int]$_.QueueRank } | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status='PARSED';Reports=$results.Count;Profiles=@($results.Candidate | Sort-Object -Unique).Count
   SourceSha256=$expectedSourceHash;LatestData=($results.To | Sort-Object -Descending | Select-Object -First 1)
}
