[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Tick_Protection_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_strong_signal_tick_protection_lock_ladder_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_LOCK_LADDER_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_LOCK_LADDER_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_LOCK_LADDER_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_TICK_PROTECTION_LOCK_LADDER_MODEL1_CONTRACT.md'
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
if($sourceHash -ne $expectedSourceHash) { throw "Strong-signal tick-protection source identity changed: $sourceHash" }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_strong_signal_tick_protection_lock_ladder_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvsstpll_control';Role='control';Strong='false';Protection='false';TriggerR='1.00';LockR='0.10'},
   [pscustomobject]@{Name='rvsstpll_strong_only';Role='strong_control';Strong='true';Protection='false';TriggerR='1.00';LockR='0.10'},
   [pscustomobject]@{Name='rvsstpll_lock010';Role='observed_reference';Strong='true';Protection='true';TriggerR='1.00';LockR='0.10'},
   [pscustomobject]@{Name='rvsstpll_lock015';Role='lower_neighbor';Strong='true';Protection='true';TriggerR='1.00';LockR='0.15'},
   [pscustomobject]@{Name='rvsstpll_lock020';Role='center';Strong='true';Protection='true';TriggerR='1.00';LockR='0.20'},
   [pscustomobject]@{Name='rvsstpll_lock025';Role='upper_neighbor';Strong='true';Protection='true';TriggerR='1.00';LockR='0.25'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$stopRule = 'Tick-protection lock ladder at fixed 1.00R trigger. Lock0.20 center must change trading metrics, keep every era >= disabled control, continuous net >= control +5% and >=97% of strong-only, CAGR >= control +0.10 points and >= strong-only -0.03 points, PF/recovery/return-DD >= strong-only, DD <= strong-only and <=1.25%, and >=400 trades. Lock0.15 and lock0.25 neighbors must change trading metrics and keep every era >= control, net >= control +3%, CAGR >= control +0.05 points, PF/recovery/return-DD >= control, DD <=1.25%, and >=400 trades. No post-result retuning.'

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
   Set-FixedInput $inputs 'InpRVUseStrongSignalProtection' $variant.Protection
   Set-FixedInput $inputs 'InpRVStrongSignalProtectionTriggerR' $variant.TriggerR
   Set-FixedInput $inputs 'InpRVStrongSignalProtectionLockR' $variant.LockR
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='reversion_strong_signal_tick_protection_lock_ladder_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         StrongSignalRiskEnabled=$variant.Strong;ProtectionEnabled=$variant.Protection;StrongSignalMinimumBodyRatio='0.25';StrongSignalRiskPercent='0.70';ProtectionTriggerR=$variant.TriggerR;ProtectionLockR=$variant.LockR
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
   '# Three-Lane Reversion Strong-Signal Tick Protection Lock Ladder Model 1 Package','',
   '**Status: PREREGISTERED CODE FOLLOW-UP. THE PRIOR REJECTIONS, ATB150 CHAMPION, AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``",
   "- Configurations: ``$ordinal``",
   '- This separately preregistered follow-up freezes body ratio 0.25, requested risk 0.70%, and the effective 1.00R trigger, then tests 0.15R, 0.20R, and 0.25R locks on every executable tick.',
   '- The package retains disabled and strong-only controls plus the already-observed 0.10R row for attribution; only the 0.15R/0.20R/0.25R ladder is eligible under this new contract.',
   '- Entries, initial stops, VWAP targets, trend lanes, lot cap, portfolio exposure cap, and every loss limit remain identical to the strong-signal branch.',
   '- These dates have informed earlier portfolio research, so later checks are historical cross-period validation, not pristine out-of-sample evidence.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Reversion Strong-Signal Tick Protection Lock Ladder Model 1 Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- This is a new data-informed settings follow-up and cannot amend or reverse any rejected strong-signal, break-even, or initial tick-protection contract.',
   '- Freeze completed-H1 directional body ratio at 0.25, requested strong risk at 0.70%, and protection trigger at 1.00R. Test only disabled control, strong-only control, observed 0.10R reference, and new lock values 0.15R, 0.20R, and 0.25R.',
   '- Use only completed signal-bar OHLC at entry, exact stored initial risk, and current executable bid/ask on every management tick. Never use future data, prior outcomes, drawdown, loss streaks, account profit, or calendar exclusions.',
   '- Never add to a position. Keep exact-ticket ownership, broker-valued sizing, maximum-lot refusal, exposure refusal, and post-fill reconciliation.',
   '- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.',
   '- Require the 0.20R center to change at least one trading metric, match or beat disabled control net in every era, produce continuous net at least 5% above disabled control and at least 97% of strong-only, keep CAGR at least 0.10 points above disabled control and no more than 0.03 points below strong-only, keep PF/recovery/return-drawdown no worse than strong-only, drawdown no worse than strong-only and at most 1.25%, and at least 400 continuous trades.',
   '- Require both 0.15R and 0.25R neighbors to change at least one trading metric, match or beat disabled control in every era, produce continuous net at least 3% above disabled control, CAGR at least 0.05 points above disabled control, PF/recovery/return-drawdown no worse than disabled control, drawdown at most 1.25%, and at least 400 trades.',
   '- Reject an isolated winner, losing era, identity mismatch, compiler warning, safety failure, or any candidate that qualifies by relaxing these gates after results.',
   '- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
