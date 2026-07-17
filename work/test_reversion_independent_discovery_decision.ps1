param(
   [string]$ResultsCsv = "outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionCsv = "outputs\REVERSION_INDEPENDENT_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\REVERSION_INDEPENDENT_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsCsv))
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($results.Count -ne 45) { throw "Expected 45 parsed discovery results." }
if(@($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Every discovery result must be parsed." }
if($decision.Count -ne 5) { throw "Expected one control and four candidate decision rows." }

$control = @($decision | Where-Object Role -eq 'CONTROL')
$candidates = @($decision | Where-Object Role -eq 'CANDIDATE')
if($control.Count -ne 1 -or $control[0].Decision -ne 'CONTROL_CONFIRMED') { throw "Exact control was not confirmed." }
if($candidates.Count -ne 4) { throw "Expected four independent-scheduling candidates." }
if(@($candidates | Where-Object Decision -ne 'REJECTED_NO_HOLDOUT_NO_MODEL4').Count -ne 0) { throw "Every candidate must be rejected before recent data and Model 4." }

$controlOlder = [double]$control[0].OlderDiscoveryNet
$controlNewer = [double]$control[0].NewerDiscoveryNet
$controlPf = [double]$control[0].ContinuousProfitFactor
$controlDd = [double]$control[0].ContinuousMaxDrawdownPercent
if([math]::Abs($controlOlder - 184.32) -gt 0.001 -or [math]::Abs($controlNewer - 108.33) -gt 0.001) { throw "Control broad-window compatibility changed." }
if(@($candidates | Where-Object {
   [double]$_.OlderDiscoveryNet -ge $controlOlder -or
   [double]$_.NewerDiscoveryNet -ge $controlNewer -or
   [double]$_.ContinuousProfitFactor -ge $controlPf -or
   [double]$_.ContinuousMaxDrawdownPercent -le $controlDd -or
   $_.RedDiscoveryYears -ne '2017;2019'
}).Count -ne 0) { throw "Candidate rows do not prove the registered rejection gates." }

$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @(
   'No 2021-2026 implementation-validation run was opened',
   'Model 4 was skipped',
   'no new best was promoted',
   'Keep `InpBandVWAPReversionIndependentAttempt` default off',
   'real-account trading remains disabled'
)) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Decision token missing: $token" }
}

[pscustomobject]@{ Status = 'PASS'; Results = 45; Candidates = 4; Rejected = 4; HoldoutAllowed = $false; Model4Allowed = $false }
