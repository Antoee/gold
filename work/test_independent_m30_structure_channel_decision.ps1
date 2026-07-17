param(
   [string]$DecisionCsv = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
$rows = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($rows.Count -ne 4) { throw "Expected four frozen decision rows." }
if(@($rows | Where-Object { $_.Decision -ne 'REJECTED_NO_MODEL4' }).Count -ne 0) { throw "Every frozen candidate must be rejected before Model4." }
if(@($rows | Where-Object { [double]$_.DiscoveryNet -le 0 -or [double]$_.ContinuousHoldoutNet -ge 0 -or [double]$_.ContinuousHoldoutProfitFactor -ge 1.0 }).Count -ne 0) { throw "Decision rows do not prove discovery-to-holdout failure." }
$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @('No new best was promoted','Model 4 was skipped','Do not tune channel lengths','real-account trading remains disabled')) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Decision token missing: $token" }
}
[pscustomobject]@{ Status = 'PASS'; Candidates = 4; Rejected = 4; Model4Allowed = $false }

