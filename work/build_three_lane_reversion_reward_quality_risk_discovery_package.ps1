[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Three_Lane_Reversion_Reward_Quality_Risk_Research.mq5',
   [string]$LeaderProfilePath='release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir='outputs\three_lane_reversion_reward_quality_risk_discovery_model1_package',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ContractPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash='A300713711328CE221447E452B889C0A2F9E449E2BF721BE7E49E0A354A4C416'
$expectedLeaderHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Convert-SourceDefault([string]$Type,[string]$Value){$v=$Value.Trim();if($Type -eq 'string'){return $v.Substring(1,$v.Length-2)};if($Type -eq 'ENUM_TIMEFRAMES'){$map=@{PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'};if(!$map.ContainsKey($v)){throw "Unsupported timeframe: $v"};return $map[$v]};return $v}
function Get-SourceInputs([string]$Path){$inputs=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){continue};$type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3];$inputs[$name]=if($type -eq 'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}};return $inputs}
function Copy-Inputs($Inputs){$copy=[ordered]@{};foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]};return $copy}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){if(!$Inputs.Contains($Name)){throw "Unknown input: $Name"};$Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}}
function Clear-OutputDirSafe([string]$Path){if(Test-Path -LiteralPath $Path){$resolved=(Resolve-Path -LiteralPath $Path).Path;if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear $resolved"};Remove-Item -LiteralPath $resolved -Recurse -Force};New-Item -ItemType Directory -Path $Path -Force|Out-Null}

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_reward_quality_risk_source.ps1')|Out-Null
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_reward_quality_risk_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false';Set-FixedInput $base 'InpShowDashboard' 'false'

$variants=@(
   [pscustomobject]@{Name='rqri_control';Role='control';Strong='false';Quality='false';RR='1.50';Risk='0.70'},
   [pscustomobject]@{Name='rqri_body070';Role='body_risk_diagnostic';Strong='true';Quality='false';RR='1.50';Risk='0.70'},
   [pscustomobject]@{Name='rqri_rr135';Role='reward_lower';Strong='true';Quality='true';RR='1.35';Risk='0.70'},
   [pscustomobject]@{Name='rqri_center150_070';Role='center';Strong='true';Quality='true';RR='1.50';Risk='0.70'},
   [pscustomobject]@{Name='rqri_rr165';Role='reward_upper';Strong='true';Quality='true';RR='1.65';Risk='0.70'},
   [pscustomobject]@{Name='rqri_risk065';Role='risk_lower';Strong='true';Quality='true';RR='1.50';Risk='0.65'},
   [pscustomobject]@{Name='rqri_risk075';Role='risk_upper';Strong='true';Quality='true';RR='1.50';Risk='0.75'}
)
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule='Discovery only. The 1.50 RR / 0.70% center must be positive in both eras, improve continuous net >=5% and CAGR >=0.10 point versus exact control, retain at least 98% of control net in each era and all control trades, PF/recovery/return-DD no worse than control, DD <=1.35% and <=control +0.15 point. At least three of the four fixed RR/risk neighbors must independently pass the same era-retention and non-worse efficiency gates with >=3% net and >=0.05-point CAGR growth. No threshold rescue, holdout, or Model 4 after failure.'
$package=Resolve-RepoPath $PackageDir;Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$ordinal=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++;$inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpRVUseStrongSignalRisk' $variant.Strong
   Set-FixedInput $inputs 'InpRVStrongSignalMinimumBodyRatio' '0.25'
   Set-FixedInput $inputs 'InpRVStrongSignalRiskPercent' $variant.Risk
   Set-FixedInput $inputs 'InpRVUseStrongSignalRewardQuality' $variant.Quality
   Set-FixedInput $inputs 'InpRVStrongSignalMinimumRiskReward' $variant.RR
   Set-FixedInput $inputs 'InpRVUseStrongSignalLotCap' 'true'
   Set-FixedInput $inputs 'InpRVStrongSignalMaximumPositionLots' '0.15'
   $profilePath=Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++;$configName='{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name;$configPath=Join-Path $configDir $configName;$reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='reversion_reward_quality_risk_discovery_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;StrongSignalRiskEnabled=$variant.Strong;RewardQualityEnabled=$variant.Quality;MinimumRiskReward=$variant.RR;StrongRiskPercent=$variant.Risk;StrongBodyRatio='0.25';StrongLotCap='0.15';ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath;$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
$rows|Export-Csv -LiteralPath (Resolve-RepoPath 'outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_MODEL1_QUEUE.csv') -NoTypeInformation -Encoding ASCII
@('# Reversion Reward-Quality Risk Discovery Contract','','**Status: PREREGISTERED PRE-2021 CODE RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',"- Source SHA-256: ``$sourceHash``","- Leader profile SHA-256: ``$leaderHash``","- Manifest SHA-256: ``$manifestHash``",'', '- New default-off code permits strong-signal risk only when the existing completed-H1 body test and a fixed spread-adjusted reward/risk threshold both pass.','- The existing body-based 0.15-lot cap remains independent; entries, stops, VWAP targets, exits, and every risk/account lock are unchanged.',"- $stopRule",'- No martingale, grid, averaging down, recovery sizing, outcome conditioning, capital change, forward substitution, or real-account trading.')|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
