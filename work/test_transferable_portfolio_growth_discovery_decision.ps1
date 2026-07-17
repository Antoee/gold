param(
   [string]$ResultsPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DecisionPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.csv",
   [string]$MarkdownPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Assert-True([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}

$resultsFile=Resolve-RepoPath $ResultsPath
$summaryFile=Resolve-RepoPath $SummaryPath
$decisionFile=Resolve-RepoPath $DecisionPath
$markdownFile=Resolve-RepoPath $MarkdownPath
foreach($path in @($resultsFile,$summaryFile,$decisionFile,$markdownFile)){Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "Missing growth decision artifact: $path"}
$results=@(Import-Csv -LiteralPath $resultsFile)
$summary=@(Import-Csv -LiteralPath $summaryFile)
$decision=@(Import-Csv -LiteralPath $decisionFile)
$text=Get-Content -LiteralPath $markdownFile -Raw

Assert-True ($results.Count -eq 28) "Expected 28 parsed reports."
Assert-True (@($results | Where-Object Status -ne 'PARSED').Count -eq 0) "Unparsed growth reports remain."
Assert-True (@($results.Model | Where-Object {[int]$_ -ne 1}).Count -eq 0) "Model4 was opened before the Model1 gate."
Assert-True ($summary.Count -eq 7) "Expected seven summary profiles."
Assert-True ($decision.Count -eq 1) "Expected one decision row."
Assert-True ($decision[0].Status -eq 'REJECTED_IN_MODEL1') "Growth decision is not rejected."
Assert-True ([int]$decision[0].NumericPasses -eq 0 -and [int]$decision[0].Model4Eligible -eq 0) "Rejected decision reports passing profiles."
Assert-True ($decision[0].Model4Permitted -eq 'False' -and $decision[0].ReleasedCandidateChanged -eq 'False') "Rejected decision changed candidate state."
Assert-True (@($summary | Where-Object Decision -eq 'MODEL4_ELIGIBLE').Count -eq 0) "Summary contains a Model4-eligible profile."

$growth=@($summary | Where-Object Control -ne 'True')
Assert-True (@($growth | Where-Object {[double]$_.ImprovementVsControlPercent -ge 15.0}).Count -eq 0) "A profile now reaches the frozen 15% improvement gate."
$best=$summary | Sort-Object {[double]$_.ContinuousNetProfit} -Descending | Select-Object -First 1
Assert-True ($best.Candidate -eq 'tpg_rv055_mo015') "Unexpected best Model1 growth row; rebuild the decision."
Assert-True ([double]$best.ContinuousMaxDrawdownPercent -gt 4.0 -and [double]$best.ContinuousRecoveryFactor -lt 4.0) "Best row no longer fails drawdown and recovery gates."

$hash=(Get-FileHash -LiteralPath $resultsFile -Algorithm SHA256).Hash.ToUpperInvariant()
Assert-True ($decision[0].ResultsSha256 -eq $hash) "Results hash mismatch."
Assert-True ($text.Contains('No Model 4 growth test, new best, or live approval was opened')) "Markdown omits the no-promotion statement."

[pscustomobject]@{Status='PASS';Reports=$results.Count;Profiles=$summary.Count;Model4Permitted=$false;BestProfile=$best.Candidate;ResultsSha256=$hash}
