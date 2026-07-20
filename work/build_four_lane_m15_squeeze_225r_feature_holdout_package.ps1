[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Diversifier_Research.mq5',
   [string]$LeaderProfilePath='release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir='outputs\four_lane_m15_squeeze_225r_feature_holdout_model1_package',
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_MODEL1_MANIFEST.csv',
   [string]$ContractPath='outputs\FOUR_LANE_M15_SQUEEZE_225R_FEATURE_HOLDOUT_CONTRACT.md'
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash='5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6'
$expectedLeaderHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'
$expectedDiscoveryDecisionHash='F90C67E8F46C75F74E71B508D19500AB3FF57FDFC1582B36772F645DB5C9E674'
$expectedDiscoveryResultsHash='88F9DBB0BE9092605F6AA907D04CD5E1362D47FC28A50E3CFF77655376C41A76'
$expectedDiscoveryRunHash='908C6C1E6F445C300547EFDA4084BA9257D97F2FAC32552A5335EF6D95F4B4DC'

function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Convert-SourceDefault([string]$Type,[string]$Value){
   $v=$Value.Trim()
   if($Type-eq'string'){return $v.Substring(1,$v.Length-2)}
   if($Type-eq'ENUM_TIMEFRAMES'){
      $map=@{PERIOD_M15='15';PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'}
      if(!$map.ContainsKey($v)){throw "Unsupported timeframe: $v"}
      return $map[$v]
   }
   return $v
}
function Get-SourceInputs([string]$Path){
   $inputs=[ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path){
      if($line-notmatch'^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){continue}
      $type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3]
      if($inputs.Contains($name)){throw "Duplicate input: $name"}
      $inputs[$name]=if($type-eq'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}
   }
   return $inputs
}
function Copy-Inputs($Inputs){$copy=[ordered]@{};foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]};return $copy}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){
   if(!$Inputs.Contains($Name)){throw "Unknown input: $Name"}
   $Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}
}
function Assert-Hash([string]$Path,[string]$Expected,[string]$Label){
   $actual=(Get-FileHash -LiteralPath (Resolve-RepoPath $Path) -Algorithm SHA256).Hash.ToUpperInvariant()
   if($actual-ne$Expected){throw "$Label changed: $actual"}
}
function Clear-OutputDirSafe([string]$Path){
   if(Test-Path -LiteralPath $Path){
      $resolved=(Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear $resolved"}
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force|Out-Null
}

& (Join-Path $PSScriptRoot 'test_four_lane_m15_squeeze_diversifier_source.ps1')|Out-Null
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_DECISION.md' $expectedDiscoveryDecisionHash 'Discovery decision'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_MODEL1_RESULTS.csv' $expectedDiscoveryResultsHash 'Discovery results'
Assert-Hash 'outputs\FOUR_LANE_M15_SQUEEZE_TARGET_INTERACTION_DISCOVERY_RUN_ATTESTATION.csv' $expectedDiscoveryRunHash 'Discovery run attestation'
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader=(Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash=(Get-FileHash $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash=(Get-FileHash $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash-ne$expectedSourceHash){throw 'Research source changed.'}
if($leaderHash-ne$expectedLeaderHash){throw 'Leader profile changed.'}

$base=Get-SourceInputs $source
if($base.Count-ne247){throw "Expected 247 source inputs, found $($base.Count)."}
$leaderCount=0
foreach($line in Get-Content -LiteralPath $leader){
   if($line-notmatch'^(Inp[^=]+)=(.*)$'){continue}
   $name=$Matches[1]
   if(!$base.Contains($name)){throw "Leader input missing: $name"}
   $base[$name]=$line;$leaderCount++
}
if($leaderCount-ne185){throw "Expected 185 leader inputs, found $leaderCount."}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'four_lane_m15_squeeze_225r_feature_holdout_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants=@(
   [pscustomobject]@{Name='sqh_exact_control';Role='exact_leader_control';Enabled='false';Positions='3';Target='1.50'},
   [pscustomobject]@{Name='sqh_capacity_control';Role='disabled_four_position_control';Enabled='false';Positions='4';Target='1.50'},
   [pscustomobject]@{Name='sqh_reference150';Role='enabled_reference';Enabled='true';Positions='4';Target='1.50'},
   [pscustomobject]@{Name='sqh_lower200';Role='lower_sensitivity';Enabled='true';Positions='4';Target='2.00'},
   [pscustomobject]@{Name='sqh_center225';Role='frozen_training_nomination';Enabled='true';Positions='4';Target='2.25'},
   [pscustomobject]@{Name='sqh_upper250';Role='upper_sensitivity';Enabled='true';Positions='4';Target='2.50'}
)
$windows=@(
   [pscustomobject]@{Name='holdout_2021_2023';From='2021.01.01';To='2023.12.31'},
   [pscustomobject]@{Name='latest_2024_2026';From='2024.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2021_2026';From='2021.01.01';To='2026.07.12'}
)
$stopRule='One-shot feature holdout only. Exact and capacity controls must match in every window. Every row must be profitable. The fixed 2.25R center must be no worse than exact control in both disjoint eras, improve continuous net >=10% and CAGR >=control +0.15 point, beat the enabled 1.50R reference by >=3% continuous net, retain PF/recovery >=95% of exact control, keep return/DD >=exact control, DD <=min(1.50%, exact control +0.20 point), retain >=95% of exact-control report trades, and differ from the 1.50R reference. At least one fixed 2.00R or 2.50R sensitivity row must be no worse than exact control in both eras, improve continuous net >=5%, retain PF/recovery/return-DD >=90% of exact control, and meet the same DD and activity limits. No alternate target selection or post-result rescue.'

$package=Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item $source (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$ordinal=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++
   $inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpSQEnabled' $variant.Enabled
   Set-FixedInput $inputs 'InpSQRiskPercent' '0.10'
   Set-FixedInput $inputs 'InpSQTakeProfitR' $variant.Target
   Set-FixedInput $inputs 'InpMaximumAccountPositions' $variant.Positions
   $profilePath=Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++
      $configName='{0:000}_{1}_{2}_m1.ini'-f$ordinal,$variant.Name,$window.Name
      $configPath=Join-Path $configDir $configName
      $reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='four_lane_m15_squeeze_225r_feature_holdout_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;FeatureEnabled=$variant.Enabled;MaximumAccountPositions=$variant.Positions;SqueezeRiskPercent='0.10';SqueezeTakeProfitR=$variant.Target;BreakoutLookbackBars='8';MaximumHoldBars='32';MaximumPortfolioOpenRiskPercent='0.75';ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash $configPath -Algorithm SHA256).Hash.ToUpperInvariant();ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      })|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath
$rows|Export-Csv $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@(
   '# Four-Lane M15 Squeeze 2.25R Feature Holdout Contract','',
   '**Status: PREREGISTERED ONE-SHOT POST-2020 FEATURE HOLDOUT. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Exact leader profile SHA-256: ``$leaderHash``",
   "- Frozen discovery decision SHA-256: ``$expectedDiscoveryDecisionHash``",
   "- Frozen discovery results SHA-256: ``$expectedDiscoveryResultsHash``",
   "- Frozen discovery run SHA-256: ``$expectedDiscoveryRunHash``",
   "- Holdout manifest SHA-256: ``$manifestHash``",'',
   '- The 2.25R target was nominated only from 2015-2020 training. It made +$1,753.53 versus +$1,379.93 exact control, with PF 1.87 versus 1.88 and the same 1.10% drawdown ceiling. This does not count as validation.',
   '- The feature-specific 2021-2026 outcomes were not opened before this contract. The 2.25R center is fixed; 2.00R and 2.50R are fixed sensitivity rows and cannot replace it.',
   '- Entry, squeeze, trend, stop, break-even, session, risk, lot, account-cap, loss-limit, capital-contract, and real-account settings are unchanged. Only the fixed squeeze target differs among enabled rows.',
   "- $stopRule",
   '- A passing Model 1 holdout may open one separately frozen full-history Model 4 confirmation. A failure closes this target family.',
   '- No martingale, grid, averaging down, recovery sizing, capital change, forward substitution, or real-account trading.'
)|Set-Content (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status='READY';SourceSha256=$sourceHash;ManifestSha256=$manifestHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
