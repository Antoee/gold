[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5',
   [string]$LeaderProfilePath = 'release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir = 'outputs\three_lane_capital_efficiency_risk_ladder_discovery_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_MODEL1_MANIFEST.csv'
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
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_capital_efficiency_risk_ladder_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='cerl_control100';Role='control';Factor='1.00';ReversionRisk='0.45';MomentumRisk='0.15';AdaptiveRisk='0.15';PortfolioCap='0.75';ReversionLotCap='0.10';StrongReversionLotCap='0.15';AdaptiveLotCap='0.10'},
   [pscustomobject]@{Name='cerl_low125';Role='lower_neighbor';Factor='1.25';ReversionRisk='0.5625';MomentumRisk='0.1875';AdaptiveRisk='0.1875';PortfolioCap='0.9375';ReversionLotCap='0.125';StrongReversionLotCap='0.1875';AdaptiveLotCap='0.125'},
   [pscustomobject]@{Name='cerl_center150';Role='center';Factor='1.50';ReversionRisk='0.675';MomentumRisk='0.225';AdaptiveRisk='0.225';PortfolioCap='1.125';ReversionLotCap='0.15';StrongReversionLotCap='0.225';AdaptiveLotCap='0.15'},
   [pscustomobject]@{Name='cerl_high175';Role='upper_neighbor';Factor='1.75';ReversionRisk='0.7875';MomentumRisk='0.2625';AdaptiveRisk='0.2625';PortfolioCap='1.3125';ReversionLotCap='0.175';StrongReversionLotCap='0.2625';AdaptiveLotCap='0.175'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='recent_2021_2023';From='2021.01.01';To='2023.12.31'},
   [pscustomobject]@{Name='latest_2024_2026';From='2024.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$stopRule = 'Frozen proportional capital-efficiency ladder on the exact leader. Every row and all four disjoint eras must remain profitable. The 1.50x center must improve continuous net >=20% and CAGR >=control +0.30 point, retain >=90% of control trades, PF >=90% of control, recovery and return/DD >=80% of control, and DD <=2.00%. Both 1.25x and 1.75x neighbors must improve continuous net >=10%, retain >=80% of control PF/recovery/return-DD, and DD <=2.25%. The 5% equity-drawdown lock and all daily, weekly, monthly, cooldown, entry, and exit controls remain unchanged. No post-result rescue.'

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
   Set-FixedInput $inputs 'InpRVRiskPercent' $variant.ReversionRisk
   Set-FixedInput $inputs 'InpMORiskPercent' $variant.MomentumRisk
   Set-FixedInput $inputs 'InpATBRiskPercent' $variant.AdaptiveRisk
   Set-FixedInput $inputs 'InpMaximumPortfolioOpenRiskPercent' $variant.PortfolioCap
   Set-FixedInput $inputs 'InpRVMaximumPositionLots' $variant.ReversionLotCap
   Set-FixedInput $inputs 'InpRVStrongSignalMaximumPositionLots' $variant.StrongReversionLotCap
   Set-FixedInput $inputs 'InpATBMaximumPositionLots' $variant.AdaptiveLotCap
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
         Phase='capital_efficiency_risk_ladder_discovery_model1';Window=$window.Name
         From=$window.From;To=$window.To;Model=1;Deposit=10000
         RiskScaleFactor=$variant.Factor
         MomentumRiskPercent=$variant.MomentumRisk;AdaptiveRiskPercent=$variant.AdaptiveRisk
         ReversionRiskPercent=$variant.ReversionRisk;DeclaredLaneRiskSumPercent=$variant.PortfolioCap
         MaximumPortfolioOpenRiskPercent=$variant.PortfolioCap
         ReversionMaximumPositionLots=$variant.ReversionLotCap
         StrongReversionMaximumPositionLots=$variant.StrongReversionLotCap
         AdaptiveMaximumPositionLots=$variant.AdaptiveLotCap
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
   '# Capital-Efficiency Risk Ladder Discovery Contract','',
   '**Status: PREREGISTERED PRE-2021 RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Source SHA-256: ``$sourceHash``", "- Leader profile SHA-256: ``$leaderHash``", "- Manifest SHA-256: ``$manifestHash``", '',
   '- Frozen ladder scales all three requested lane risks, matching reversion/adaptive lot ceilings, and the account-wide open-risk allowance by the same factor.',
   '- Control is the exact published leader at 1.00x. The center is 1.50x with fixed 1.25x and 1.75x neighbors. The 5% equity-drawdown lock and realized-loss controls do not move.',
   "- $stopRule",
   '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, capital change, forward substitution, or real-account trading.'
) | Set-Content -LiteralPath (Join-Path $package 'DISCOVERY_CONTRACT.md') -Encoding ASCII
[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
