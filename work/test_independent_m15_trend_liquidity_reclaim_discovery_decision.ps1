param(
   [string]$ResultsPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$RunPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RUN.csv",
   [string]$DecisionCsvPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$results=@(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$runs=@(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$decisions=@(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath))
$markdown=Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Raw
if($results.Count -ne 28 -or $runs.Count -ne 28 -or $decisions.Count -ne 7){throw 'Unexpected discovery evidence counts.'}
if(@($results|Where-Object Status -ne 'PARSED').Count -gt 0 -or @($runs|Where-Object Status -ne 'REPORT_FOUND').Count -gt 0){throw 'Discovery evidence is incomplete.'}
if(@($results|Where-Object{$_.To -gt '2020.12.31'}).Count -gt 0){throw 'Post-2020 evidence was used.'}
if(@($decisions|Where-Object BaseGatePass -eq 'True').Count -gt 0 -or
   @($decisions|Where-Object FamilyDiscoveryPass -ne 'False').Count -gt 0 -or
   @($decisions|Where-Object Decision -ne 'REJECTED_NO_HOLDOUT_NO_MODEL4').Count -gt 0){
   throw 'The failed discovery family must not advance.'
}
$control=@($decisions|Where-Object Candidate -eq 'tlr_control_q0')
$center=@($decisions|Where-Object Candidate -eq 'tlr_center_q14')
$q07=@($decisions|Where-Object Candidate -eq 'tlr_q07')
if($control.Count -ne 1 -or [double]$control[0].Continuous2015To2020Net -ne -85.36 -or
   [double]$control[0].ContinuousProfitFactor -ne 0.81 -or [int]$control[0].ContinuousTrades -ne 79){
   throw 'Control result changed unexpectedly.'
}
if($center.Count -ne 1 -or [double]$center[0].Older2015To2018Net -ne -118.75 -or
   [double]$center[0].Net2019 -ne 31.16 -or [double]$center[0].Net2020 -ne -3.09 -or
   [double]$center[0].Continuous2015To2020Net -ne -90.68 -or
   [double]$center[0].ContinuousProfitFactor -ne 0.73 -or [int]$center[0].ContinuousTrades -ne 61){
   throw 'Center result changed unexpectedly.'
}
if($q07.Count -ne 1 -or [double]$q07[0].Continuous2015To2020Net -ne -31.32 -or
   [double]$q07[0].ContinuousProfitFactor -ne 0.92 -or [int]$q07[0].ContinuousTrades -ne 69){
   throw 'Least-bad quarantine neighbor changed unexpectedly.'
}
if($markdown.IndexOf([char]0) -ge 0){throw 'Decision markdown contains a null character.'}
foreach($token in @(
   'rejected during the frozen pre-2021 Model 1 screen',
   'No post-2020 holdout or Model 4 configuration was opened',
   'no new best was promoted',
   'registered candidate remains unchanged',
   'Three initial portable rows hit source-identity startup races',
   'Every row lost in 2015-2018 and continuously',
   'does not survive extraction into this clean date-independent mechanism',
   'Real-account trading: disabled'
)){
   if($markdown.IndexOf($token,[StringComparison]::OrdinalIgnoreCase) -lt 0){throw "Decision markdown missing token: $token"}
}

[pscustomobject]@{Status='PASS';Reports=$results.Count;Profiles=$decisions.Count;BaseGatePasses=0;FamilyPass=$false;HoldoutRuns=0;Model4Runs=0;NewBest=$false}
