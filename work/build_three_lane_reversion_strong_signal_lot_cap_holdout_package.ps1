[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5',
   [string]$ChampionProfilePath='release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir='outputs\three_lane_reversion_strong_signal_lot_cap_holdout_model1_package',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_HOLDOUT_MODEL1_MANIFEST.csv',
   [string]$QueuePath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_HOLDOUT_MODEL1_QUEUE.csv',
   [string]$PackageMarkdownPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_HOLDOUT_MODEL1_PACKAGE.md',
   [string]$ContractPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_HOLDOUT_CONTRACT.md'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path;$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$sourceHash='C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91';$championHash='705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E'
$expectedControlHash='AD0289B7A96150C930B54A2C44845C11DF05D42FD9A8D8DE4FA2703C308697F6';$expectedCenterHash='A0099C6701311BAE105F29909166358D4D30050593318F340AD8F3B932F65F04'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Clear-OutputDirSafe([string]$Path){if(Test-Path -LiteralPath $Path){$resolved=(Resolve-Path -LiteralPath $Path).Path;if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe package path: $resolved"};Remove-Item -LiteralPath $resolved -Recurse -Force};New-Item -ItemType Directory -Path $Path -Force|Out-Null}
function Convert-SourceDefault([string]$Type,[string]$Value){$v=$Value.Trim();if($Type -eq 'string'){return $v.Substring(1,$v.Length-2)};if($Type -eq 'ENUM_TIMEFRAMES'){$map=@{PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'};return $map[$v]};return $v}
function Get-SourceInputs([string]$Path){$inputs=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -match '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){$type=$Matches[1];$name=$Matches[2];$v=Convert-SourceDefault $type $Matches[3];$inputs[$name]=if($type -eq 'string'){"$name=$v"}else{"$name=$v||$v||0||0||N"}}};return $inputs}
function Copy-Inputs($Inputs){$copy=[ordered]@{};foreach($k in $Inputs.Keys){$copy[$k]=$Inputs[$k]};return $copy}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){if(!$Inputs.Contains($Name)){throw "Unknown input $Name"};$Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}}

$discovery=Import-Csv (Join-Path $repo 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.csv')
if($discovery.Status -ne 'DISCOVERY_GATE_PASSED' -or $discovery.HoldoutValidationPermitted -ne 'True' -or $discovery.SourceSha256 -ne $sourceHash -or $discovery.CenterProfileSha256 -ne $expectedCenterHash){throw 'Exact discovery authorization is missing or changed.'}
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path;$champion=(Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
if((Get-FileHash $source -Algorithm SHA256).Hash -ne $sourceHash -or (Get-FileHash $champion -Algorithm SHA256).Hash -ne $championHash){throw 'Source or champion identity changed.'}
$base=Get-SourceInputs $source;if($base.Count -ne 183){throw 'Research input count changed.'}
foreach($line in Get-Content $champion){if($line -match '^(Inp[^=]+)='){$base[$Matches[1]]=$line}}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue;Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_strong_signal_lot_cap_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false';Set-FixedInput $base 'InpShowDashboard' 'false';Set-FixedInput $base 'InpRVUseStrongSignalRisk' 'false';Set-FixedInput $base 'InpRVStrongSignalMinimumBodyRatio' '0.25';Set-FixedInput $base 'InpRVStrongSignalRiskPercent' '0.60'
$profiles=@(
 [pscustomobject]@{Candidate='sslc_control';Role='exact_control';Selective='false';StrongCap='0.15';ExpectedHash=$expectedControlHash},
 [pscustomobject]@{Candidate='sslc_center015';Role='frozen_discovery_center';Selective='true';StrongCap='0.15';ExpectedHash=$expectedCenterHash}
)
$windows=@(
 [pscustomobject]@{Name='holdout_2021_2022';From='2021.01.01';To='2022.12.31'},
 [pscustomobject]@{Name='holdout_2023_2024';From='2023.01.01';To='2024.12.31'},
 [pscustomobject]@{Name='holdout_2025_2026';From='2025.01.01';To='2026.07.18'},
 [pscustomobject]@{Name='continuous_2021_2026';From='2021.01.01';To='2026.07.18'}
)
$stopRule='Exact center recent-data validation only. Every center window positive and no worse than control. Continuous center net >=control +5%, CAGR >=control +0.08 point, PF/recovery/return-DD >=control, DD <=1.35% and <=control +0.10 point, trades >=control -2. No setting change after opening.'
$package=Resolve-RepoPath $PackageDir;Clear-OutputDirSafe $package;$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source';New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null;Copy-Item $source (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5')
$queue=[Collections.Generic.List[object]]::new();$run=[Collections.Generic.List[object]]::new();$rank=0
foreach($profile in $profiles){$inputs=Copy-Inputs $base;Set-FixedInput $inputs 'InpRVUseStrongSignalLotCap' $profile.Selective;Set-FixedInput $inputs 'InpRVMaximumPositionLots' '0.10';Set-FixedInput $inputs 'InpRVStrongSignalMaximumPositionLots' $profile.StrongCap;$profileName="$($profile.Candidate).set";$profileOut=Join-Path $profileDir $profileName;@($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content $profileOut -Encoding ASCII;$hash=(Get-FileHash $profileOut -Algorithm SHA256).Hash;if($hash -ne $profile.ExpectedHash){throw "Profile identity changed: $($profile.Candidate) $hash"}
 foreach($window in $windows){$rank++;$configName='{0:000}_{1}_{2}_m1.ini' -f $rank,$profile.Candidate,$window.Name;$config=Join-Path $configDir $configName;$reportName="$($profile.Candidate)_$($window.Name)_m1";Write-SeasonalTesterConfig -Path $config -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15;$configHash=(Get-FileHash $config -Algorithm SHA256).Hash;$common=[ordered]@{QueueRank=$rank;Candidate=$profile.Candidate;Role=$profile.Role;Phase='three_lane_reversion_strong_signal_lot_cap_holdout_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;StrongSignalBodyRatio='0.25';ReversionRiskPercent='0.45';SelectiveLotCapEnabled=$profile.Selective;BaseReversionMaximumPositionLots='0.10';StrongSignalMaximumPositionLots=$profile.StrongCap;ExpectedReportName=$reportName;ConfigSha256=$configHash;ProfileSha256=$profile.ExpectedHash;SourceSha256=$sourceHash;StopRule=$stopRule};$queue.Add([pscustomobject]($common+[ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"}))|Out-Null;$run.Add([pscustomobject]($common+[ordered]@{PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"}))|Out-Null}}
$queue|Export-Csv (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII;$run|Export-Csv (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@('# Strong-Signal Selective Lot-Cap Recent-Data Package','','**Status: FROZEN FEATURE-LEVEL 2021-2026 VALIDATION. MODEL 4 REMAINS CLOSED.**','',"- Source: ``$sourceHash``","- Control profile: ``$expectedControlHash``","- Center profile: ``$expectedCenterHash``",'- Profiles: `2`; configurations: `8`','- The center is exact discovery identity. These years are not globally untouched because prior ATB150 research examined them.','- No setting may change after opening; any losing or weaker center window closes Model 4.')|Set-Content (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@('# Strong-Signal Selective Lot-Cap Recent-Data Contract','','**Status: RESEARCH ONLY. NOT MODEL-4, FORWARD, OR REAL-MONEY APPROVAL.**','','- Freeze exact discovery control and center across 2021-2022, 2023-2024, 2025-2026 YTD, and continuous 2021-2026.','- Require every center window positive and no worse than paired control net. Require continuous center net at least 5% above control and CAGR at least 0.08 point above control.','- Require continuous PF, recovery, and return/drawdown no worse than control; drawdown at most 1.35% and no more than 0.10 point above control; trades at least control minus two.','- Reject on identity mismatch, losing/weaker window, efficiency loss, excess drawdown, or any need to change body threshold/cap. Only an exact pass may open a separately frozen Model 4 comparison.','- Keep requested risk, stops, targets, exposure/loss/capital guards, forward candidate, and real-account lock unchanged.')|Set-Content (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;ControlProfileSha256=$expectedControlHash;CenterProfileSha256=$expectedCenterHash;Profiles=2;Windows=4;Configurations=$rank;LatestDate='2026-07-18'}
