param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\independent_m15_dual_regime_portfolio_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
$source = Join-Path $packageFull "source\Professional_XAUUSD_EA.mq5"
Assert-True ($queue.Count -eq 45) "Expected 45 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 15) "Expected 15 variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) "Expected three discovery windows."
Assert-True (@($queue.To | Where-Object { $_ -gt "2020.12.31" }).Count -eq 0) "Holdout data leaked into the discovery package."
Assert-True (Test-Path -LiteralPath $source -PathType Leaf) "Package source is missing."
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
Assert-True (@($queue.SourceSha256 | Sort-Object -Unique).Count -eq 1) "Queue contains multiple source identities."
Assert-True ($queue[0].SourceSha256 -eq $sourceHash) "Queue/package source identity mismatch."
foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 3) "Each variant must have three discovery windows."
   $first = $candidate.Group[0]
   $config = Join-Path $packageFull $first.Config
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $config -PathType Leaf) "Missing config: $($first.Config)"
   Assert-True ((Get-Content -LiteralPath $config -Raw).Contains("Period=15")) "M15 package config does not use the native tester timeframe."
   Assert-True (Test-Path -LiteralPath $profile -PathType Leaf) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      "InpRiskPercent=0.10",
      "InpSignalTimeframe=15",
      "InpEnableVolumeClimax=",
      "InpEnableVolatilitySqueeze=",
      "InpVcrMinimumVolumeRatio=",
      "InpVcrExtremeLookbackBars=",
      "InpVcrMinimumRangeATR=",
      "InpVcrMinimumWickPercent=",
      "InpVcrMinimumVWAPDeviationATR=",
      "InpVcrMinimumRiskReward=",
      "InpVcrMaximumTargetR=",
      "InpVcrUseRangePhaseFilter=",
      "InpSqSqueezeBars=",
      "InpSqBollingerPeriod=",
      "InpSqKeltnerATRMultiplier=",
      "InpSqBreakoutLookbackBars=",
      "InpSqTakeProfitR=",
      "InpMaximumStopPriceDistance=6.00",
      "InpMaximumSimultaneousPositions=1",
      "InpMaximumDailyLossPercent=0.75",
      "InpMaximumEquityDrawdownPercent=5.00",
      "InpUseAccountWideExposureGuard=true",
      "InpAccountWideMaxOpenRiskPercent=3.00",
      "InpUseRealAccountSafetyLock=true",
      "InpAllowRealAccountTrading=false"
   )) {
      Assert-True ($text.Contains($required)) "Profile safety contract missing: $required"
   }
}
[pscustomobject]@{ Status="PASS"; Rows=$queue.Count; Variants=15; Windows=3; HoldoutRows=0; DualEngine=$true; SourceSha256=$sourceHash }
