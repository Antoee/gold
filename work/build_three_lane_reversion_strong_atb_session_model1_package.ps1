[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Tick_Protection_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_strong_atb_session_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = '096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248'
$expectedChampionHash = '705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}
function Convert-SourceDefault([string]$Type, [string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq 'string') { return $trimmed.Substring(1, $trimmed.Length - 2) }
   if($Type -eq 'ENUM_TIMEFRAMES') {
      $map = @{ PERIOD_H1='16385'; PERIOD_H4='16388'; PERIOD_D1='16408' }
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
      if($inputs.Contains($name)) { throw "Duplicate source input: $name" }
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

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_strong_signal_tick_protection_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 184) { throw "Expected 184 research inputs, found $($base.Count)." }
$championKeys = [Collections.Generic.List[string]]::new()
foreach($line in Get-Content -LiteralPath $championProfile) {
   if($line -notmatch '^(Inp[^=]+)=(.*)$') { continue }
   $name = $Matches[1]
   if(!$base.Contains($name)) { throw "Champion input is missing from research source: $name" }
   $base[$name] = $line
   $championKeys.Add($name) | Out-Null
}
if($championKeys.Count -ne 178) { throw "Expected 178 champion inputs, found $($championKeys.Count)." }
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_strong_atb_session_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvsats_champion';Role='champion_control';Strong='false';Session='false';Start=6;End=20},
   [pscustomobject]@{Name='rvsats_strong';Role='strong_control';Strong='true';Session='false';Start=6;End=20},
   [pscustomobject]@{Name='rvsats_12_1';Role='lower_neighbor';Strong='true';Session='true';Start=12;End=1},
   [pscustomobject]@{Name='rvsats_16_1';Role='center';Strong='true';Session='true';Start=16;End=1},
   [pscustomobject]@{Name='rvsats_16_9';Role='upper_neighbor';Strong='true';Session='true';Start=16;End=9}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$stopRule = 'ATB session-shaped strong-reversion follow-up. Center 16-1 must beat both controls in every era; continuous net >= champion +10% and strong control +2%; CAGR >= champion +0.15 point and strong control +0.03 point; PF/recovery/return-DD >= both controls; DD <=1.25% and <=champion +0.08 point; trades >=380. Each 12-1 and 16-9 neighbor must retain >=99% of strong-control net in every era, continuous net >= strong control +1%, CAGR >= strong control +0.02 point, PF/recovery/return-DD >= strong control, DD <=1.25%, and trades >=385. No post-result hour search.'

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package 'configs'
$profileDir = Join-Path $package 'profiles'
$reportDir = Join-Path $package 'reports_here'
$sourceDir = Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$queueRows = [Collections.Generic.List[object]]::new()
$runRows = [Collections.Generic.List[object]]::new()
$ordinal = 0
$candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Copy-Inputs $base
   Set-FixedInput $inputs 'InpRVUseStrongSignalRisk' $variant.Strong
   Set-FixedInput $inputs 'InpRVStrongSignalMinimumBodyRatio' '0.25'
   Set-FixedInput $inputs 'InpRVStrongSignalRiskPercent' '0.70'
   Set-FixedInput $inputs 'InpRVUseStrongSignalProtection' 'false'
   Set-FixedInput $inputs 'InpATBRiskPercent' '0.15'
   Set-FixedInput $inputs 'InpATBUseSessionFilter' $variant.Session
   Set-FixedInput $inputs 'InpATBSessionStartHour' ([string]$variant.Start)
   Set-FixedInput $inputs 'InpATBSessionEndHour' ([string]$variant.End)
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows) {
      $ordinal++
      $configName = '{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $common = [ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='three_lane_reversion_strong_atb_session_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         StrongSignalRiskEnabled=$variant.Strong;StrongSignalMinimumBodyRatio='0.25';StrongSignalRiskPercent='0.70';AdaptiveTrendRiskPercent='0.15'
         ATBSessionEnabled=$variant.Session;ATBSessionStartHour=$variant.Start;ATBSessionEndHour=$variant.End
         ExpectedReportName=$reportName;ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      }
      $queueRows.Add([pscustomobject]($common + [ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"})) | Out-Null
      $runRows.Add([pscustomobject]($common + [ordered]@{
         PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
         ReportDestination="$PackageDir\reports_here\$reportName"
      })) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Three-Lane Strong-Reversion / ATB Session Model 1 Package','',
   '**Status: PREREGISTERED DATA-INFORMED FOLLOW-UP. ATB150, PRIOR REJECTIONS, AND THE FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``; configurations: ``$ordinal``",
   '- The center admits adaptive-trend entries only from server hour 16 through hour 0. The 12-1 and 16-9 windows are frozen wider neighbors.',
   '- The completed ATB150 ledger informed these hours, so this is historical cross-period validation rather than pristine out-of-sample evidence.',
   '- Strong reversion remains body 0.25 / requested risk 0.70%; every entry, initial stop, target, exit, lot cap, exposure cap, and loss limit is unchanged.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Strong-Reversion / ATB Session Model 1 Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Freeze disabled champion control, strong-reversion control, and ATB server-session windows 12-1, 16-1, and 16-9 before running reports.',
   '- Freeze completed-H1 body ratio 0.25, requested strong-reversion risk 0.70%, adaptive-trend risk 0.15%, and tick protection disabled.',
   '- Require the 16-1 center to beat both controls in every era; continuous net at least 10% above champion and 2% above strong control; CAGR at least 0.15 point above champion and 0.03 point above strong control; PF, recovery, and return/drawdown no worse than both controls; drawdown at most 1.25% and no more than 0.08 point above champion; and at least 380 continuous trades.',
   '- Require both wider neighbors to retain at least 99% of strong-control net in every era; continuous net at least 1% above strong control; CAGR at least 0.02 point above strong control; PF, recovery, and return/drawdown no worse than strong control; drawdown at most 1.25%; and at least 385 trades.',
   '- Reject a losing era, isolated center, identity mismatch, safety failure, or any result that needs a post-result hour adjustment. No further session-hour search follows a failure.',
   '- Keep exact-ticket ownership, broker-valued sizing, maximum-lot refusal, post-fill reconciliation, the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, and real-account lock unchanged.',
   '- No martingale, grid, averaging down, recovery sizing, funding change, forward-candidate change, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
