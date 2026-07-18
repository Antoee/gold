param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_MODEL1_RUN.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$runs = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$decisions = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath))
$markdown = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Raw
if($results.Count -ne 30 -or $runs.Count -ne 30 -or $decisions.Count -ne 10) {
   throw "Unexpected discovery evidence counts."
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0 -or
   @($runs | Where-Object Status -ne 'REPORT_FOUND').Count -gt 0) {
   throw "Discovery evidence is incomplete."
}
if(@($results | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) {
   throw "Post-2020 evidence was used."
}
if(@($decisions | Where-Object DiscoveryGatePass -eq 'True').Count -gt 0 -or
   @($decisions | Where-Object Decision -ne 'REJECTED_NO_HOLDOUT_NO_MODEL4').Count -gt 0) {
   throw "The failed discovery family must not advance."
}
$center = @($decisions | Where-Object Candidate -eq 'ars_center')
$leastBad = @($decisions | Where-Object Candidate -eq 'ars_adx24')
if($center.Count -ne 1 -or [int]$center[0].ContinuousTrades -ne 103 -or
   [double]$center[0].Continuous2015To2020Net -ne -263.39 -or
   [double]$center[0].ContinuousProfitFactor -ne 0.59 -or
   [double]$center[0].Older2015To2018Net -ne -212.61 -or
   [double]$center[0].Repair2019To2020Net -ne -42.57) {
   throw "Center result changed unexpectedly."
}
if($leastBad.Count -ne 1 -or [int]$leastBad[0].ContinuousTrades -ne 40 -or
   [double]$leastBad[0].Continuous2015To2020Net -ne -65.16 -or
   [double]$leastBad[0].ContinuousProfitFactor -ne 0.76) {
   throw "Least-bad ADX result changed unexpectedly."
}
foreach($token in @(
   'rejected during frozen Model 1 discovery',
   'No 2021-2026 holdout was opened',
   'Model 4 was skipped',
   'no new best was promoted',
   'real-account trading remains disabled',
   'startup identity races',
   'registered source/profile/binary identity',
   'center plus two one-factor neighbors',
   'session-transition false-break hypothesis has no broad pre-2021 edge'
)) {
   if($markdown.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Decision markdown missing token: $token"
   }
}

[pscustomobject]@{
   Status = 'PASS'
   Reports = $results.Count
   Candidates = $decisions.Count
   GatePasses = 0
   HoldoutRuns = 0
   Model4Runs = 0
}
