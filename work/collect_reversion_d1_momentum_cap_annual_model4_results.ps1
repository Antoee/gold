param(
   [string]$QueuePath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_MANIFEST.csv",
   [string]$ReportDir = "outputs\reversion_d1_momentum_cap_annual_model4_package\reports_here",
   [string]$RawResultsPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RAW_RESULTS.csv",
   [string]$ResultsPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RESULTS.csv",
   [string]$RunPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RUN.csv",
   [string]$SummaryPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_SUMMARY.csv",
   [string]$MarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
if($queue.Count -ne 12) { throw "Expected twelve frozen annual Model4 queue rows." }
if(@($queue | Where-Object { $_.Model -ne "4" -or $_.From -lt "2015.01.01" -or $_.To -gt "2026.07.16" }).Count -gt 0) { throw "Unexpected annual Model4 boundary." }
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity in queue."
}

$initialRuns = @(Get-ChildItem -LiteralPath (Resolve-RepoPath "outputs") -Filter "REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_PORTABLE_*.csv" |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$retryRuns = @(Get-ChildItem -LiteralPath (Resolve-RepoPath "outputs") -Filter "REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_RERUN_*.csv" |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$canonicalRuns = foreach($queued in $queue) {
   $retry = @($retryRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq "REPORT_FOUND" })
   $initial = @($initialRuns | Where-Object { $_.QueueRank -eq $queued.QueueRank -and $_.Status -eq "REPORT_FOUND" })
   $selected = if($retry.Count -gt 0) { $retry | Select-Object -Last 1 } elseif($initial.Count -gt 0) { $initial | Select-Object -Last 1 } else { $null }
   if($null -eq $selected) { throw "No identity-valid runner result for rank $($queued.QueueRank)." }
   if($selected.PackageSourceSha256 -ne $queued.SourceSha256) { throw "Runner source mismatch at rank $($queued.QueueRank)." }
   $reportPath = [string]$selected.ReportPath
   if($reportPath.StartsWith($repo + "\", [StringComparison]::OrdinalIgnoreCase)) {
      $reportPath = $reportPath.Substring($repo.Length + 1)
   }
   [pscustomobject]@{
      Worker=$selected.Worker;QueueRank=$queued.QueueRank;Candidate=$queued.Candidate;Window=$queued.Window
      Status=$selected.Status;ReportPath=$reportPath;Evidence=$selected.Evidence
      PackageSourceSha256=$selected.PackageSourceSha256;PortableBinarySha256=$selected.PortableBinarySha256
      PortableExpertRecompiled=$selected.PortableExpertRecompiled;Started=$selected.Started;Finished=$selected.Finished
   }
}
$canonicalRuns | Sort-Object { [int]$_.QueueRank } |
   Export-Csv -LiteralPath (Resolve-RepoPath $RunPath) -NoTypeInformation -Encoding ASCII

& (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir `
   -ReportNameTemplate "{ExpectedReportName}" -OutResults $RawResultsPath `
   -OutSummary $SummaryPath -OutMarkdown $MarkdownPath | Out-Null

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $RawResultsPath))
if($raw.Count -ne 12) { throw "Expected twelve parsed annual Model4 results." }
$results = foreach($queued in $queue) {
   $matches = @($raw | Where-Object ExpectedReportName -eq $queued.ExpectedReportName)
   if($matches.Count -ne 1) { throw "Result missing or ambiguous for rank $($queued.QueueRank)." }
   $row = $matches[0]
   $reportPath = [string]$row.ReportPath
   if($reportPath.StartsWith($repo + "\", [StringComparison]::OrdinalIgnoreCase)) {
      $reportPath = $reportPath.Substring($repo.Length + 1)
   }
   [pscustomobject]@{
      QueueRank=$queued.QueueRank;Candidate=$queued.Candidate;Window=$queued.Window
      From=$queued.From;To=$queued.To;Model=$queued.Model;Deposit=$queued.Deposit
      ExpectedReportName=$queued.ExpectedReportName;Status=$row.Status;ReportPath=$reportPath
      ProfileSha256=$queued.ProfileSha256;SourceSha256=$queued.SourceSha256
      Model4ContractSha256=$queued.Model4ContractSha256
      AnnualContractSha256=$queued.AnnualContractSha256;InitialDeposit=$row.InitialDeposit
      NetProfit=$row.NetProfit;Balance=$row.Balance;TotalReturnPercent=$row.TotalReturnPercent
      AnnualizedReturnPercent=$row.AnnualizedReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;ExpectedPayoff=$row.ExpectedPayoff;SharpeRatio=$row.SharpeRatio
      WinRatePercent=$row.WinRatePercent;TotalTrades=$row.TotalTrades;MaxConsecutiveLosses=$row.MaxConsecutiveLosses
      MaxDrawdownMoney=$row.MaxDrawdownMoney;MaxDrawdownPercent=$row.MaxDrawdownPercent
      BalanceDrawdownMaximal=$row.BalanceDrawdownMaximal;EquityDrawdownMaximal=$row.EquityDrawdownMaximal
      RecoveryFactor=$row.RecoveryFactor
   }
}
if(@($results | Where-Object Status -ne "PARSED").Count -gt 0) { throw "Every report must parse." }
$results | Sort-Object { [int]$_.QueueRank } |
   Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{Status="PARSED";Reports=$results.Count;Profiles=@($results.Candidate | Sort-Object -Unique).Count}
