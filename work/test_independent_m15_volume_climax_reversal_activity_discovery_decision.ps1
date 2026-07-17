param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$decisionRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionPath))
if($results.Count -ne 45) { throw "Expected 45 final activity reports." }
if(@($results.Candidate | Sort-Object -Unique).Count -ne 15) { throw "Expected 15 activity candidates." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "A final activity report is unparsed." }
if(@($results | Where-Object ReportSourceIdentityPass -ne "True").Count -ne 0) { throw "A final activity report failed source identity." }
if(@($results | Where-Object { $_.Window -notin @("older_2015_2018","discovery_2019_2020","continuous_2015_2020") }).Count -ne 0) { throw "Holdout data was opened." }
if($decisionRows.Count -ne 1) { throw "Expected one activity decision row." }
$decision = $decisionRows[0]
if($decision.Status -ne "REJECTED_IN_DISCOVERY" -or [int]$decision.NumericPasses -ne 0) { throw "Activity discovery rejection changed." }
if($decision.HoldoutOpened -ne "False" -or $decision.Model4Opened -ne "False") { throw "Rejected activity discovery opened later evidence." }
$hash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
if($decision.ResultsSha256 -ne $hash) { throw "Activity decision/results identity mismatch." }
[pscustomobject]@{ Status="PASS"; Reports=45; Candidates=15; IdentityPasses=45; HoldoutOpened=$false; Model4Opened=$false; ResultsSha256=$hash }
