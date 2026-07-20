[CmdletBinding()]
param(
   [string]$SourcePath='work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Diversifier_Research.mq5',
   [string]$LeaderProfilePath='release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir='outputs\four_lane_m15_squeeze_diversifier_discovery_model1_package',
   [string]$ManifestPath='outputs\FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ContractPath='outputs\FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash='5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6'
$expectedLeaderHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'
$independentSourceHash='A47F7A8ED05916A07A7CCF713340C64B1DFF950504E28744212EA8FD5CA94F29'
$independentProfileHash='1DE7D321D06A3BC046302C73C47ED7B346A558A1F82EFCBC75C9C513638EAB4B'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Convert-SourceDefault([string]$Type,[string]$Value){$v=$Value.Trim();if($Type -eq 'string'){return $v.Substring(1,$v.Length-2)};if($Type -eq 'ENUM_TIMEFRAMES'){$map=@{PERIOD_M15='15';PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'};if(!$map.ContainsKey($v)){throw "Unsupported timeframe: $v"};return $map[$v]};return $v}
function Get-SourceInputs([string]$Path){$inputs=[ordered]@{};foreach($line in Get-Content -LiteralPath $Path){if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$'){continue};$type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3];if($inputs.Contains($name)){throw "Duplicate input: $name"};$inputs[$name]=if($type -eq 'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}};return $inputs}
function Copy-Inputs($Inputs){$copy=[ordered]@{};foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]};return $copy}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue){if(!$Inputs.Contains($Name)){throw "Unknown input: $Name"};$Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}}
function Clear-OutputDirSafe([string]$Path){if(Test-Path -LiteralPath $Path){$resolved=(Resolve-Path -LiteralPath $Path).Path;if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear $resolved"};Remove-Item -LiteralPath $resolved -Recurse -Force};New-Item -ItemType Directory -Path $Path -Force|Out-Null}

& (Join-Path $PSScriptRoot 'test_four_lane_m15_squeeze_diversifier_source.ps1')|Out-Null
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader=(Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash=(Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash){throw "Research source changed: $sourceHash"}
if($leaderHash -ne $expectedLeaderHash){throw "Leader profile changed: $leaderHash"}
$base=Get-SourceInputs $source
if($base.Count -ne 247){throw "Expected 247 source inputs, found $($base.Count)."}
$leaderCount=0
foreach($line in Get-Content -LiteralPath $leader){if($line -notmatch '^(Inp[^=]+)=(.*)$'){continue};$name=$Matches[1];if(!$base.Contains($name)){throw "Leader input missing: $name"};$base[$name]=$line;$leaderCount++}
if($leaderCount -ne 185){throw "Expected 185 leader inputs, found $leaderCount."}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'four_lane_m15_squeeze_diversifier_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants=@(
   [pscustomobject]@{Name='sq_exact_control';Role='exact_leader_control';Enabled='false';Positions='3';Risk='0.10'},
   [pscustomobject]@{Name='sq_capacity_control';Role='disabled_four_position_control';Enabled='false';Positions='4';Risk='0.10'},
   [pscustomobject]@{Name='sq_low0075';Role='lower_neighbor';Enabled='true';Positions='4';Risk='0.075'},
   [pscustomobject]@{Name='sq_center0100';Role='fixed_center';Enabled='true';Positions='4';Risk='0.10'},
   [pscustomobject]@{Name='sq_high0125';Role='upper_neighbor';Enabled='true';Positions='4';Risk='0.125'}
)
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule='Discovery only. Disabled four-position capacity control must exactly reproduce the disabled three-position leader control. Fixed 0.10% squeeze lane must stay profitable in both disjoint eras, improve continuous net by at least 8% and CAGR by 0.12 point, add at least 40 trades, retain PF/recovery/return-to-drawdown >=98% of control, and keep DD <=1.30% and <=control+0.10 point. At least one 0.075% or 0.125% neighbor must stay profitable in both eras, improve continuous net >=4% and CAGR >=0.06 point, add at least 30 trades, retain PF/recovery/return-DD >=98%, and meet the same DD limits. No alternate-center selection or threshold rescue after observation.'
$package=Resolve-RepoPath $PackageDir;Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$ordinal=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++;$inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpSQEnabled' $variant.Enabled
   Set-FixedInput $inputs 'InpSQRiskPercent' $variant.Risk
   Set-FixedInput $inputs 'InpMaximumAccountPositions' $variant.Positions
   $profilePath=Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++;$configName='{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name;$configPath=Join-Path $configDir $configName;$reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='four_lane_m15_squeeze_diversifier_discovery_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;FeatureEnabled=$variant.Enabled;MaximumAccountPositions=$variant.Positions;SqueezeRiskPercent=$variant.Risk;BreakoutLookbackBars='8';TakeProfitR='1.50';MaximumHoldBars='32';MaximumPortfolioOpenRiskPercent='0.75';ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath;$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
$rows|Export-Csv -LiteralPath (Resolve-RepoPath 'outputs\FOUR_LANE_M15_SQUEEZE_DIVERSIFIER_DISCOVERY_MODEL1_QUEUE.csv') -NoTypeInformation -Encoding ASCII
@('# Four-Lane M15 Squeeze Diversifier Discovery Contract','','**Status: PREREGISTERED PRE-2021 CODE RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**','',"- Research source SHA-256: ``$sourceHash``","- Exact leader profile SHA-256: ``$leaderHash``","- Independent squeeze source SHA-256: ``$independentSourceHash``","- Exact independent b8 profile SHA-256: ``$independentProfileHash``","- Manifest SHA-256: ``$manifestHash``",'','- Nomination used only the frozen independent pre-2021 b8 result: 2015-2018 +$98.71 / PF 1.38 / 55 trades, 2019-2020 +$81.19 / PF 1.57 / 33 trades, continuous +$177.89 / PF 1.44 / 88 trades / 0.48% DD. Post-2020 remained unopened for this exact integration.','- The fourth lane is disabled by default and runs after the three frozen leader lanes. It adds one independently owned position at most; all fills remain subject to the existing 0.75% account-wide open-risk cap.','- The exact b8 signal and exits are frozen. Only lane risk is bracketed at 0.075% / fixed 0.10% / 0.125%. Two disabled controls isolate code and four-position-capacity effects.',"- $stopRule",'- Reject losing broad windows, identity mismatch, compiler warning, safety failure, inactive feature, isolated center, or any result needing a new risk/threshold after observation. Only the exact 0.10% center may open a separately frozen post-2020 gate.','- No martingale, grid, averaging down, recovery sizing, capital change, forward substitution, or real-account trading.')|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
