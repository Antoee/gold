param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\independent_m30_structure_channel_holdout_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
$expectedCandidates = @('m30sc_72_36_tp20','m30sc_48_24_channel','m30sc_48_24_tp25','m30sc_48_24_stop5')
Assert-True ($queue.Count -eq 36) "Expected 36 holdout rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 4) "Expected four frozen candidates."
Assert-True (@($queue.Candidate | Sort-Object -Unique | Where-Object { $_ -notin $expectedCandidates }).Count -eq 0) "Unexpected holdout candidate."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 9) "Expected nine holdout windows."
Assert-True (@($queue.From | Where-Object { $_ -lt '2021.01.01' }).Count -eq 0) "Discovery data leaked into the holdout package."
Assert-True (@($queue.To | Where-Object { $_ -gt '2026.07.12' }).Count -eq 0) "Post-freeze data leaked into the holdout package."
foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 9) "Each candidate must have nine holdout windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @('InpRiskPercent=0.10','InpSignalTimeframe=30','InpMaximumStopPriceDistance=','InpUseAccountWideExposureGuard=true','InpUseRealAccountSafetyLock=true','InpAllowRealAccountTrading=false')) {
      Assert-True ($text.Contains($required)) "Holdout profile contract missing: $required"
   }
}
[pscustomobject]@{ Status = 'PASS'; Rows = $queue.Count; Candidates = 4; Windows = 9; Earliest = '2021.01.01'; Latest = '2026.07.12' }
