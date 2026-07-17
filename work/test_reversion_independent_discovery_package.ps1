param(
   [string]$QueueManifestPath = "outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\reversion_independent_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition,[string]$Message) { if(!$Condition) { throw $Message } }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
Assert-True ($queue.Count -eq 45) "Expected 45 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 5) "Expected five profile variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 9) "Expected nine discovery windows."
Assert-True (@($queue.To | Where-Object { $_ -gt '2020.12.31' }).Count -eq 0) "Post-2020 data leaked into discovery."
Assert-True (@($queue | Where-Object { $_.Model -ne '1' }).Count -eq 0) "Discovery must use Model1 only."

foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 9) "Each candidate must have nine windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      'InpUseRealAccountSafetyLock=true',
      'InpAllowRealAccountTrading=false',
      'InpAccountWideMaxOpenRiskPercent=0.75',
      'InpMaxOpenRiskPercent=0.75',
      'InpUseBandVWAPReversionLane=true',
      'InpBandVWAPReversionUseIsolatedExecution=true'
   )) { Assert-True ($text.Contains($required)) "Profile safety contract missing: $required" }

   if($first.Candidate -eq 'ri_control') {
      Assert-True ($text.Contains('InpBandVWAPReversionIndependentAttempt=false')) "Control must keep independent scheduling off."
      Assert-True ($text.Contains('InpMaxSimultaneousPositions=1')) "Control must preserve the one-position contract."
   } else {
      Assert-True ($text.Contains('InpBandVWAPReversionIndependentAttempt=true')) "Candidate must enable independent scheduling."
      Assert-True ($text.Contains('InpMaxSimultaneousPositions=2')) "Candidate must use the bounded two-position contract."
      Assert-True ($first.DIEdge -in @('-12','-10')) "Unexpected DI threshold."
      Assert-True ($first.BandRiskMultiplier -in @('0.30','0.40')) "Unexpected reversion risk multiplier."
   }
}

[pscustomobject]@{ Status='PASS'; Rows=$queue.Count; Variants=5; Windows=9; HoldoutRows=0; LatestDate='2020-12-31' }
