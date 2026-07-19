[CmdletBinding()]
param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$AttestationPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_RUN_ATTESTATION.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_DECISION.md",
   [string]$FeasibilityPath = "outputs\XAUUSD_TLT_D1_HISTORY_FEASIBILITY_RESULTS.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

& (Join-Path $PSScriptRoot "test_independent_m15_tlt_rates_impulse_source.ps1") | Out-Null
$resultsFile = Resolve-RepoPath $ResultsPath
$summaryFile = Resolve-RepoPath $SummaryPath
$attestationFile = Resolve-RepoPath $AttestationPath
$decisionFile = Resolve-RepoPath $DecisionCsvPath
$decisionMarkdownFile = Resolve-RepoPath $DecisionMarkdownPath
$feasibilityFile = Resolve-RepoPath $FeasibilityPath
foreach($path in @($resultsFile,$summaryFile,$attestationFile,$decisionFile,$decisionMarkdownFile,$feasibilityFile)) {
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing TLT decision artifact: $path" }
}

$results = @(Import-Csv -LiteralPath $resultsFile)
$summary = @(Import-Csv -LiteralPath $summaryFile)
$attestations = @(Import-Csv -LiteralPath $attestationFile)
$decisionRows = @(Import-Csv -LiteralPath $decisionFile)
$feasibility = @(Import-Csv -LiteralPath $feasibilityFile)
$decisionText = Get-Content -LiteralPath $decisionMarkdownFile -Raw
if($results.Count -ne 45 -or @($results | Where-Object Status -ne "PARSED").Count -ne 0) { throw "Expected 45 parsed TLT reports." }
if($summary.Count -ne 15 -or $attestations.Count -ne 45) { throw "TLT summary or attestation count mismatch." }
if(@($attestations | Where-Object Status -ne "REPORT_FOUND").Count -ne 0) { throw "A TLT report attestation failed." }
if($decisionRows.Count -ne 1) { throw "Expected one TLT decision row." }
if(@($results | Where-Object { [int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000.0 -or [int]$_.TotalTrades -le 0 }).Count -ne 0) {
   throw "TLT discovery violates model, deposit, or activity integrity."
}
if(@($results | Where-Object { $_.Window -notin @("older_2015_2018","discovery_2019_2020","continuous_2015_2020") }).Count -ne 0) {
   throw "TLT discovery opened an unsealed window."
}
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or
   @($results.PortableBinarySha256 | Sort-Object -Unique).Count -ne 1) { throw "TLT source/binary identity is not uniform." }

$attestationByReport = @{}
foreach($row in $attestations) { $attestationByReport[[string]$row.ExpectedReportName] = $row }
foreach($row in $results) {
   if(!$attestationByReport.ContainsKey([string]$row.ExpectedReportName)) { throw "Missing TLT report attestation." }
   $attested = $attestationByReport[[string]$row.ExpectedReportName]
   if($row.ReportSha256 -ne $attested.ReportSha256 -or $row.ConfigSha256 -ne $attested.ConfigSha256 -or
      $row.SourceSha256 -ne $attested.SourceSha256 -or $row.PortableBinarySha256 -ne $attested.PortableBinarySha256) {
      throw "TLT result and attestation identity mismatch."
   }
}

$decision = $decisionRows[0]
$resultsHash = (Get-FileHash -LiteralPath $resultsFile -Algorithm SHA256).Hash.ToUpperInvariant()
$attestationHash = (Get-FileHash -LiteralPath $attestationFile -Algorithm SHA256).Hash.ToUpperInvariant()
if($decision.Status -ne "REJECTED_IN_DISCOVERY" -or [int]$decision.NumericPasses -ne 0 -or [int]$decision.DiscoveryEligible -ne 0) {
   throw "TLT rejection counts do not match the evidence."
}
if($decision.HoldoutPermitted -ne "False" -or $decision.Model4Opened -ne "False" -or $decision.NewBest -ne "False") {
   throw "Rejected TLT discovery incorrectly opened escalation."
}
if($decision.ResultsSha256 -ne $resultsHash -or $decision.RunAttestationSha256 -ne $attestationHash) {
   throw "TLT decision hashes do not match the evidence."
}
if($feasibility.Count -ne 6 -or ($feasibility | Measure-Object alignment_percent -Minimum).Minimum -lt 98.0 -or
   ($feasibility | Measure-Object lookback_ready_percent -Minimum).Minimum -ne 100.0) {
   throw "TLT feasibility evidence is incomplete."
}
$centerProfile = Get-Content -LiteralPath (Join-Path $repo "outputs\independent_m15_tlt_rates_impulse_discovery_model1_package\profiles\tltri_center.set")
if(@($centerProfile | Where-Object { $_ -eq "InpTLTSymbol=TLT" }).Count -ne 1 -or
   @($centerProfile | Where-Object { $_ -like "InpTLTSymbol=*||*" }).Count -ne 0) {
   throw "TLT symbol input was not serialized as a literal string."
}
if($decisionText -notmatch "No 2021\+ holdout, Model 4 escalation, new best, or live approval was opened") {
   throw "TLT decision omits the no-escalation statement."
}

[pscustomobject]@{
   Status="PASS"; Reports=$results.Count; Candidates=$summary.Count
   MinimumTrades=($results | Measure-Object TotalTrades -Minimum).Minimum
   MaximumTrades=($results | Measure-Object TotalTrades -Maximum).Maximum
   HoldoutOpened=$false; Model4Opened=$false; ResultsSha256=$resultsHash
}
