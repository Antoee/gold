param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_MODEL1_RUN.csv",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_WEEKEND_GAP_FADE_DISCOVERY_DECISION.md"
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
if($results.Count -ne 21 -or $runs.Count -ne 21 -or $decisions.Count -ne 7) {
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
$center = @($decisions | Where-Object Candidate -eq 'wgf_center')
$loose = @($decisions | Where-Object Candidate -eq 'wgf_confirm000')
if($center.Count -ne 1 -or [int]$center[0].ContinuousTrades -ne 3 -or [double]$center[0].Continuous2015To2020Net -ne -8.04) {
   throw "Center result changed unexpectedly."
}
if($loose.Count -ne 1 -or [int]$loose[0].ContinuousTrades -ne 15 -or
   [double]$loose[0].Continuous2015To2020Net -ne -13.46 -or
   [double]$loose[0].Repair2019To2020Net -ne -22.00) {
   throw "Loose-confirmation result changed unexpectedly."
}
foreach($token in @(
   'rejected during frozen Model 1 discovery',
   'No 2021-2026 holdout was opened',
   'Model 4 was skipped',
   'no new best was promoted',
   'real-account trading remains disabled',
   'startup identity races',
   'registered source/profile/binary identity'
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
