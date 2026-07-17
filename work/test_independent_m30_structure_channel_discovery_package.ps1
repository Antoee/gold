param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\independent_m30_structure_channel_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
Assert-True ($queue.Count -eq 30) "Expected 30 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 10) "Expected ten variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) "Expected three discovery windows."
Assert-True (@($queue.To | Where-Object { $_ -gt '2020.12.31' }).Count -eq 0) "Holdout data leaked into the discovery package."
foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 3) "Each variant must have three discovery windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      'InpRiskPercent=0.10',
      'InpSignalTimeframe=30',
      'InpMaximumStopPriceDistance=',
      'InpStopLookbackBars=',
      'InpMaximumSimultaneousPositions=1',
      'InpMaximumDailyLossPercent=0.75',
      'InpMaximumEquityDrawdownPercent=5.00',
      'InpUseAccountWideExposureGuard=true',
      'InpAccountWideMaxOpenRiskPercent=3.00',
      'InpUseRealAccountSafetyLock=true',
      'InpAllowRealAccountTrading=false'
   )) {
      Assert-True ($text.Contains($required)) "Profile safety contract missing: $required"
   }
}
[pscustomobject]@{ Status = 'PASS'; Rows = $queue.Count; Variants = 10; Windows = 3; HoldoutRows = 0 }
