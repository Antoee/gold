[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Partial_Runner_Research.mq5',
   [string]$LeaderProfilePath='release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir='outputs\four_lane_m15_squeeze_partial_runner_discovery_model1_package',
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ContractPath='outputs\FOUR_LANE_M15_SQUEEZE_PARTIAL_RUNNER_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash='1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005'
$expectedLeaderHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'
$expectedReferenceDecisionHash='8263EE47CA4BD74160BBE93B28BCF695DF641C9E60AF296C7B7FD6CEDD8A03DF'

function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Convert-SourceDefault([string]$Type,[string]$Value){$v=$Value.Trim();if($Type -eq 'string'){return $v.Substring(1,$v.Length-2)};if($Type -eq 'ENUM_TIMEFRAMES'){$map=@{PERIOD_M15='15';PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'};if(!$map.ContainsKey($v)){throw "Unsupported timeframe: $v"};return $map[$v]};return $v}
function Get-SourceInputs([string]$Path){$inputs=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){continue};$type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3];if($inputs.Contains($name)){throw "Duplicate input: $name"};$inputs[$name]=if($type -eq 'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}};return $inputs}
function Copy-Inputs($Inputs){$copy=[ordered]@{};foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]};return $copy}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){if(!$Inputs.Contains($Name)){throw "Unknown input: $Name"};$Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}}
function Clear-OutputDirSafe([string]$Path){if(Test-Path -LiteralPath $Path){$resolved=(Resolve-Path -LiteralPath $Path).Path;if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear $resolved"};Remove-Item -LiteralPath $resolved -Recurse -Force};New-Item -ItemType Directory -Path $Path -Force|Out-Null}

& (Join-Path $PSScriptRoot 'test_four_lane_m15_squeeze_partial_runner_source.ps1')|Out-Null
$referenceDecision=Resolve-RepoPath 'outputs\FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_DECISION.md'
if((Get-FileHash -LiteralPath $referenceDecision -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedReferenceDecisionHash){throw 'Integrated squeeze reference decision changed.'}
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader=(Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash=(Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash){throw "Research source changed: $sourceHash"}
if($leaderHash -ne $expectedLeaderHash){throw "Leader profile changed: $leaderHash"}
$base=Get-SourceInputs $source
if($base.Count -ne 252){throw "Expected 252 source inputs, found $($base.Count)."}
$leaderCount=0
foreach($line in Get-Content -LiteralPath $leader){if($line -notmatch '^(Inp[^=]+)=(.*)$'){continue};$name=$Matches[1];if(!$base.Contains($name)){throw "Leader input missing: $name"};$base[$name]=$line;$leaderCount++}
if($leaderCount -ne 185){throw "Expected 185 leader inputs, found $leaderCount."}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'four_lane_m15_squeeze_partial_runner_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants=@(
   [pscustomobject]@{Name='sqpr_exact_control';Role='exact_leader_control';SQ='false';Positions='3';Runner='false';Close='80';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_reference';Role='active_squeeze_reference';SQ='true';Positions='4';Runner='false';Close='80';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_center';Role='fixed_center';SQ='true';Positions='4';Runner='true';Close='80';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_close70';Role='close_neighbor_low';SQ='true';Positions='4';Runner='true';Close='70';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_close90';Role='close_neighbor_high';SQ='true';Positions='4';Runner='true';Close='90';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_target300';Role='target_neighbor_low';SQ='true';Positions='4';Runner='true';Close='80';Target='3.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_target500';Role='target_neighbor_high';SQ='true';Positions='4';Runner='true';Close='80';Target='5.00';Lock='1.25'},
   [pscustomobject]@{Name='sqpr_lock100';Role='lock_neighbor_low';SQ='true';Positions='4';Runner='true';Close='80';Target='4.00';Lock='1.00'},
   [pscustomobject]@{Name='sqpr_lock140';Role='lock_neighbor_high';SQ='true';Positions='4';Runner='true';Close='80';Target='4.00';Lock='1.40'}
)
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule='Pre-2021 discovery only. Exact leader control and active 1.50R squeeze reference must reproduce prior results. Every report must be profitable. Fixed 80%/4R/+1.25R center must be no worse than the active reference in both disjoint eras, improve continuous net >=3% and CAGR >=0.08 point, retain PF >=98% of leader control, recovery and return/drawdown >=active reference, keep DD <=1.30% and <=reference+0.15 point, and produce 380-450 report trades. At least three of six one-factor neighbors must retain >=98% of reference net in both eras, improve continuous net >=1%, retain PF >=98% of leader control and recovery/return-DD >=98% of reference, and meet the same DD/activity limits. No alternate center, threshold rescue, or post-result parameter selection.'

$package=Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$ordinal=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++;$inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpSQEnabled' $variant.SQ
   Set-FixedInput $inputs 'InpSQRiskPercent' '0.10'
   Set-FixedInput $inputs 'InpSQTakeProfitR' '1.50'
   Set-FixedInput $inputs 'InpMaximumAccountPositions' $variant.Positions
   Set-FixedInput $inputs 'InpSQUsePartialRunner' $variant.Runner
   Set-FixedInput $inputs 'InpSQPartialClosePercent' $variant.Close
   Set-FixedInput $inputs 'InpSQPartialTriggerR' '1.50'
   Set-FixedInput $inputs 'InpSQPartialTargetR' $variant.Target
   Set-FixedInput $inputs 'InpSQPartialStopLockR' $variant.Lock
   $profilePath=Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++;$configName='{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name;$configPath=Join-Path $configDir $configName;$reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='four_lane_m15_squeeze_partial_runner_discovery_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;SqueezeEnabled=$variant.SQ;MaximumAccountPositions=$variant.Positions;PartialRunnerEnabled=$variant.Runner;ClosePercent=$variant.Close;TriggerR='1.50';TargetR=$variant.Target;StopLockR=$variant.Lock;SqueezeRiskPercent='0.10';SqueezeTakeProfitR='1.50';ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath
$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@(
   '# Four-Lane M15 Squeeze Partial-Runner Discovery Contract','',
   '**Status: PREREGISTERED PRE-2021 CODE RESEARCH. THE PUBLISHED LEADER AND FROZEN FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``","- Exact leader profile SHA-256: ``$leaderHash``","- Integrated squeeze reference decision SHA-256: ``$expectedReferenceDecisionHash``","- Manifest SHA-256: ``$manifestHash``",'',
   '- Frozen center: eligible squeeze positions bank 80% at +1.50R only after locking the remainder at +1.25R; the remainder targets +4.00R. Unsplittable positions retain the original +1.50R target.',
   '- Frozen one-factor neighborhood: close 70/90%, runner target +3.00/+5.00R, and stop lock +1.00/+1.40R. Trigger, entries, stops, initial risk, portfolio limits, and all other settings remain fixed.',
   '- State is persisted by owned position identifier. A restart cannot replay the partial close. Stop protection is confirmed before any partial close; state or execution ambiguity fails closed.',
   "- $stopRule",
   '- Reject identity mismatch, compiler warning, losing broad window, inactive runner, efficiency failure, isolated center, or any result needing a changed threshold. Only the exact frozen center may open a separately frozen post-2020 gate.',
   '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, capital change, forward substitution, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
