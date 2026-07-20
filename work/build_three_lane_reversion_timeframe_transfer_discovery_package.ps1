[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5',
   [string]$LeaderProfilePath = 'release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_timeframe_transfer_discovery_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_CONTRACT.md'
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
      if(!$map.ContainsKey($trimmed)) { throw "Unsupported source timeframe: $trimmed" }
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

Set-FixedInput $base 'InpMOEnabled' 'false'
Set-FixedInput $base 'InpATBEnabled' 'false'
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_timeframe_transfer_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvtf_h1_control';Family='h1';Role='control';Timeframe='16385';ATR='14';ADX='14';RSI='14';Bands='20';VWAP='48';Stop='5'},
   [pscustomobject]@{Name='rvtf_m30_local';Family='m30';Role='local_bars';Timeframe='30';ATR='14';ADX='14';RSI='14';Bands='20';VWAP='48';Stop='5'},
   [pscustomobject]@{Name='rvtf_m30_mid';Family='m30';Role='mid_duration';Timeframe='30';ATR='21';ADX='21';RSI='21';Bands='30';VWAP='72';Stop='8'},
   [pscustomobject]@{Name='rvtf_m30_duration';Family='m30';Role='duration_normalized';Timeframe='30';ATR='28';ADX='28';RSI='28';Bands='40';VWAP='96';Stop='10'},
   [pscustomobject]@{Name='rvtf_h2_local';Family='h2';Role='local_bars';Timeframe='16386';ATR='14';ADX='14';RSI='14';Bands='20';VWAP='48';Stop='5'},
   [pscustomobject]@{Name='rvtf_h2_mid';Family='h2';Role='mid_duration';Timeframe='16386';ATR='11';ADX='11';RSI='11';Bands='15';VWAP='36';Stop='4'},
   [pscustomobject]@{Name='rvtf_h2_duration';Family='h2';Role='duration_normalized';Timeframe='16386';ATR='7';ADX='7';RSI='7';Bands='10';VWAP='24';Stop='3'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Discovery only. A timeframe family may open post-2020 holdout only when at least two of its three fixed horizon interpretations are profitable in both disjoint eras, continuous PF >= 1.50, at least 24 trades, DD <= 1.50%, recovery >= 2.0, and at least one supported row improves isolated-H1 continuous net by >= 10% and CAGR by >= 0.10 point without fewer trades. No threshold rescue, risk increase, minimum-lot forcing, or Model 4 run after failure.'

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
   Set-FixedInput $inputs 'InpRVSignalTimeframe' $variant.Timeframe
   Set-FixedInput $inputs 'InpRVATRPeriod' $variant.ATR
   Set-FixedInput $inputs 'InpRVADXPeriod' $variant.ADX
   Set-FixedInput $inputs 'InpRVRSIPeriod' $variant.RSI
   Set-FixedInput $inputs 'InpRVBollingerPeriod' $variant.Bands
   Set-FixedInput $inputs 'InpRVVWAPLookbackBars' $variant.VWAP
   Set-FixedInput $inputs 'InpRVStopLookbackBars' $variant.Stop
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Family=$variant.Family;Role=$variant.Role
         Phase='reversion_timeframe_transfer_discovery_model1';Window=$window.Name;From=$window.From;To=$window.To
         Model=1;Deposit=10000;SignalTimeframe=$variant.Timeframe;ATRPeriod=$variant.ATR;ADXPeriod=$variant.ADX
         RSIPeriod=$variant.RSI;BollingerPeriod=$variant.Bands;VWAPLookbackBars=$variant.VWAP;StopLookbackBars=$variant.Stop
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
$queuePath = Resolve-RepoPath 'outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_QUEUE.csv'
$rows | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
@(
   '# Reversion Timeframe-Transfer Discovery Contract','',
   '**Status: PREREGISTERED PRE-2021 RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Source SHA-256: ``$sourceHash``", "- Leader profile SHA-256: ``$leaderHash``", "- Manifest SHA-256: ``$manifestHash``", '',
   '- The exact leader source is used with momentum and adaptive-trend lanes disabled so only band/VWAP reversion is measured.',
   '- H1 is the isolated control. M30 and H2 each have fixed local-bar, midpoint, and elapsed-duration-normalized interpretations.',
   '- Requested reversion risk remains 0.45%, portfolio open risk remains capped at 0.75%, and untradable minimum volume is refused.',
   "- $stopRule",
   '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned behavior, capital change, forward substitution, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
