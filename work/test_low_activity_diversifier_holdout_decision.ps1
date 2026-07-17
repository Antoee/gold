param(
   [string]$ResultsPath='outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_RESULTS.csv',
   [string]$SummaryPath='outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_SUMMARY.csv',
   [string]$DecisionPath='outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_DECISION.csv',
   [string]$MarkdownPath='outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_DECISION.md'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Assert-True([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$resultsFile=Resolve-RepoPath $ResultsPath;$summaryFile=Resolve-RepoPath $SummaryPath;$decisionFile=Resolve-RepoPath $DecisionPath;$markdownFile=Resolve-RepoPath $MarkdownPath
foreach($path in @($resultsFile,$summaryFile,$decisionFile,$markdownFile)){Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "Missing holdout artifact: $path"}
$results=@(Import-Csv -LiteralPath $resultsFile);$summary=@(Import-Csv -LiteralPath $summaryFile);$decision=@(Import-Csv -LiteralPath $decisionFile);$text=Get-Content -LiteralPath $markdownFile -Raw
Assert-True ($results.Count -eq 9 -and @($results | Where-Object Status -ne 'PARSED').Count -eq 0) 'Expected nine parsed reports.'
Assert-True ($summary.Count -eq 3) 'Expected three profile summaries.'
Assert-True ($decision.Count -eq 1 -and $decision[0].Status -eq 'REJECTED_IN_HOLDOUT') 'Decision must reject the holdout.'
Assert-True ([int]$decision[0].TradeAnalysisEligible -eq 0 -and $decision[0].PortfolioAnalysisPermitted -eq 'False') 'Rejected holdout incorrectly permits portfolio analysis.'
Assert-True ($decision[0].Model4Permitted -eq 'False' -and $decision[0].ReleasedCandidateChanged -eq 'False') 'Rejected holdout changed candidate state.'
Assert-True (@($summary | Where-Object LaneGatePass -eq 'True').Count -eq 0) 'A lane unexpectedly passes.'
foreach($row in $summary){
   Assert-True ([double]$row.Holdout2021_2022Net -le 0 -or [double]$row.Holdout2023_2026Net -le 0) "Profile no longer has a losing disjoint era: $($row.Candidate)"
}
$hash=(Get-FileHash -LiteralPath $resultsFile -Algorithm SHA256).Hash.ToUpperInvariant()
Assert-True ($decision[0].ResultsSha256 -eq $hash) 'Results hash mismatch.'
Assert-True ($text.Contains('No trade extraction, portfolio combination, Model 4 run, new best, or live approval was opened')) 'Markdown omits no-promotion statement.'
[pscustomobject]@{Status='PASS';Reports=$results.Count;Profiles=$summary.Count;Eligible=0;PortfolioAnalysisPermitted=$false;ResultsSha256=$hash}
