[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Three_Lane_Reversion_Solo_Strong_Signal_Lot_Cap_Research.mq5',
   [string]$LeaderProfilePath='release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir='outputs\three_lane_reversion_solo_strong_signal_lot_cap_discovery_model1_package',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ContractPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash='726BCABFA64C25FA3D22E78B41AB4868EA8D5235609294F7ED68DC3DB9088EEE'
$expectedLeaderHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Convert-SourceDefault([string]$Type,[string]$Value){$v=$Value.Trim();if($Type -eq 'string'){return $v.Substring(1,$v.Length-2)};if($Type -eq 'ENUM_TIMEFRAMES'){$map=@{PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'};if(!$map.ContainsKey($v)){throw "Unsupported timeframe: $v"};return $map[$v]};return $v}
function Get-SourceInputs([string]$Path){$inputs=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){continue};$type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3];if($inputs.Contains($name)){throw "Duplicate input: $name"};$inputs[$name]=if($type -eq 'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}};return $inputs}
function Copy-Inputs($Inputs){$copy=[ordered]@{};foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]};return $copy}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){if(!$Inputs.Contains($Name)){throw "Unknown input: $Name"};$Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}}
function Clear-OutputDirSafe([string]$Path){if(Test-Path -LiteralPath $Path){$resolved=(Resolve-Path -LiteralPath $Path).Path;if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear $resolved"};Remove-Item -LiteralPath $resolved -Recurse -Force};New-Item -ItemType Directory -Path $Path -Force|Out-Null}

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_solo_strong_signal_lot_cap_source.ps1')|Out-Null
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader=(Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash=(Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash){throw "Research source changed: $sourceHash"}
if($leaderHash -ne $expectedLeaderHash){throw "Leader profile changed: $leaderHash"}
$base=Get-SourceInputs $source
if($base.Count -ne 187){throw "Expected 187 source inputs, found $($base.Count)."}
$leaderCount=0
foreach($line in Get-Content -LiteralPath $leader){if($line -notmatch '^(Inp[^=]+)=(.*)$'){continue};$name=$Matches[1];if(!$base.Contains($name)){throw "Leader input missing: $name"};$base[$name]=$line;$leaderCount++}
if($leaderCount -ne 185){throw "Expected 185 leader inputs, found $leaderCount."}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_solo_strong_signal_lot_cap_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants=@(
   [pscustomobject]@{Name='rvsolo_control015';Role='exact_leader_control';Enabled='false';SoloCap='0.18'},
   [pscustomobject]@{Name='rvsolo_low017';Role='lower_neighbor';Enabled='true';SoloCap='0.17'},
   [pscustomobject]@{Name='rvsolo_center018';Role='fixed_center';Enabled='true';SoloCap='0.18'},
   [pscustomobject]@{Name='rvsolo_high019';Role='upper_neighbor';Enabled='true';SoloCap='0.19'},
   [pscustomobject]@{Name='rvsolo_boundary020';Role='upper_boundary';Enabled='true';SoloCap='0.20'}
)
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule='Discovery only. Fixed 0.18 solo cap must be profitable, improve both disjoint eras by at least 3%, improve continuous net by at least 4.5% and CAGR by 0.08 point, keep exact trade count, keep PF/recovery/return-to-drawdown no worse, and keep DD <=1.25% and <=control+0.10 point. At least one 0.17 or 0.19 neighbor must improve both eras, continuous net >=3%, CAGR >=0.05 point, retain PF/recovery/return-DD >=98%, exact trades, and the same DD limit. No alternate-center selection or threshold rescue after observation.'
$package=Resolve-RepoPath $PackageDir;Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$ordinal=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++;$inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpRVUseSoloStrongSignalLotCap' $variant.Enabled
   Set-FixedInput $inputs 'InpRVSoloStrongSignalMaximumPositionLots' $variant.SoloCap
   $profilePath=Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++;$configName='{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name;$configPath=Join-Path $configDir $configName;$reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='reversion_solo_strong_signal_lot_cap_discovery_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;FeatureEnabled=$variant.Enabled;SoloStrongSignalMaximumPositionLots=$variant.SoloCap;BaseStrongSignalMaximumPositionLots='0.15';StrongSignalBodyRatio='0.25';ReversionRiskPercent='0.45';MaximumPortfolioOpenRiskPercent='0.75';ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath;$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
$rows|Export-Csv -LiteralPath (Resolve-RepoPath 'outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_QUEUE.csv') -NoTypeInformation -Encoding ASCII
@('# Portfolio-Solo Strong Reversion Lot-Cap Discovery Contract','','**Status: PREREGISTERED PRE-2021 CODE RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',"- Research source SHA-256: ``$sourceHash``","- Exact leader profile SHA-256: ``$leaderHash``","- Manifest SHA-256: ``$manifestHash``",'','- Nomination used only the pre-2021 leader ledger: five current 0.15-lot strong reversion trades entered without another managed lane open; aggregate +$402.42, with positive older and discovery eras. This is weak sample support, not proof.','- The switch is disabled by default. Enabled rows may raise only the existing strong-signal lot cap when no momentum or adaptive-trend position is open. Entry, stop, target, signal threshold, requested risk, trade count logic, and exits are unchanged.','- Requested reversion risk remains 0.45%; account open risk remains capped at 0.75%. The 0.17 / fixed 0.18 / 0.19 neighborhood and 0.20 boundary were frozen before testing.',"- $stopRule",'- Reject losing broad windows, identity mismatch, compiler warning, safety failure, isolated center, or any result needing a new cap/threshold after observation. Only the exact 0.18 center may open a separately frozen post-2020 gate.','- No martingale, grid, averaging down, recovery sizing, capital change, forward substitution, or real-account trading.')|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
