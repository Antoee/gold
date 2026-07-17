param(
   [string]$DecisionCsv = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_DECISION.csv",
   [string]$DecisionMarkdown = "outputs\INDEPENDENT_M15_FAILED_BREAKOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($decision.Count -ne 28) { throw "Expected 28 candidate decisions." }
if(@($decision | Where-Object FinalPromotionGatePass -eq "True").Count -ne 0) {
   throw "A failed-breakout candidate incorrectly passed the final gate."
}
$numeric = @($decision | Where-Object QuantitativeGatePass -eq "True")
if($numeric.Count -ne 1 -or $numeric[0].Candidate -ne "fbt_b14_fixed_r200" -or $numeric[0].NeighborSupportPass -ne "False") {
   throw "Unexpected unsupported numeric-pass identity."
}
$b16 = @($decision | Where-Object { $_.Candidate -match '^fbt_b16_fixed_r(125|150|200)$' })
if($b16.Count -ne 3 -or @($b16 | Where-Object { $_.NeighborSupportPass -ne "True" -or $_.ContinuousTrades -ne "54" -or $_.Decision -ne "REJECTED_ACTIVITY_FLOOR" }).Count -ne 0) {
   throw "The supported-but-sparse 16-bar fixed-R neighborhood changed."
}
$lead = @($decision | Where-Object Candidate -eq "fbt_b14_fixed_r200")
if($lead.Count -ne 1 -or
   [math]::Abs([double]$lead[0].Older2015To2018Net - 110.75) -gt 0.001 -or
   [math]::Abs([double]$lead[0].Newer2019To2020Net - 0.76) -gt 0.001 -or
   [math]::Abs([double]$lead[0].Continuous2015To2020Net - 112.52) -gt 0.001 -or
   [math]::Abs([double]$lead[0].ContinuousProfitFactor - 1.28) -gt 0.001 -or
   [int]$lead[0].ContinuousTrades -ne 95) {
   throw "Lead liveness metrics changed."
}

$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @(
   "rejected before holdout",
   "No 2021-2026 retrospective run was opened",
   "Model 4 was skipped",
   "no new best was promoted",
   "Every row had only ``54`` trades",
   "Do not lower the activity floor",
   "real-account trading remains disabled"
)) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Decision token missing: $token"
   }
}

[pscustomobject]@{
   Status="PASS"; Candidates=$decision.Count; FinalGatePasses=0
   UnsupportedNumericPasses=$numeric.Count; SupportedSparseRows=$b16.Count
   RecentAllowed=$false; Model4Allowed=$false
}
