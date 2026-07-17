param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_SUMMARY.csv",
   [string]$DecisionPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$summary = @(Import-Csv -LiteralPath (Resolve-RepoPath $SummaryPath))
$decisionRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionPath))
if($results.Count -ne 36) { throw "Expected 36 final reports." }
if(@($results.Candidate | Sort-Object -Unique).Count -ne 12) { throw "Expected 12 candidates." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "A final report is unparsed." }
if(@($results | Where-Object ReportSourceIdentityPass -ne "True").Count -ne 0) { throw "A final report failed source identity." }
if(@($results | Where-Object { $_.Window -notin @("holdout_2021_2023","recent_2024_2026ytd","continuous_2021_2026ytd") }).Count -ne 0) { throw "Unexpected holdout window." }
if($decisionRows.Count -ne 1) { throw "Expected one decision row." }
$decision = $decisionRows[0]
$eligible = @($summary | Where-Object Decision -eq "HOLDOUT_ELIGIBLE")
$expectedStatus = if($eligible.Count -gt 0) { "HOLDOUT_ELIGIBLE" } else { "REJECTED_IN_HOLDOUT" }
if($decision.Status -ne $expectedStatus -or [int]$decision.HoldoutEligible -ne $eligible.Count) { throw "Holdout decision does not match the summary." }
if($decision.HoldoutOpened -ne "True" -or $decision.Model4Opened -ne "False") { throw "Holdout/model4 state is inconsistent." }
$hash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
if($decision.ResultsSha256 -ne $hash) { throw "Decision/results identity mismatch." }
[pscustomobject]@{ Status="PASS"; Decision=$decision.Status; Reports=36; Candidates=12; IdentityPasses=36; HoldoutEligible=$eligible.Count; HoldoutOpened=$true; Model4Opened=$false; ResultsSha256=$hash }
