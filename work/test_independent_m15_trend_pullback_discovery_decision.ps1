[CmdletBinding()]
param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$resultsFile = Resolve-RepoPath $ResultsPath
$decisionFile = Resolve-RepoPath $DecisionCsvPath
$markdownFile = Resolve-RepoPath $DecisionMarkdownPath
foreach($path in @($resultsFile, $decisionFile, $markdownFile)) {
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing decision artifact: $path" }
}

$results = @(Import-Csv -LiteralPath $resultsFile)
$decisionRows = @(Import-Csv -LiteralPath $decisionFile)
$decisionText = Get-Content -LiteralPath $markdownFile -Raw
if($decisionRows.Count -ne 1) { throw "Expected exactly one decision row." }
$decision = $decisionRows[0]

$candidateNames = @($results | Select-Object -ExpandProperty Candidate -Unique)
$continuous = @($results | Where-Object Window -eq "continuous_2015_2020")
$laterEra = @($results | Where-Object Window -eq "discovery_2019_2020")
$unexpectedWindows = @($results | Where-Object { $_.Window -notin @("older_2015_2018", "discovery_2019_2020", "continuous_2015_2020") })
$unexpectedModels = @($results | Where-Object { [int]$_.Model -ne 1 })
$unparsed = @($results | Where-Object Status -ne "PARSED")

if($results.Count -ne 30) { throw "Expected 30 discovery reports, found $($results.Count)." }
if($candidateNames.Count -ne 10) { throw "Expected 10 discovery candidates, found $($candidateNames.Count)." }
if($continuous.Count -ne 10 -or $laterEra.Count -ne 10) { throw "Each candidate must have one continuous and one later-era result." }
if($unexpectedWindows.Count -ne 0 -or $unexpectedModels.Count -ne 0) { throw "Holdout or non-Model1 evidence was opened before the discovery gate." }
if($unparsed.Count -ne 0) { throw "Discovery decision contains unparsed reports." }
if(@($continuous | Where-Object { [double]$_.NetProfit -ge 0.0 }).Count -ne 0) { throw "A continuous candidate is no longer losing; rebuild and review the decision." }
if(@($laterEra | Where-Object { [double]$_.NetProfit -ge 0.0 }).Count -ne 0) { throw "A later-era candidate is no longer losing; rebuild and review the decision." }

$resultsHash = (Get-FileHash -LiteralPath $resultsFile -Algorithm SHA256).Hash.ToUpperInvariant()
if($decision.Status -ne "REJECTED_IN_DISCOVERY") { throw "Decision status is not REJECTED_IN_DISCOVERY." }
if([int]$decision.Candidates -ne 10 -or [int]$decision.ReportsParsed -ne 30 -or [int]$decision.NumericPasses -ne 0) { throw "Decision counts do not match the discovery evidence." }
if($decision.HoldoutOpened -ne "False" -or $decision.Model4Opened -ne "False") { throw "Rejected discovery incorrectly opened holdout or Model4 testing." }
if($decision.ResultsSha256 -ne $resultsHash) { throw "Decision results hash does not match the results CSV." }
if($decisionText -notmatch "No 2021\+ holdout, Model 4 escalation, new best, or live approval was opened") { throw "Decision markdown omits the no-promotion statement." }

[pscustomobject]@{
   Status = "PASS"
   Reports = $results.Count
   Candidates = $candidateNames.Count
   HoldoutOpened = $false
   Model4Opened = $false
   ResultsSha256 = $resultsHash
}
