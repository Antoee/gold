param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\independent_m15_prevday_sweep_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "DE93CFC433C0F3A9B19A6F8D58AAF32894FC8FE6DC41F98A3745FD209C787E8E"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Assert-True([bool]$Condition, [string]$Message) {
   if(!$Condition) { throw $Message }
}

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
$packagedSource = Join-Path $packageFull "source\Professional_XAUUSD_EA.mq5"

Assert-True ($queue.Count -eq 30) "Expected 30 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 10) "Expected ten variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) "Expected three discovery windows."
Assert-True (@($queue.Model | Where-Object { $_ -ne '1' }).Count -eq 0) "Every discovery row must use Model 1."
Assert-True (@($queue.To | Where-Object { $_ -gt '2020.12.31' }).Count -eq 0) "Holdout data leaked into the discovery package."
Assert-True (Test-Path -LiteralPath $packagedSource) "Packaged source is missing."
Assert-True ((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash -eq $expectedSourceHash) "Packaged source hash mismatch."
Assert-True (@($queue.SourceSha256 | Where-Object { $_ -ne $expectedSourceHash }).Count -eq 0) "Queue source identity mismatch."

$expectedWindows = @("older_2015_2018", "discovery_2019_2020", "continuous_2015_2020")
Assert-True (@(Compare-Object $expectedWindows @($queue.Window | Sort-Object -Unique)).Count -eq 0) "Unexpected discovery window set."

foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 3) "Each variant must have three discovery windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   foreach($required in @(
      'InpRiskPercent=0.10',
      'InpSignalTimeframe=15',
      'InpMinimumSweepATR=',
      'InpMinimumReclaimATR=',
      'InpMinimumWickToBodyRatio=',
      'InpRequireFreshSweep=true',
      'InpMaximumStopPriceDistance=10.00',
      'InpMaximumSimultaneousPositions=1',
      'InpMaximumDailyLossPercent=0.75',
      'InpMaximumEquityDrawdownPercent=5.00',
      'InpUseAccountWideExposureGuard=true',
      'InpAccountWideMaxOpenRiskPercent=3.00',
      'InpAccountWideBlockUnprotectedExposure=true',
      'InpUseRealAccountSafetyLock=true',
      'InpAllowRealAccountTrading=false'
   )) {
      Assert-True ($text.Contains($required)) "Profile safety contract missing: $required"
   }
}

[pscustomobject]@{
   Status = "PASS"
   Rows = $queue.Count
   Variants = 10
   Windows = 3
   HoldoutRows = 0
   SourceSha256 = $expectedSourceHash
}
