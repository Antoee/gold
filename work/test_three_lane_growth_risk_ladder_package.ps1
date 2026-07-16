param(
   [string]$QueueManifestPath = "outputs\THREE_LANE_GROWTH_RISK_LADDER_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\three_lane_growth_risk_ladder_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
Assert-True ($queue.Count -eq 16) "Expected 16 queue rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 4) "Expected four risk candidates."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 4) "Expected four broad windows."
foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 4) "Each risk candidate must have four windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Profile missing: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   Assert-True ($text.Contains("InpRiskPercent=$($first.RiskPercent)")) "Risk percent mismatch."
   Assert-True ($text.Contains("InpMaxEffectiveRiskPercent=$($first.EffectiveRiskCap)")) "Effective cap mismatch."
   Assert-True ($text.Contains("InpAccountWideMaxOpenRiskPercent=$($first.OpenRiskCap)")) "Account-wide open-risk cap mismatch."
   Assert-True ($text.Contains('InpAllowRealAccountTrading=false')) "Real trading must remain disabled."
   Assert-True ($text.Contains('InpAccountWideMaxPositions=1')) "Account-wide position cap must remain one."
}
[pscustomobject]@{ Status = 'PASS'; Rows = $queue.Count; Candidates = 4; Windows = 4 }
