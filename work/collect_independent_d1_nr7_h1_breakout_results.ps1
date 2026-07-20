param(
   [string]$QueuePath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ReportDir = "outputs\independent_d1_nr7_h1_breakout_discovery_model1_package\reports_here",
   [string]$ParserManifestPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_PARSE_MANIFEST.csv",
   [string]$RawResultsPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RAW_RESULTS.csv",
   [string]$ResultsPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_RUN.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
if($queue.Count -ne 54) { throw "Expected 54 frozen queue rows, found $($queue.Count)." }
if(@($queue | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) {
   throw "Post-2020 data leaked into the discovery collector."
}

$initialRuns = @(Get-ChildItem -LiteralPath (Resolve-RepoPath 'outputs') -Filter 'INDEPENDENT_D1_NR7_H1_BREAKOUT_WORKER_*.csv' |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$recoveryRuns = @(Get-ChildItem -LiteralPath (Resolve-RepoPath 'outputs') -Filter 'INDEPENDENT_D1_NR7_H1_BREAKOUT_RECOVERY_*.csv' |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$canonicalRuns = foreach($queued in $queue) {
   $recovery = @($recoveryRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq 'REPORT_FOUND' })
   $initial = @($initialRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq 'REPORT_FOUND' })
   $selected = if($recovery.Count -gt 0) { $recovery | Select-Object -Last 1 } elseif($initial.Count -gt 0) { $initial | Select-Object -Last 1 } else { $null }
   if($null -eq $selected) { throw "No identity-valid runner result for queue rank $($queued.QueueRank)." }
   if($selected.PackageSourceSha256 -ne $queued.SourceSha256) {
      throw "Runner source identity mismatch at queue rank $($queued.QueueRank)."
   }
   $reportPath = [string]$selected.ReportPath
   if($reportPath.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
      $reportPath = $reportPath.Substring($repo.Length + 1)
   }
   [pscustomobject]@{
      Worker = $selected.Worker
      QueueRank = $selected.QueueRank
      Candidate = $selected.Candidate
      Window = $selected.Window
      Status = $selected.Status
      ReportPath = $reportPath
      Evidence = $selected.Evidence
      PackageConfigSha256 = $selected.PackageConfigSha256
      PackageSourceSha256 = $selected.PackageSourceSha256
      PortableBinarySha256 = $selected.PortableBinarySha256
      PortableExpertRecompiled = $selected.PortableExpertRecompiled
      ReportSha256 = $selected.ReportSha256
      ReportIdentityPath = $selected.ReportIdentityPath
      ReportIdentityReused = $selected.ReportIdentityReused
      Started = $selected.Started
      Finished = $selected.Finished
   }
}
$canonicalRuns | Sort-Object { [int]$_.QueueRank } | Export-Csv -LiteralPath (Resolve-RepoPath $RunPath) -NoTypeInformation -Encoding ASCII

$parserRows = foreach($row in $queue) {
   [pscustomobject]@{
      Rank = $row.QueueRank
      Priority = $row.QueueRank
      Phase = $row.Phase
      Profile = $row.Candidate
      Set = $row.SourceType
      Window = $row.Window
      From = $row.From
      To = $row.To
      ExpectedReportName = $row.ExpectedReportName
      Deposit = $row.Deposit
   }
}
$parserRows | Export-Csv -LiteralPath (Resolve-RepoPath $ParserManifestPath) -NoTypeInformation -Encoding ASCII

& (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $ParserManifestPath -ReportDir $ReportDir `
   -ReportNameTemplate '{ExpectedReportName}' -OutResults $RawResultsPath `
   -OutSummary $SummaryPath -OutMarkdown $MarkdownPath | Out-Null

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $RawResultsPath))
if($raw.Count -ne 54) { throw "Expected 54 parsed result rows, found $($raw.Count)." }

$results = foreach($row in $raw) {
   $queued = @($queue | Where-Object QueueRank -eq $row.Rank)
   if($queued.Count -ne 1) { throw "Queue identity missing or ambiguous for rank $($row.Rank)." }
   $q = $queued[0]
   [pscustomobject]@{
      QueueRank = $q.QueueRank
      Candidate = $q.Candidate
      CandidateRank = $q.CandidateRank
      Phase = $q.Phase
      Window = $q.Window
      From = $q.From
      To = $q.To
      Model = $q.Model
      Deposit = $q.Deposit
      ExpectedReportName = $q.ExpectedReportName
      Status = $row.Status
      ReportPath = $row.ReportPath
      ProfileSha256 = $q.ProfileSha256
      SourceSha256 = $q.SourceSha256
      LookbackDays = $q.LookbackDays
      MaximumSetupRangeATR = $q.MaximumSetupRangeATR
      BreakoutBufferATR = $q.BreakoutBufferATR
      MinimumBodyPercent = $q.MinimumBodyPercent
      MinimumVolumeRatio = $q.MinimumVolumeRatio
      EMAFilter = $q.EMAFilter
      EMAPeriod = $q.EMAPeriod
      ADXFilter = $q.ADXFilter
      TakeProfitR = $q.TakeProfitR
      ChandelierTrail = $q.ChandelierTrail
      InitialDeposit = $row.InitialDeposit
      CalendarDays = $row.CalendarDays
      Years = $row.Years
      NetProfit = $row.NetProfit
      Balance = $row.Balance
      TotalReturnPercent = $row.TotalReturnPercent
      AnnualizedReturnPercent = $row.AnnualizedReturnPercent
      CagrPercent = $row.CagrPercent
      ProfitFactor = $row.ProfitFactor
      ExpectedPayoff = $row.ExpectedPayoff
      SharpeRatio = $row.SharpeRatio
      WinRatePercent = $row.WinRatePercent
      TotalTrades = $row.TotalTrades
      MaxConsecutiveLosses = $row.MaxConsecutiveLosses
      MaxDrawdownMoney = $row.MaxDrawdownMoney
      MaxDrawdownPercent = $row.MaxDrawdownPercent
      RecoveryFactor = $row.RecoveryFactor
   }
}

if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0) {
   $bad = @($results | Where-Object Status -ne 'PARSED' | ForEach-Object { "$($_.QueueRank):$($_.Status)" }) -join ', '
   throw "Every identity-valid report must parse before a decision: $bad"
}
$results | Sort-Object { [int]$_.QueueRank } | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = 'PARSED'
   Reports = $results.Count
   Candidates = @($results.Candidate | Sort-Object -Unique).Count
   SourceSha256 = @($results.SourceSha256 | Sort-Object -Unique)[0]
   LatestData = ($results.To | Sort-Object -Descending | Select-Object -First 1)
}
