[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5',
   [string]$LeaderProfilePath = 'release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_band_deviation_expansion_discovery_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_BAND_DEVIATION_EXPANSION_DISCOVERY_MODEL1_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedLeaderHash = 'ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Convert-SourceDefault([string]$Type, [string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq 'string') { return $trimmed.Substring(1, $trimmed.Length - 2) }
   if($Type -eq 'ENUM_TIMEFRAMES') {
      $map = @{PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'}
      if(!$map.ContainsKey($trimmed)) { throw "Unsupported timeframe: $trimmed" }
      return $map[$trimmed]
   }
   return $trimmed
}
function Get-SourceInputs([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$') { continue }
      $type = $Matches[1]
      $name = $Matches[2]
      $value = Convert-SourceDefault $type $Matches[3]
      $inputs[$name] = if($type -eq 'string') { "$name=$value" } else { "$name=$value||$value||0||0||N" }
   }
   return $inputs
}
function Copy-Inputs($Inputs) {
   $copy = [ordered]@{}
   foreach($key in $Inputs.Keys) { $copy[$key] = $Inputs[$key] }
   return $copy
}
function Set-FixedInput($Inputs, [string]$Name, [string]$Value, [switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Unknown input override: $Name" }
   $Inputs[$Name] = if($StringValue) { "$Name=$Value" } else { "$Name=$Value||$Value||0||0||N" }
}
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-output path: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

& (Join-Path $PSScriptRoot 'test_three_lane_momentum_same_side_exit_cooldown_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader = (Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash = (Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Leader source identity changed: $sourceHash" }
if($leaderHash -ne $expectedLeaderHash) { throw "Leader profile identity changed: $leaderHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 185) { throw "Expected 185 source inputs, found $($base.Count)." }
$leaderCount = 0
foreach($line in Get-Content -LiteralPath $leader) {
   if($line -notmatch '^(Inp[^=]+)=(.*)$') { continue }
   $name = $Matches[1]
   if(!$base.Contains($name)) { throw "Leader input missing from source: $name" }
   $base[$name] = $line
   $leaderCount++
}
if($leaderCount -ne 185) { throw "Expected 185 leader inputs, found $leaderCount." }
if($base['InpRVBollingerDeviation'] -notlike 'InpRVBollingerDeviation=2.00*') {
   throw 'Leader Bollinger-deviation control changed.'
}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_band_deviation_expansion_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvbd_control200';Role='control';Deviation='2.00'},
   [pscustomobject]@{Name='rvbd_neighbor190';Role='conservative_neighbor';Deviation='1.90'},
   [pscustomobject]@{Name='rvbd_center180';Role='center';Deviation='1.80'},
   [pscustomobject]@{Name='rvbd_neighbor170';Role='aggressive_neighbor';Deviation='1.70'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='recent_2021_2023';From='2021.01.01';To='2023.12.31'},
   [pscustomobject]@{Name='latest_2024_2026';From='2024.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$stopRule = 'Frozen one-factor Bollinger-deviation expansion on the exact leader. Every row and all four disjoint eras must remain profitable. The 1.80 center must improve continuous net >=10% and CAGR >=control +0.15 point, add at least three continuous reversion entries, retain >=95% of control total trades, PF >=90% of control, recovery and return/DD >=85% of control, and DD <=1.75%. Both 1.90 and 1.70 neighbors must improve net >=5%, add reversion activity, retain >=85% of control PF and >=75% of control recovery/return-DD, and DD <=2.00%. All other entry, exit, risk, lot, exposure, loss-limit, cooldown, and real-account settings remain unchanged. No post-result rescue.'

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package 'configs'
$profileDir = Join-Path $package 'profiles'
$reportDir = Join-Path $package 'reports_here'
$sourceDir = Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$rows = [Collections.Generic.List[object]]::new()
$ordinal = 0
$candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Copy-Inputs $base
   Set-FixedInput $inputs 'InpRVBollingerDeviation' $variant.Deviation
   $profilePath = Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows) {
      $ordinal++
      $configName = '{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name
      $configPath = Join-Path $configDir $configName
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         Phase='reversion_band_deviation_expansion_discovery_model1';Window=$window.Name
         From=$window.From;To=$window.To;Model=1;Deposit=10000
         BollingerDeviation=$variant.Deviation
         ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName"
         SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"
         ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      }) | Out-Null
   }
}
$manifest = Resolve-RepoPath $ManifestPath
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@(
   '# Reversion Band-Deviation Expansion Discovery Contract','',
   '**Status: PREREGISTERED HISTORICAL RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Source SHA-256: ``$sourceHash``", "- Leader profile SHA-256: ``$leaderHash``", "- Manifest SHA-256: ``$manifestHash``", '',
   '- Control is the exact leader at 2.00 standard deviations. The frozen center is 1.80 with fixed 1.90 and 1.70 neighbors.',
   '- This changes only the existing H1 reversion band excursion. RSI, ADX, wick/reclaim geometry, VWAP target, stop, RR, DI, spread, risk, lot caps, portfolio cap, and every account protection remain fixed.',
   "- $stopRule",
   '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned behavior, capital change, forward substitution, or real-account trading.'
) | Set-Content -LiteralPath (Join-Path $package 'DISCOVERY_CONTRACT.md') -Encoding ASCII
[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
