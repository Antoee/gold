[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Feature_Telemetry_Research.mq5',
   [string]$LeaderProfilePath='release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir='outputs\four_lane_m15_squeeze_feature_telemetry_model1_package',
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_MODEL1_MANIFEST.csv',
   [string]$ContractPath='outputs\FOUR_LANE_M15_SQUEEZE_FEATURE_TELEMETRY_CONTRACT.md'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path;$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash='C6B4BC66F661BB70CC51B92E320A87A5643745454C26791B09766F84DA9C94C4'
$expectedLeaderHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'
$expectedPartialDecisionHash='22D031D7C398B7F76DF988523B849C295C812FE650BAAA1BE9773FC94419AD20'
$expectedAnalyzerHash='EDD9DC6CE723F111C9C888B321DF76405A0E581AF539C0DD04F566912E7558C8'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Convert-SourceDefault([string]$Type,[string]$Value){$v=$Value.Trim();if($Type -eq 'string'){return $v.Substring(1,$v.Length-2)};if($Type -eq 'ENUM_TIMEFRAMES'){$map=@{PERIOD_M15='15';PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'};if(!$map.ContainsKey($v)){throw "Unsupported timeframe: $v"};return $map[$v]};return $v}
function Get-SourceInputs([string]$Path){$inputs=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){continue};$type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3];if($inputs.Contains($name)){throw "Duplicate input: $name"};$inputs[$name]=if($type -eq 'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}};return $inputs}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){if(!$Inputs.Contains($Name)){throw "Unknown input: $Name"};$Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}}
function Clear-OutputDirSafe([string]$Path){if(Test-Path -LiteralPath $Path){$resolved=(Resolve-Path -LiteralPath $Path).Path;if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear $resolved"};Remove-Item -LiteralPath $resolved -Recurse -Force};New-Item -ItemType Directory -Path $Path -Force|Out-Null}

& (Join-Path $PSScriptRoot 'test_four_lane_m15_squeeze_feature_telemetry_source.ps1')|Out-Null
$analyzer=Join-Path $PSScriptRoot 'analyze_four_lane_m15_squeeze_feature_telemetry.py'
if((Get-FileHash -LiteralPath $analyzer -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedAnalyzerHash){throw 'Frozen telemetry analyzer changed.'}
$partialDecision=Resolve-RepoPath 'outputs\FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_DECISION.md'
if((Get-FileHash -LiteralPath $partialDecision -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedPartialDecisionHash){throw 'Partial-runner decision identity changed.'}
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path;$leader=(Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant();$leaderHash=(Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash){throw "Telemetry source changed: $sourceHash"};if($leaderHash -ne $expectedLeaderHash){throw 'Leader profile changed.'}
$inputs=Get-SourceInputs $source;if($inputs.Count -ne 252){throw "Expected 252 source inputs, found $($inputs.Count)."}
$leaderCount=0;foreach($line in Get-Content -LiteralPath $leader){if($line -notmatch '^(Inp[^=]+)=(.*)$'){continue};$name=$Matches[1];if(!$inputs.Contains($name)){throw "Leader input missing: $name"};$inputs[$name]=$line;$leaderCount++};if($leaderCount -ne 185){throw "Expected 185 leader inputs, found $leaderCount."}
Set-FixedInput $inputs 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $inputs 'InpEvidenceRunLabel' 'four_lane_m15_squeeze_feature_telemetry_model1' -StringValue
Set-FixedInput $inputs 'InpLogTrades' 'true';Set-FixedInput $inputs 'InpShowDashboard' 'false'
Set-FixedInput $inputs 'InpRVLogFileName' 'SQUEEZE_FEATURE_TELEMETRY_RV_AUX.csv' -StringValue
Set-FixedInput $inputs 'InpMOLogFileName' 'SQUEEZE_FEATURE_TELEMETRY_MO_AUX.csv' -StringValue
Set-FixedInput $inputs 'InpATBLogFileName' 'SQUEEZE_FEATURE_TELEMETRY_ATB_AUX.csv' -StringValue
Set-FixedInput $inputs 'InpSQLogFileName' 'SQUEEZE_FEATURE_TELEMETRY_2015_2020.csv' -StringValue
Set-FixedInput $inputs 'InpSQEnabled' 'true';Set-FixedInput $inputs 'InpMaximumAccountPositions' '4';Set-FixedInput $inputs 'InpSQRiskPercent' '0.10';Set-FixedInput $inputs 'InpSQTakeProfitR' '1.50'
Set-FixedInput $inputs 'InpSQUsePartialRunner' 'true';Set-FixedInput $inputs 'InpSQPartialClosePercent' '80';Set-FixedInput $inputs 'InpSQPartialTriggerR' '1.50';Set-FixedInput $inputs 'InpSQPartialTargetR' '4.00';Set-FixedInput $inputs 'InpSQPartialStopLockR' '1.25'

$package=Resolve-RepoPath $PackageDir;Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source';New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$profilePath=Join-Path $profileDir 'sqft_control.set';@($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII;$profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
$configPath=Join-Path $configDir '001_sqft_control_continuous_2015_2020_m1.ini';$reportName='sqft_control_continuous_2015_2020_m1'
Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From '2015.01.01' -To '2020.12.31' -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
$stopRule='Behavior-neutral telemetry only. Exact Model 1 reproduction requires +1695.16 net, 391 report trades, PF 1.84, and 1.10% rounded drawdown before screening. Feature nomination uses only 2015-2018, requires nonnegative removal impact in both 2015-2016 and 2017-2018, >=75% trade retention, improved kept-trade PF, and two adjacent threshold supports. The selected threshold is then frozen before one-shot 2019-2020 validation, which requires nonnegative removal impact in both years and at least one validating neighbor. Post-2020 data remains unopened.'
$row=[pscustomobject][ordered]@{QueueRank=1;Candidate='sqft_control';CandidateRank=1;Role='behavior_neutral_partial_runner_telemetry';Phase='four_lane_m15_squeeze_feature_telemetry_model1';Window='continuous_2015_2020';From='2015.01.01';To='2020.12.31';Model=1;Deposit=10000;PartialRunnerEnabled='true';ClosePercent='80';TriggerR='1.50';TargetR='4.00';StopLockR='1.25';ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\001_sqft_control_continuous_2015_2020_m1.ini";SourceConfig="$PackageDir\configs\001_sqft_control_continuous_2015_2020_m1.ini";ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule}
$manifest=Resolve-RepoPath $ManifestPath;@($row)|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII;$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@('# Four-Lane M15 Squeeze Feature-Telemetry Contract','','**Status: PREREGISTERED BEHAVIOR-NEUTRAL PRE-2021 RESEARCH. THE VERIFIED LEADER AND FROZEN FORWARD CANDIDATE ARE UNCHANGED.**','',"- Telemetry source SHA-256: ``$sourceHash``","- Leader profile SHA-256: ``$leaderHash``","- Partial-runner decision SHA-256: ``$expectedPartialDecisionHash``","- Frozen analyzer SHA-256: ``$expectedAnalyzerHash``","- Manifest SHA-256: ``$manifestHash``",'','- The fork adds zero inputs and zero buy, sell, partial-close, or stop-modification paths. Features are calculated from completed M15 bars and completed H1 indicator values only after every existing entry gate passes.','- Recorded fields: breakout depth, body ratio, close location, range/ATR, expansion ratio, channel width/ATR, squeeze range/ATR, tick-volume ratio, ATR percentage, ADX, direction-adjusted H1 EMA distance/slope, squeeze-width mean/max, and actual stop/ATR.',"- $stopRule",'- The offline screen is a hypothesis generator, not a performance claim. Any nominated filter must be implemented default-off and pass a separately frozen MT5 neighborhood before newer data can open.','- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, risk increase, capital change, forward substitution, or real-account trading.')|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;ManifestSha256=$manifestHash;ProfileSha256=$profileHash;Configurations=1;Inputs=$inputs.Count;PackageDir=$PackageDir}
