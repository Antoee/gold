param(
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DECISION.md",
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$FeasibilityPath = "outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath))
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$feasibility = @(Import-Csv -LiteralPath (Resolve-RepoPath $FeasibilityPath) | Where-Object { [int]$_.year -ge 2015 -and [int]$_.year -le 2020 })
$markdown = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Raw
if($decision.Count -ne 16) { throw "Expected 16 decision rows." }
if(@($decision | Where-Object Verdict -ne 'REJECTED_BROAD_ERAS').Count -ne 0) { throw "A failed family was not fully rejected." }
if(@($decision | Where-Object DiscoveryGatePass -eq 'True').Count -ne 0) { throw "Unexpected discovery gate pass." }
if(@($decision | Where-Object { [double]$_.OlderNetProfit -ge 0 -or [double]$_.NewerNetProfit -ge 0 }).Count -ne 0) {
   throw "Expected every synchronized-continuation candidate to lose both eras."
}
if(@($decision | Where-Object { $_.ContinuousOpened -ne 'False' -or $_.RecentDataOpened -ne 'False' -or $_.Model4Opened -ne 'False' }).Count -ne 0) {
   throw "A forbidden follow-up phase was opened."
}
if($results.Count -ne 32 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 32 parsed strategy reports." }
if(@($queue | Where-Object { [datetime]$_.To -gt [datetime]'2020-12-31' -or $_.Model -ne '1' }).Count -ne 0) { throw "Queue used forbidden data or model." }
if($feasibility.Count -lt 6 -or @($feasibility | Where-Object { [double]$_.alignment_percent -lt 99.9 -or [double]$_.lookback_ready_percent -lt 100.0 }).Count -ne 0) {
   throw "Pre-2021 XAGUSD history feasibility is not proven."
}
foreach($token in @('**Rejected. No new best','Profitable in both eras: `0/16`','Full discovery gate passes: `0/16`','Post-2020 strategy rows: `0`','Model4 rows: `0`')) {
   if($markdown.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Decision markdown token missing: $token" }
}
[pscustomobject]@{ Status='PASS'; Candidates=16; ParsedReports=32; GatePasses=0; Post2020Rows=0; Model4Rows=0; RealPromotion=$false }
