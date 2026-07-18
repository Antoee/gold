param(
   [string]$ResultsPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv",
   [string]$DecisionCsvPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_DECISION.md"
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
if($results.Count -ne 24 -or $runs.Count -ne 24 -or $decisions.Count -ne 6) {
   throw "Unexpected discovery evidence counts."
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0 -or
   @($runs | Where-Object Status -ne 'REPORT_FOUND').Count -gt 0) {
   throw "Discovery evidence is incomplete."
}
if(@($results | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) {
   throw "Post-2020 evidence was used."
}
if(@($decisions | Where-Object BaseGatePass -eq 'True').Count -ne 3 -or
   @($decisions | Where-Object FamilyDiscoveryPass -ne 'False').Count -gt 0 -or
   @($decisions | Where-Object Decision -ne 'REJECTED_NO_HOLDOUT_NO_MODEL4').Count -gt 0) {
   throw "The failed discovery family must not advance."
}

$control = @($decisions | Where-Object Candidate -eq 'dir_mo020_di12_control')
$center = @($decisions | Where-Object Candidate -eq 'dir_mo020_di10_center')
$strict = @($decisions | Where-Object Candidate -eq 'dir_mo020_di08_strict')
if($control.Count -ne 1 -or [double]$control[0].Net2020 -ne -82.98 -or
   [double]$control[0].Continuous2015To2020Net -ne 889.12) {
   throw "The 0.20-risk control result changed unexpectedly."
}
if($center.Count -ne 1 -or [double]$center[0].Net2020 -ne 83.79 -or
   [double]$center[0].Continuous2015To2020Net -ne 954.80 -or
   [double]$center[0].ContinuousProfitFactor -ne 1.49 -or
   $center[0].BaseGatePass -ne 'False' -or $center[0].FailedBaseGates -ne 'continuous-pf') {
   throw "The nominated 0.20-risk center result changed unexpectedly."
}
if($strict.Count -ne 1 -or [double]$strict[0].Continuous2015To2020Net -ne 939.03 -or
   [double]$strict[0].ContinuousProfitFactor -ne 1.52 -or $strict[0].BaseGatePass -ne 'True') {
   throw "The strict neighbor result changed unexpectedly."
}
if($markdown.IndexOf([char]0) -ge 0) { throw "Decision markdown contains a null character." }
foreach($token in @(
   'rejected at the frozen pre-2021 Model 1 gate',
   'No post-2020 holdout or Model 4 configuration was opened',
   'no new best was promoted',
   'registered candidate remains unchanged',
   'Replacing the center after seeing results would be threshold selection',
   'real-account trading: disabled'
)) {
   if($markdown.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Decision markdown missing token: $token"
   }
}

[pscustomobject]@{
   Status = 'PASS'
   Reports = $results.Count
   Profiles = $decisions.Count
   BaseGatePasses = 3
   FamilyPass = $false
   HoldoutRuns = 0
   Model4Runs = 0
   NewBest = $false
}
