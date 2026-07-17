param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\independent_m5_failed_breakout_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "6774D7E94A78E985630C34EE372086BF2C8A6EA4C77690078F15641B86119D3B"

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

Assert-True ($queue.Count -eq 24) "Expected 24 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 12) "Expected twelve variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 2) "Expected two equal discovery windows."
Assert-True (@($queue.Model | Where-Object { $_ -ne '1' }).Count -eq 0) "Every discovery row must use Model 1."
Assert-True (@($queue.To | Where-Object { $_ -gt '2020.12.31' }).Count -eq 0) "Holdout data leaked into the discovery package."
Assert-True (Test-Path -LiteralPath $packagedSource) "Packaged source is missing."
Assert-True ((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash -eq $expectedSourceHash) "Packaged source hash mismatch."
Assert-True (@($queue.SourceSha256 | Where-Object { $_ -ne $expectedSourceHash }).Count -eq 0) "Queue source identity mismatch."
Assert-True (@($queue.Candidate | Where-Object { $_ -notmatch '^m5fbt_b(14|16|18)_(struct_r075|fixed_r(125|150|200))$' }).Count -eq 0) "Unexpected M5 discovery candidate."

$expectedWindows = @("discovery_2018_2020", "older_2015_2017")
Assert-True (@(Compare-Object $expectedWindows @($queue.Window | Sort-Object -Unique)).Count -eq 0) "Unexpected discovery window set."

foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 2) "Each variant must have two discovery windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $lines = @(Get-Content -LiteralPath $profile)
   Assert-True ($lines.Count -eq 80) "Profile input count must exactly match the 80 configurable source inputs."
   $text = $lines -join "`n"
   foreach($required in @(
      'InpRiskPercent=0.10',
      'InpSignalTimeframe=5',
      'InpBoxLookbackBars=',
      'InpMaximumBreakoutAgeBars=',
      'InpMinimumBoxRangeATR=',
      'InpMaximumBoxRangeATR=',
      'InpMinimumReclaimDepthRatio=',
      'InpUseMaximumADXFilter=true',
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
   $boxTarget = $text.Contains('InpUseBoxOppositeTarget=true')
   $fixedTarget = $text.Contains('InpUseFixedTakeProfit=true')
   Assert-True ($boxTarget -xor $fixedTarget) "Each profile must use exactly one bounded take-profit path."
}

[pscustomobject]@{
   Status = "PASS"
   Rows = $queue.Count
   Variants = 12
   Windows = 2
   HoldoutRows = 0
   InputsPerProfile = 80
   SourceSha256 = $expectedSourceHash
}
