param(
   [string]$ResultsPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv",
   [string]$CompileEvidencePath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_COMPILE_EVIDENCE.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$expectedSourceHash = 'A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9'
$expectedBinaryHash = '7B6386477A6205F77AB91484A585E27B88517B3BE288F700AC911A5B7C8BFABB'
$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$runs = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$compile = @(Import-Csv -LiteralPath (Resolve-RepoPath $CompileEvidencePath))
$decisions = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath))
$markdown = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Raw
if($results.Count -ne 56 -or $runs.Count -ne 56 -or $decisions.Count -ne 14) {
   throw "Unexpected discovery evidence counts."
}
if($compile.Count -ne 1 -or $compile[0].SourceSha256 -ne $expectedSourceHash -or
   $compile[0].BinarySha256 -ne $expectedBinaryHash -or $compile[0].Result -ne '0 errors, 0 warnings') {
   throw "Compile identity changed unexpectedly."
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0 -or
   @($runs | Where-Object Status -ne 'REPORT_FOUND').Count -gt 0) {
   throw "Discovery evidence is incomplete."
}
if(@($results | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) {
   throw "Post-2020 evidence was used."
}
if(@($results.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $results[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Result source identity changed unexpectedly."
}
if(@($decisions | Where-Object BaseGatePass -eq 'True').Count -ne 2 -or
   @($decisions | Where-Object FamilyDiscoveryPass -ne 'False').Count -gt 0 -or
   @($decisions | Where-Object Decision -ne 'REJECTED_NO_HOLDOUT_NO_MODEL4').Count -gt 0) {
   throw "The failed discovery family must not advance."
}

$center015 = @($decisions | Where-Object Candidate -eq 'rsg_mo015_combo25')
$center020 = @($decisions | Where-Object Candidate -eq 'rsg_mo020_combo25')
$strict015 = @($decisions | Where-Object Candidate -eq 'rsg_mo015_combo25_di08')
$strict020 = @($decisions | Where-Object Candidate -eq 'rsg_mo020_combo25_di08')
if($center015.Count -ne 1 -or [double]$center015[0].Net2019 -ne -4.98 -or
   [double]$center015[0].Net2020 -ne 109.32 -or [double]$center015[0].ContinuousProfitFactor -ne 1.51 -or
   $center015[0].BaseGatePass -ne 'False' -or $center015[0].FailedBaseGates -ne '2019-net;2019-pf') {
   throw "The 0.15-risk nominated center changed unexpectedly."
}
if($center020.Count -ne 1 -or [double]$center020[0].Net2019 -ne -2.17 -or
   [double]$center020[0].Net2020 -ne 126.81 -or [double]$center020[0].ContinuousProfitFactor -ne 1.47 -or
   $center020[0].BaseGatePass -ne 'False' -or $center020[0].FailedBaseGates -ne '2019-net;2019-pf;continuous-pf') {
   throw "The 0.20-risk nominated center changed unexpectedly."
}
if($strict015.Count -ne 1 -or [double]$strict015[0].Continuous2015To2020Net -ne 678.43 -or
   [double]$strict015[0].ContinuousProfitFactor -ne 1.56 -or $strict015[0].BaseGatePass -ne 'True') {
   throw "The 0.15-risk strict-DI row changed unexpectedly."
}
if($strict020.Count -ne 1 -or [double]$strict020[0].Continuous2015To2020Net -ne 867.69 -or
   [double]$strict020[0].ContinuousProfitFactor -ne 1.51 -or $strict020[0].BaseGatePass -ne 'True') {
   throw "The 0.20-risk strict-DI row changed unexpectedly."
}
if($markdown.IndexOf([char]0) -ge 0) { throw "Decision markdown contains a null character." }
foreach($token in @(
   'rejected at the frozen pre-2021 Model 1 gate',
   'No post-2020 holdout or Model 4 configuration was opened',
   'no new best was promoted',
   'registered candidate remains unchanged',
   'Five initial portable rows hit source-identity startup races',
   'Substituting the isolated stricter-DI rows after seeing results would be threshold selection',
   'Real-account trading: disabled'
)) {
   if($markdown.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Decision markdown missing token: $token"
   }
}

[pscustomobject]@{
   Status = 'PASS'
   Reports = $results.Count
   Profiles = $decisions.Count
   BaseGatePasses = 2
   FamilyPass = $false
   HoldoutRuns = 0
   Model4Runs = 0
   NewBest = $false
}
