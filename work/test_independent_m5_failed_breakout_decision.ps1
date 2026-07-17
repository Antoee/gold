param(
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DECISION.md",
   [string]$ResultsPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath))
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$markdown = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Raw
if($decision.Count -ne 12) { throw "Expected 12 M5 decision rows." }
if($results.Count -ne 24 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 24 parsed M5 results." }
if(@($queue | Where-Object { [datetime]$_.To -gt [datetime]'2020-12-31' -or $_.Model -ne '1' -or $_.SignalTimeframe -ne '5' }).Count -ne 0) {
   throw "M5 queue used forbidden data, model, or timeframe."
}
if(@($decision | Where-Object { $_.Verdict -ne 'REJECTED_BROAD_ERAS' -or $_.DiscoveryGatePass -ne 'False' }).Count -ne 0) {
   throw "A failed M5 candidate was not rejected."
}
if(@($decision | Where-Object { [double]$_.OlderNetProfit -ge 0 -or [double]$_.NewerNetProfit -ge 0 }).Count -ne 0) {
   throw "Expected every M5 candidate to lose both eras."
}
if(@($decision | Where-Object { $_.ContinuousOpened -ne 'False' -or $_.RecentDataOpened -ne 'False' -or $_.Model4Opened -ne 'False' }).Count -ne 0) {
   throw "A forbidden M5 follow-up phase was opened."
}
foreach($token in @('**Rejected. No new best','Model1 reports: `24/24`','Profitable in both eras: `0/12`','At least 100 trades in both eras: `0/12`','Model4 rows: `0`')) {
   if($markdown.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Decision markdown token missing: $token" }
}
[pscustomobject]@{
   Status='PASS'; Candidates=12; ParsedReports=24; ProfitableBoth=0; ActivityBoth=0
   GatePasses=0; Post2020Rows=0; Model4Rows=0; RealPromotion=$false
}
