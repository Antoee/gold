param(
   [string]$QueueManifestPath = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageDir = "outputs\independent_h1_prevweek_break_retest_discovery_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "1A5799C5829D0E7108F60CBB331EB98BE39DACD0422C592020B6973C17147F26"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }

$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath))
$packageFull = Resolve-RepoPath $PackageDir
$packagedSource = Join-Path $packageFull "source\Professional_XAUUSD_EA.mq5"
Assert-True ($queue.Count -eq 42) "Expected 42 discovery rows."
Assert-True (@($queue.Candidate | Sort-Object -Unique).Count -eq 14) "Expected fourteen variants."
Assert-True (@($queue.Window | Sort-Object -Unique).Count -eq 3) "Expected three discovery windows."
Assert-True (@($queue.Model | Where-Object { $_ -ne '1' }).Count -eq 0) "Every discovery row must use Model 1."
Assert-True (@($queue.To | Where-Object { $_ -gt '2020.12.31' }).Count -eq 0) "Holdout data leaked into the discovery package."
Assert-True (Test-Path -LiteralPath $packagedSource) "Packaged source is missing."
Assert-True ((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash -eq $expectedSourceHash) "Packaged source hash mismatch."
Assert-True (@($queue.SourceSha256 | Where-Object { $_ -ne $expectedSourceHash }).Count -eq 0) "Queue source identity mismatch."

$sourceText = Get-Content -LiteralPath $packagedSource -Raw
$sourceInputNames = @([regex]::Matches($sourceText, '(?m)^\s*input\s+(?!group\b)[A-Za-z_][A-Za-z0-9_<>]*\s+(Inp[A-Za-z0-9_]+)\s*=') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
Assert-True ($sourceInputNames.Count -gt 50) "Source input extraction unexpectedly failed."

foreach($candidate in ($queue | Group-Object Candidate)) {
   Assert-True ($candidate.Count -eq 3) "Each variant must have three discovery windows."
   $first = $candidate.Group[0]
   $profile = Join-Path $packageFull $first.ProfileSnapshot
   Assert-True (Test-Path -LiteralPath $profile) "Missing profile: $($first.ProfileSnapshot)"
   Assert-True ((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -eq $first.ProfileSha256) "Profile hash mismatch."
   $text = Get-Content -LiteralPath $profile -Raw
   $profileInputNames = @(Get-Content -LiteralPath $profile | ForEach-Object { if($_ -match '^([^=]+)=') { $matches[1] } } | Sort-Object -Unique)
   Assert-True (@(Compare-Object $sourceInputNames $profileInputNames).Count -eq 0) "Profile/source input set mismatch: $($first.ProfileSnapshot)"
   foreach($required in @(
      'InpRiskPercent=0.10', 'InpSignalTimeframe=16385', 'InpMaximumSetupAgeBars=',
      'InpBreakBufferATR=', 'InpRetestToleranceATR=', 'InpMaximumRetestPenetrationATR=',
      'InpMaximumStopPriceDistance=10.00', 'InpMaximumSimultaneousPositions=1',
      'InpMaximumDailyLossPercent=0.75', 'InpMaximumEquityDrawdownPercent=5.00',
      'InpUseAccountWideExposureGuard=true', 'InpAccountWideMaxOpenRiskPercent=3.00',
      'InpAccountWideBlockUnprotectedExposure=true', 'InpUseRealAccountSafetyLock=true',
      'InpAllowRealAccountTrading=false'
   )) {
      Assert-True ($text.Contains($required)) "Profile safety contract missing: $required"
   }
}

[pscustomobject]@{ Status="PASS"; Rows=$queue.Count; Variants=14; Windows=3; HoldoutRows=0; SourceInputs=$sourceInputNames.Count; SourceSha256=$expectedSourceHash }
