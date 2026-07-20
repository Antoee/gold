[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$PackageDir = 'outputs\three_lane_reversion_lot_cap_discovery_model1_package',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$profileHash = '705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E'
$caps = [ordered]@{rvlc_control='0.10';rvlc_low012='0.12';rvlc_center015='0.15';rvlc_high018='0.18';rvlc_stress020='0.20'}
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Get-Inputs([string]$Path) {
   $map = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -match '^(Inp[^=]+)=(.*)$') { $map[$Matches[1]] = $Matches[2] }
   }
   return $map
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$package = (Resolve-Path -LiteralPath (Resolve-RepoPath $PackageDir)).Path
$source = Join-Path $package 'source\Professional_XAUUSD_EA.mq5'
$champion = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $sourceHash) { throw 'Packaged source identity changed.' }
if((Get-FileHash -LiteralPath $champion -Algorithm SHA256).Hash.ToUpperInvariant() -ne $profileHash) { throw 'Champion profile identity changed.' }
if($manifest.Count -ne 15 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 5 -or @($manifest.Window | Sort-Object -Unique).Count -ne 3) {
   throw 'Manifest topology is not exactly five candidates by three windows.'
}
if(@($manifest | Where-Object {
   $_.SourceSha256 -ne $sourceHash -or [int]$_.Model -ne 1 -or [int]$_.Deposit -ne 10000 -or
   $_.ReversionRiskPercent -ne '0.45' -or $_.MaximumPortfolioOpenRiskPercent -ne '0.75'
}).Count -ne 0) { throw 'Manifest risk/source contract changed.' }

$championInputs = Get-Inputs $champion
foreach($candidate in $caps.Keys) {
   $profile = Join-Path $package "profiles\$candidate.set"
   $inputs = Get-Inputs $profile
   if($inputs.Count -ne 178) { throw "$candidate profile input count changed." }
   if($inputs['InpRVMaximumPositionLots'] -ne "$($caps[$candidate])||$($caps[$candidate])||0||0||N") { throw "$candidate lot cap changed." }
   foreach($name in $championInputs.Keys) {
      if($name -in @('InpRVMaximumPositionLots','InpEvidenceRunLabel')) { continue }
      if($inputs[$name] -ne $championInputs[$name]) { throw "$candidate changed forbidden input $name." }
   }
   foreach($required in @{
      InpAllowRealAccountTrading='false||false||0||0||N';InpRVRiskPercent='0.45||0.45||0||0||N';
      InpMORiskPercent='0.15||0.15||0||0||N';InpATBRiskPercent='0.15||0.15||0||0||N';
      InpMaximumPortfolioOpenRiskPercent='0.75||0.75||0||0||N';InpExpectedInitialBalance='10000.0||10000.0||0||0||N'
   }.GetEnumerator()) {
      if($inputs[$required.Key] -ne $required.Value) { throw "$candidate safety value $($required.Key) changed." }
   }
}
foreach($row in $manifest) {
   $config = Resolve-RepoPath ([string]$row.PackageConfig)
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $row.ConfigSha256) {
      throw "Config hash changed at rank $($row.QueueRank)."
   }
   if($row.ReversionMaximumPositionLots -ne $caps[[string]$row.Candidate]) {
      throw "Manifest lot cap changed at rank $($row.QueueRank)."
   }
}

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$sourceHash;ChampionProfileSha256=$profileHash
   Configurations=$manifest.Count;Candidates=$caps.Count;Windows=3;OnlyTradingInputChanged='InpRVMaximumPositionLots'
   ReversionRiskPercent='0.45';PortfolioOpenRiskCapPercent='0.75';RealAccountTradingAllowed=$false
}
