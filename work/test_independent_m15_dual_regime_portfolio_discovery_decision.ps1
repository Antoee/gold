param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DecisionPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Dual_Regime_Portfolio.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$summary = @(Import-Csv -LiteralPath (Resolve-RepoPath $SummaryPath))
$decisionRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionPath))
if($results.Count -ne 45) { throw "Expected 45 final reports." }
if(@($results.Candidate | Sort-Object -Unique).Count -ne 15) { throw "Expected 15 candidates." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "A final report is unparsed." }
if(@($results | Where-Object ReportSourceIdentityPass -ne "True").Count -ne 0) { throw "A final report failed source identity." }
$sourceHash = (Get-FileHash -LiteralPath (Resolve-RepoPath $SourcePath) -Algorithm SHA256).Hash
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].SourceSha256 -ne $sourceHash) { throw "Checked-out source hash differs from the tested result identity." }
if(@($results | Where-Object { $_.Window -notin @("older_2015_2018","discovery_2019_2020","continuous_2015_2020") }).Count -ne 0) { throw "Holdout data was opened." }
if($decisionRows.Count -ne 1) { throw "Expected one decision row." }
$decision = $decisionRows[0]
$eligible = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE")
$expectedStatus = if($eligible.Count -gt 0) { "DISCOVERY_ELIGIBLE" } else { "REJECTED_IN_DISCOVERY" }
if($decision.Status -ne $expectedStatus -or [int]$decision.DiscoveryEligible -ne $eligible.Count) { throw "Discovery decision does not match the summary." }
if(@($summary | Where-Object { $_.Candidate -in @('m15drp_sq_only','m15drp_vcr_only') -and $_.Decision -ne 'REJECT_BEFORE_HOLDOUT' }).Count -ne 0) { throw "An engine-only control became eligible." }
if($decision.HoldoutOpened -ne "False" -or $decision.Model4Opened -ne "False") { throw "Discovery decision opened later evidence prematurely." }
$hash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
if($decision.ResultsSha256 -ne $hash) { throw "Decision/results identity mismatch." }
[pscustomobject]@{ Status="PASS"; Decision=$decision.Status; Reports=45; Candidates=15; IdentityPasses=45; DiscoveryEligible=$eligible.Count; HoldoutOpened=$false; Model4Opened=$false; SourceSha256=$sourceHash; ResultsSha256=$hash }
