[CmdletBinding()]
param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$AttestationPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_RUN_ATTESTATION.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$resultsFile = Resolve-RepoPath $ResultsPath
$summaryFile = Resolve-RepoPath $SummaryPath
$attestationFile = Resolve-RepoPath $AttestationPath
$decisionFile = Resolve-RepoPath $DecisionCsvPath
$markdownFile = Resolve-RepoPath $DecisionMarkdownPath
foreach($path in @($resultsFile,$summaryFile,$attestationFile,$decisionFile,$markdownFile)) {
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing decision artifact: $path" }
}

$results = @(Import-Csv -LiteralPath $resultsFile)
$summary = @(Import-Csv -LiteralPath $summaryFile)
$attestations = @(Import-Csv -LiteralPath $attestationFile)
$decisionRows = @(Import-Csv -LiteralPath $decisionFile)
$decisionText = Get-Content -LiteralPath $markdownFile -Raw
if($decisionRows.Count -ne 1) { throw "Expected exactly one decision row." }
$decision = $decisionRows[0]

$candidateNames = @($results | Select-Object -ExpandProperty Candidate -Unique)
$continuous = @($results | Where-Object Window -eq "continuous_2015_2020")
$unexpectedWindows = @($results | Where-Object { $_.Window -notin @("older_2015_2018","discovery_2019_2020","continuous_2015_2020") })
$unexpectedModels = @($results | Where-Object { [int]$_.Model -ne 1 })
$unexpectedDeposits = @($results | Where-Object { [double]$_.Deposit -ne 10000.0 })
$unparsed = @($results | Where-Object Status -ne "PARSED")

if($results.Count -ne 45) { throw "Expected 45 discovery reports, found $($results.Count)." }
if($attestations.Count -ne 45 -or @($attestations | Where-Object Status -ne "REPORT_FOUND").Count -ne 0) {
   throw "Expected 45 complete report attestations."
}
if($candidateNames.Count -ne 15 -or $summary.Count -ne 15) { throw "Expected 15 discovery candidates." }
if($continuous.Count -ne 15) { throw "Each candidate must have one continuous result." }
if($unexpectedWindows.Count -ne 0 -or $unexpectedModels.Count -ne 0) { throw "Holdout or non-Model1 evidence was opened before the discovery gate." }
if($unexpectedDeposits.Count -ne 0) { throw "A report violates the frozen 10000 deposit contract." }
if($unparsed.Count -ne 0) { throw "Discovery decision contains unparsed reports." }
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1) { throw "Source identity is not uniform." }
if(@($results.PortableBinarySha256 | Sort-Object -Unique).Count -ne 1) { throw "Binary identity is not uniform." }
if(@($attestations.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or @($attestations.PortableBinarySha256 | Sort-Object -Unique).Count -ne 1) {
   throw "Attested source/binary identity is not uniform."
}
$attestationByReport = @{}
foreach($row in $attestations) {
   if($attestationByReport.ContainsKey([string]$row.ExpectedReportName)) { throw "Duplicate report attestation." }
   $attestationByReport[[string]$row.ExpectedReportName] = $row
}
foreach($row in $results) {
   $key = [string]$row.ExpectedReportName
   if(!$attestationByReport.ContainsKey($key)) { throw "Missing matching attestation: $key" }
   $attested = $attestationByReport[$key]
   if($row.ReportSha256 -ne $attested.ReportSha256 -or $row.ConfigSha256 -ne $attested.ConfigSha256 -or `
      $row.SourceSha256 -ne $attested.SourceSha256 -or $row.PortableBinarySha256 -ne $attested.PortableBinarySha256) {
      throw "Result and attestation identity mismatch: $key"
   }
}
if(@($summary | Where-Object NumericPass -eq "True").Count -ne 0) { throw "A candidate unexpectedly passes the numeric gate." }
if(($continuous | Measure-Object TotalTrades -Maximum).Maximum -ge 80) { throw "The inactivity rejection no longer matches the evidence." }
if(@($continuous | Where-Object { [double]$_.NetProfit -gt 0.0 }).Count -ne 1) { throw "Expected exactly one positive continuous variant." }

$resultsHash = (Get-FileHash -LiteralPath $resultsFile -Algorithm SHA256).Hash.ToUpperInvariant()
$attestationHash = (Get-FileHash -LiteralPath $attestationFile -Algorithm SHA256).Hash.ToUpperInvariant()
if($decision.Status -ne "REJECTED_IN_DISCOVERY") { throw "Decision status is not REJECTED_IN_DISCOVERY." }
if([int]$decision.Candidates -ne 15 -or [int]$decision.ReportsParsed -ne 45 -or [int]$decision.NumericPasses -ne 0) {
   throw "Decision counts do not match the discovery evidence."
}
if($decision.HoldoutPermitted -ne "False" -or $decision.Model4Opened -ne "False" -or $decision.NewBest -ne "False") {
   throw "Rejected discovery incorrectly opened holdout, Model4, or promotion."
}
if($decision.ResultsSha256 -ne $resultsHash) { throw "Decision results hash does not match the results CSV." }
if($decision.RunAttestationSha256 -ne $attestationHash) { throw "Decision attestation hash does not match the run record." }
if($decision.SourceSha256 -ne $results[0].SourceSha256 -or $decision.PortableBinarySha256 -ne $results[0].PortableBinarySha256) {
   throw "Decision source/binary identity does not match the evidence."
}
if($decisionText -notmatch "No 2021\+ holdout, Model 4 escalation, new best, or live approval was opened") {
   throw "Decision markdown omits the no-promotion statement."
}

[pscustomobject]@{
   Status="PASS"; Reports=$results.Count; Candidates=$candidateNames.Count
   MaximumContinuousTrades=($continuous | Measure-Object TotalTrades -Maximum).Maximum
   HoldoutOpened=$false; Model4Opened=$false; ResultsSha256=$resultsHash
}
