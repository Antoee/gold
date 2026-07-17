param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_VOLATILITY_SQUEEZE_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionPath = "outputs\INDEPENDENT_M15_VOLATILITY_SQUEEZE_DISCOVERY_DECISION.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$decisionRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionPath))
if($results.Count -ne 45) { throw "Expected 45 final reports." }
if(@($results.Candidate | Sort-Object -Unique).Count -ne 15) { throw "Expected 15 candidates." }
if(@($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "A final report is unparsed." }
if(@($results | Where-Object ReportSourceIdentityPass -ne "True").Count -ne 0) { throw "A final report failed source identity." }
if(@($results | Where-Object { $_.Window -notin @("older_2015_2018","discovery_2019_2020","continuous_2015_2020") }).Count -ne 0) { throw "Holdout data was opened." }
if($decisionRows.Count -ne 1) { throw "Expected one decision row." }
$decision = $decisionRows[0]
if($decision.Status -ne "REJECTED_IN_DISCOVERY" -or [int]$decision.NumericPasses -ne 0) { throw "Discovery rejection changed." }
if($decision.HoldoutOpened -ne "False" -or $decision.Model4Opened -ne "False") { throw "Rejected discovery opened later evidence." }
$hash = (Get-FileHash -LiteralPath (Resolve-RepoPath $ResultsPath) -Algorithm SHA256).Hash
if($decision.ResultsSha256 -ne $hash) { throw "Decision/results identity mismatch." }
[pscustomobject]@{ Status="PASS"; Reports=45; Candidates=15; IdentityPasses=45; HoldoutOpened=$false; Model4Opened=$false; ResultsSha256=$hash }
