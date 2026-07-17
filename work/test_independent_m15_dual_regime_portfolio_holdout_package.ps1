param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$DiscoveryQueuePath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$DiscoverySummaryPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$PackageDir = "outputs\independent_m15_dual_regime_portfolio_holdout_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$discoveryQueue = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryQueuePath))
$eligibleNames = @((Import-Csv -LiteralPath (Resolve-RepoPath $DiscoverySummaryPath) | Where-Object Decision -eq "DISCOVERY_ELIGIBLE").Candidate | Sort-Object)
$packageFull = Resolve-RepoPath $PackageDir
$source = Join-Path $packageFull "source\Professional_XAUUSD_EA.mq5"
$candidates = @($queue.Candidate | Sort-Object -Unique)
Assert-True ($eligibleNames.Count -gt 0) "Discovery has no eligible profiles."
Assert-True ($queue.Count -eq $eligibleNames.Count * 3) "Expected three holdout rows per frozen profile."
Assert-True ($candidates.Count -eq $eligibleNames.Count) "Holdout candidate count changed."
Assert-True (($candidates -join '|') -eq ($eligibleNames -join '|')) "Holdout candidates differ from discovery eligibility."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) "Expected three holdout windows."
Assert-True (@($queue.From | Where-Object { $_ -lt "2021.01.01" }).Count -eq 0) "Discovery data leaked into the holdout."
Assert-True (@($queue.To | Where-Object { $_ -gt "2026.07.17" }).Count -eq 0) "Future data leaked into the holdout."
Assert-True (Test-Path -LiteralPath $source -PathType Leaf) "Package source is missing."
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
Assert-True (@($queue.SourceSha256 | Sort-Object -Unique).Count -eq 1) "Queue contains multiple source identities."
Assert-True ($queue[0].SourceSha256 -eq $sourceHash) "Queue/package source identity mismatch."
foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 3) "Each profile must have three holdout windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile -PathType Leaf) "Missing profile: $($first.ProfileSnapshot)"
   $profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
   Assert-True ($profileHash -eq $first.ProfileSha256) "Holdout profile hash mismatch."
   Assert-True ($profileHash -eq $first.DiscoveryProfileSha256) "Holdout profile differs from discovery."
   $discovery = $discoveryQueue | Where-Object Candidate -eq $candidate.Name | Select-Object -First 1
   Assert-True ($null -ne $discovery -and $profileHash -eq $discovery.ProfileSha256) "Discovery profile identity mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      "InpRiskPercent=0.10", "InpSignalTimeframe=15", "InpEnableVolumeClimax=true",
      "InpEnableVolatilitySqueeze=true", "InpMaximumStopPriceDistance=6.00",
      "InpMaximumSimultaneousPositions=1", "InpMaximumDailyLossPercent=0.75",
      "InpMaximumEquityDrawdownPercent=5.00", "InpUseAccountWideExposureGuard=true",
      "InpUseRealAccountSafetyLock=true", "InpAllowRealAccountTrading=false"
   )) { Assert-True ($text.Contains($required)) "Profile contract missing: $required" }
}
[pscustomobject]@{ Status="PASS"; Rows=$queue.Count; Profiles=$eligibleNames.Count; Windows=3; DiscoveryRows=0; ExactProfileIdentity=$true; SourceSha256=$sourceHash }
