param(
   [string]$ResultsCsv = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueueCsv = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$DecisionCsv = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "1A5799C5829D0E7108F60CBB331EB98BE39DACD0422C592020B6973C17147F26"
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)){return $Path}; return Join-Path $repo $Path }

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsCsv))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueCsv))
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($results.Count -ne 42 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 42 parsed results." }
if(@($results | Where-Object { $_.To -gt "2020.12.31" }).Count -ne 0) { throw "Post-2020 data leaked into discovery." }
if($queue.Count -ne 42 -or @($queue.SourceSha256 | Where-Object { $_ -ne $expectedSourceHash }).Count -ne 0) { throw "Source identity changed." }
foreach($result in $results) {
   $queued = @($queue | Where-Object QueueRank -eq $result.QueueRank)
   if($queued.Count -ne 1 -or $queued[0].ProfileSha256 -ne $result.ProfileSha256) { throw "Result-to-queue mismatch at $($result.QueueRank)." }
}
if($decision.Count -ne 14) { throw "Expected fourteen candidate decisions." }
if(@($decision | Where-Object Decision -ne "REJECTED_NO_RECENT_NO_MODEL4").Count -ne 0) { throw "Every candidate must be rejected." }
if(@($decision | Where-Object { $_.BothDisjointErasPositive -ne "False" -or $_.DiscoveryGatePass -ne "False" }).Count -ne 0) { throw "A candidate incorrectly passed." }
if(@($decision | Where-Object { [double]$_.Older2015To2018Net -ge 0 -or [double]$_.Continuous2015To2020Net -ge 0 }).Count -ne 0) { throw "Expected negative older and continuous results for every candidate." }

$lead = @($decision | Sort-Object { [double]$_.Continuous2015To2020Net } -Descending | Select-Object -First 1)
if($lead.Count -ne 1 -or $lead[0].Candidate -ne "pwbr_adx18") { throw "Unexpected least-bad candidate." }
if([math]::Abs([double]$lead[0].Older2015To2018Net - (-57.20)) -gt 0.001 -or
   [math]::Abs([double]$lead[0].Newer2019To2020Net - 33.05) -gt 0.001 -or
   [math]::Abs([double]$lead[0].Continuous2015To2020Net - (-24.15)) -gt 0.001 -or
   [math]::Abs([double]$lead[0].ContinuousProfitFactor - 0.81) -gt 0.001 -or
   [int]$lead[0].ContinuousTrades -ne 24) { throw "Lead rejection metrics changed." }

$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @("No 2021-2026 retrospective run was opened", "Model 4 was skipped", "no new best was promoted", "every continuous 2015-2020 row was negative", "real-account trading remains disabled")) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Decision token missing: $token" }
}

[pscustomobject]@{ Status="PASS"; Results=$results.Count; Candidates=$decision.Count; Rejected=14; GatePasses=0; RecentAllowed=$false; Model4Allowed=$false }
