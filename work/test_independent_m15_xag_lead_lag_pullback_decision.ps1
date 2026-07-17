param(
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DECISION.md",
   [string]$DiscoveryResultsPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DiscoveryQueuePath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$NeighborhoodResultsPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_MODEL1_RESULTS.csv",
   [string]$NeighborhoodQueuePath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_MODEL1_QUEUE.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath))
$discovery = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryResultsPath))
$discoveryQueue = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryQueuePath))
$neighborhood = @(Import-Csv -LiteralPath (Resolve-RepoPath $NeighborhoodResultsPath))
$neighborhoodQueue = @(Import-Csv -LiteralPath (Resolve-RepoPath $NeighborhoodQueuePath))
$markdown = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Raw
if($decision.Count -ne 21) { throw "Expected 21 unique candidate rows." }
if($discovery.Count -ne 32 -or $neighborhood.Count -ne 12) { throw "Expected all 44 parsed report rows." }
if(@($discovery + $neighborhood | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "An evidence report was not parsed." }
if(@($discoveryQueue + $neighborhoodQueue | Where-Object { [datetime]$_.To -gt [datetime]'2020-12-31' -or $_.Model -ne '1' }).Count -ne 0) {
   throw "Evidence used forbidden data or a forbidden model."
}
if(@($decision | Where-Object { $_.PromotionGatePass -ne 'False' -or $_.ContinuousOpened -ne 'False' -or $_.RecentDataOpened -ne 'False' -or $_.Model4Opened -ne 'False' }).Count -ne 0) {
   throw "A forbidden lead-lag promotion phase was opened."
}
$lead4 = @($decision | Where-Object Candidate -eq 'xmll_lead4')
if($lead4.Count -ne 1 -or $lead4[0].Verdict -ne 'REJECTED_ISOLATED_LOOKBACK' -or
   $lead4[0].NumericGatePass -ne 'True' -or $lead4[0].NeighborhoodReproduced -ne 'True' -or
   $lead4[0].AdjacentSupportPass -ne 'False') {
   throw "Lead-4 isolation decision is inconsistent."
}
foreach($candidate in @('xmll_lead3','xmll_lead5')) {
   $row = @($decision | Where-Object Candidate -eq $candidate)
   if($row.Count -ne 1 -or [double]$row[0].OlderNetProfit -ge 0 -or [double]$row[0].NewerNetProfit -ge 0) {
      throw "Adjacent candidate $candidate did not record two losing eras."
   }
}
foreach($token in @('**Rejected. The four-bar lead result reproduced','Model1 reports: `44/44`','Adjacent lead-3/lead-5 gate passes: `0/2`','Post-2020 strategy rows: `0`','Model4 rows: `0`')) {
   if($markdown.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Decision markdown token missing: $token" }
}
[pscustomobject]@{
   Status='PASS'; UniqueCandidates=21; ParsedReports=44; Lead4Reproduced=$true
   AdjacentPasses=0; PromotionPasses=0; Post2020Rows=0; Model4Rows=0; RealPromotion=$false
}
