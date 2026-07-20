[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5',
   [string]$LeaderProfilePath = 'release\three-lane-reversion-strong-signal-lot-cap-provisional\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_PROVISIONAL.set',
   [string]$PackageDir = 'outputs\three_lane_momentum_exit_ablation_diagnostic_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_EXIT_ABLATION_DIAGNOSTIC_MODEL1_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$expectedLeaderHash = 'A0099C6701311BAE105F29909166358D4D30050593318F340AD8F3B932F65F04'

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
      $type = $Matches[1]; $name = $Matches[2]; $value = Convert-SourceDefault $type $Matches[3]
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
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear non-output path: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_strong_signal_lot_cap_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader = (Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash = (Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Published leader source identity changed: $sourceHash" }
if($leaderHash -ne $expectedLeaderHash) { throw "Leader profile identity changed: $leaderHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 183) { throw "Expected 183 source inputs, found $($base.Count)." }
$leaderCount = 0
foreach($line in Get-Content -LiteralPath $leader) {
   if($line -notmatch '^(Inp[^=]+)=(.*)$') { continue }
   $name = $Matches[1]
   if(!$base.Contains($name)) { throw "Leader input missing from published source: $name" }
   $base[$name] = $line
   $leaderCount++
}
if($leaderCount -ne 183) { throw "Expected 183 leader inputs, found $leaderCount." }
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_momentum_exit_ablation_diagnostic_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='mea_control';Role='control';Channel='true';Momentum='true';Hold='120'},
   [pscustomobject]@{Name='mea_no_channel';Role='single_ablation';Channel='false';Momentum='true';Hold='120'},
   [pscustomobject]@{Name='mea_no_momentum';Role='single_ablation';Channel='true';Momentum='false';Hold='120'},
   [pscustomobject]@{Name='mea_no_time';Role='single_ablation';Channel='true';Momentum='true';Hold='0'},
   [pscustomobject]@{Name='mea_channel_only';Role='isolated_exit';Channel='true';Momentum='false';Hold='0'},
   [pscustomobject]@{Name='mea_momentum_only';Role='isolated_exit';Channel='false';Momentum='true';Hold='0'},
   [pscustomobject]@{Name='mea_time_only';Role='isolated_exit';Channel='false';Momentum='false';Hold='120'},
   [pscustomobject]@{Name='mea_fixed_only';Role='fixed_stop_target_only';Channel='false';Momentum='false';Hold='0'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='later_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Architecture diagnostic only. No row can promote directly. Identify whether channel, D1 momentum-failure, or 120-bar time exits protect or suppress payoff. A code follow-up may be nominated only if at least two related ablations are no worse than control in both eras, continuous net >=control +3%, PF/recovery/return-DD no worse, DD <=1.30%, and at least 200 trades. No post-result settings rescue.'

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package 'configs'; $profileDir = Join-Path $package 'profiles'
$reportDir = Join-Path $package 'reports_here'; $sourceDir = Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$rows = [Collections.Generic.List[object]]::new(); $ordinal = 0; $candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Copy-Inputs $base
   Set-FixedInput $inputs 'InpMOUseChannelExit' $variant.Channel
   Set-FixedInput $inputs 'InpMOUseMomentumFailureExit' $variant.Momentum
   Set-FixedInput $inputs 'InpMOMaximumHoldBars' $variant.Hold
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='momentum_exit_ablation_diagnostic_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         MomentumChannelExitEnabled=$variant.Channel;MomentumFailureExitEnabled=$variant.Momentum
         MomentumMaximumHoldBars=$variant.Hold
         ReversionRiskPercent='0.45';MaximumPortfolioOpenRiskPercent='0.75';ExpectedReportName=$reportName
         PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
         ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      }) | Out-Null
   }
}
$manifest = Resolve-RepoPath $ManifestPath
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
@(
   '# Momentum Exit-Ablation Diagnostic Contract','',
   '**Status: PREREGISTERED PRE-2021 RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Source SHA-256: ``$sourceHash``", "- Leader profile SHA-256: ``$leaderHash``", "- Manifest SHA-256: ``$((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant())``", '',
   '- Freeze exact published leader control, each single exit ablation, each isolated exit, and fixed-stop/target-only behavior before testing.',
   '- This diagnostic changes no entry, initial stop, target, risk, lot cap, portfolio limit, or real-account protection. It cannot promote a settings row directly.',
   "- $stopRule", '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, capital change, forward substitution, or real-account trading.'
) | Set-Content -LiteralPath (Join-Path $package 'DISCOVERY_CONTRACT.md') -Encoding ASCII
[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant();Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
