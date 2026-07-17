param(
   [string]$DecisionCsv = "outputs\INDEPENDENT_M15_FVG_RETEST_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_M15_FVG_RETEST_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }

$rows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($rows.Count -ne 10) { throw "Expected ten FVG discovery decision rows." }
if(@($rows | Where-Object { $_.Decision -ne 'REJECTED_NO_HOLDOUT_NO_MODEL4' }).Count -ne 0) { throw "Every candidate must be rejected before holdout and Model4." }
if(@($rows | Where-Object {
   [double]$_.OlderDiscoveryNet -ge 0 -or
   [double]$_.NewerDiscoveryNet -ge 0 -or
   [double]$_.ContinuousDiscoveryNet -ge 0 -or
   [double]$_.OlderDiscoveryProfitFactor -ge 1.0 -or
   [double]$_.NewerDiscoveryProfitFactor -ge 1.0 -or
   [double]$_.ContinuousDiscoveryProfitFactor -ge 1.0
}).Count -ne 0) { throw "Decision rows do not prove failure in both discovery eras and continuously." }
if(@($rows | Where-Object { [int]$_.ContinuousDiscoveryTrades -lt 100 }).Count -ne 0) { throw "The family rejection must be supported by active continuous samples." }

$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @(
   'No 2021-2026 holdout was opened',
   'Model 4 was skipped',
   'no new best was promoted',
   'Do not rescue the family',
   'real-account trading remains disabled'
)) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Decision token missing: $token" }
}

[pscustomobject]@{ Status = 'PASS'; Candidates = 10; Rejected = 10; HoldoutAllowed = $false; Model4Allowed = $false }
