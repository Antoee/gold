param(
   [string]$ResultsCsv = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueueCsv = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$DecisionCsv = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "DE93CFC433C0F3A9B19A6F8D58AAF32894FC8FE6DC41F98A3745FD209C787E8E"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsCsv))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueCsv))
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($results.Count -ne 30 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected 30 parsed discovery results."
}
if(@($results | Where-Object { $_.To -gt "2020.12.31" }).Count -ne 0) {
   throw "Post-2020 data leaked into discovery evidence."
}
if($queue.Count -ne 30 -or @($queue.SourceSha256 | Where-Object { $_ -ne $expectedSourceHash }).Count -ne 0) {
   throw "Discovery source identity changed."
}
foreach($result in $results) {
   $queued = @($queue | Where-Object QueueRank -eq $result.QueueRank)
   if($queued.Count -ne 1 -or $queued[0].ProfileSha256 -ne $result.ProfileSha256) {
      throw "Result-to-queue identity mismatch at rank $($result.QueueRank)."
   }
}
if($decision.Count -ne 10) { throw "Expected ten candidate decisions." }
if(@($decision | Where-Object Decision -ne "REJECTED_NO_RECENT_NO_MODEL4").Count -ne 0) {
   throw "Every previous-day sweep candidate must be rejected before recent data and Model 4."
}
if(@($decision | Where-Object { $_.BothDisjointErasPositive -ne "False" -or $_.DiscoveryGatePass -ne "False" }).Count -ne 0) {
   throw "A candidate incorrectly passed the disjoint-era discovery gate."
}
if(@($decision | Where-Object { [double]$_.Older2015To2018Net -ge 0 }).Count -ne 0) {
   throw "Every tested candidate must reproduce a negative 2015-2018 result."
}

$lead = @($decision | Sort-Object { [double]$_.Continuous2015To2020Net } -Descending | Select-Object -First 1)
if($lead.Count -ne 1 -or $lead[0].Candidate -ne "pds_volume105") { throw "Unexpected least-bad continuous candidate." }
if([math]::Abs([double]$lead[0].Older2015To2018Net - (-37.94)) -gt 0.001 -or
   [math]::Abs([double]$lead[0].Newer2019To2020Net - 75.00) -gt 0.001 -or
   [math]::Abs([double]$lead[0].Continuous2015To2020Net - 37.06) -gt 0.001 -or
   [int]$lead[0].ContinuousTrades -ne 46) {
   throw "Lead rejection metrics changed."
}

$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @(
   "No 2021-2026 retrospective run was opened",
   "Model 4 was skipped",
   "no new best was promoted",
   "Every tested configuration lost money in the older 2015-2018 era",
   "real-account trading remains disabled"
)) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Decision token missing: $token"
   }
}

[pscustomobject]@{
   Status = "PASS"
   Results = $results.Count
   Candidates = $decision.Count
   Rejected = @($decision | Where-Object Decision -eq "REJECTED_NO_RECENT_NO_MODEL4").Count
   GatePasses = @($decision | Where-Object DiscoveryGatePass -eq "True").Count
   RecentAllowed = $false
   Model4Allowed = $false
}
