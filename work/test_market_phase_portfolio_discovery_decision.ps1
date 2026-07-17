param(
   [string]$ResultsPath = "outputs\MARKET_PHASE_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\MARKET_PHASE_PORTFOLIO_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DecisionPath = "outputs\MARKET_PHASE_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$SourcePath = "work\Professional_XAUUSD_Market_Phase_Portfolio.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$summary = @(Import-Csv -LiteralPath (Resolve-RepoPath $SummaryPath))
$decisionRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionPath))
if($results.Count -ne 24 -or @($results.Candidate | Sort-Object -Unique).Count -ne 8) { throw "Discovery result shape changed." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "A final report is unparsed." }
if(@($results | Where-Object ReportSourceIdentityPass -ne "True").Count -ne 0) { throw "A final report failed source identity." }
if(@($results | Where-Object { $_.To -gt "2020.12.31" }).Count -ne 0) { throw "Holdout data was opened." }
$sourceHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $SourcePath) -Algorithm SHA256).Hash
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].SourceSha256 -ne $sourceHash) { throw "Checked-out source hash differs from result identity." }
if($decisionRows.Count -ne 1) { throw "Expected one decision row." }
$eligible = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE")
$decision = $decisionRows[0]
$expected = if($eligible.Count -gt 0) { "DISCOVERY_ELIGIBLE" } else { "REJECTED_IN_DISCOVERY" }
if($decision.Status -ne $expected -or [int]$decision.DiscoveryEligible -ne $eligible.Count) { throw "Decision does not match summary." }
if(@($summary | Where-Object { $_.Candidate -eq 'mpp_fixed_control' -and $_.Decision -ne 'CONTROL_ONLY' }).Count -ne 0) { throw "Fixed-risk control became promotable." }
if($decision.HoldoutOpened -ne "False" -or $decision.Model4Opened -ne "False") { throw "Later evidence opened prematurely." }
$resultsHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
if($decision.ResultsSha256 -ne $resultsHash) { throw "Decision/results identity mismatch." }
[pscustomobject]@{ Status="PASS"; Decision=$decision.Status; Reports=24; Candidates=8; IdentityPasses=24; DiscoveryEligible=$eligible.Count; HoldoutOpened=$false; Model4Opened=$false; SourceSha256=$sourceHash; ResultsSha256=$resultsHash }
