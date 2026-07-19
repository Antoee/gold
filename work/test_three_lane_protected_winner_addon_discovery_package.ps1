param(
   [string]$PackageDir = 'outputs\three_lane_protected_winner_addon_discovery_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$package = Join-Path $repo $PackageDir
$manifestPath = Join-Path $repo $ManifestPath
$expectedSourceHash = 'F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46'
& (Join-Path $PSScriptRoot 'test_three_lane_protected_winner_addon_source.ps1') | Out-Null

$rows = @(Import-Csv -LiteralPath $manifestPath)
if($rows.Count -ne 30) { throw "Expected 30 discovery rows, found $($rows.Count)." }
$candidates = @($rows.Candidate | Sort-Object -Unique)
if($candidates.Count -ne 10) { throw "Expected 10 candidates, found $($candidates.Count)." }
if(@($rows | Where-Object { $_.Model -ne '1' -or $_.Deposit -ne '10000' -or [datetime]$_.To -gt [datetime]'2020-12-31' }).Count -gt 0) {
   throw 'Discovery manifest violates the sealed Model 1 / $10,000 / pre-2021 contract.'
}
if(@($rows | Where-Object { $_.SourceSha256 -ne $expectedSourceHash }).Count -gt 0) {
   throw 'Discovery source identity is inconsistent.'
}
foreach($candidate in $candidates) {
   $candidateRows = @($rows | Where-Object Candidate -eq $candidate)
   if($candidateRows.Count -ne 3 -or @($candidateRows.Window | Sort-Object -Unique).Count -ne 3) {
      throw "Candidate window coverage is incomplete: $candidate"
   }
   $profilePath = Join-Path $package ("profiles\{0}.set" -f $candidate)
   $lines = @(Get-Content -LiteralPath $profilePath)
   if($lines.Count -ne 187 -or @($lines | Where-Object { $_ -match '^Inp' }).Count -ne 187) {
      throw "Profile does not pin 187 inputs: $candidate"
   }
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   if(@($candidateRows | Where-Object ProfileSha256 -ne $profileHash).Count -gt 0) {
      throw "Profile hash mismatch: $candidate"
   }
}
$control = Get-Content -LiteralPath (Join-Path $package 'profiles\pwa_control.set') -Raw
$center = Get-Content -LiteralPath (Join-Path $package 'profiles\pwa_center.set') -Raw
foreach($token in @(
   'InpMOUseProtectedWinnerAddOn=false||false||0||0||N',
   'InpMaximumAccountPositions=3||3||0||0||N',
   'InpATBRiskPercent=0.15||0.15||0||0||N',
   'InpMaximumPortfolioOpenRiskPercent=0.75||0.75||0||0||N'
)) {
   if($control.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Control pin missing: $token" }
}
foreach($token in @(
   'InpMOUseProtectedWinnerAddOn=true||true||0||0||N',
   'InpMaximumAccountPositions=4||4||0||0||N',
   'InpMOAddOnRiskMultiplier=0.50||0.50||0||0||N',
   'InpMOAddOnPrimaryLockR=0.75||0.75||0||0||N',
   'InpMOAddOnLockedProfitCoverage=1.25||1.25||0||0||N'
)) {
   if($center.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Center pin missing: $token" }
}
$packagedSource = Join-Path $package 'source\Professional_XAUUSD_EA.mq5'
if((Get-FileHash -LiteralPath $packagedSource -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) {
   throw 'Packaged source identity mismatch.'
}

[pscustomobject][ordered]@{
   Status='PASS';Rows=$rows.Count;Candidates=$candidates.Count;Windows=3;InputsPerProfile=187
   SourceSha256=$expectedSourceHash;MaximumDate='2020-12-31';ControlFeature='DISABLED'
}
