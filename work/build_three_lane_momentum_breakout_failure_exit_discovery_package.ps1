[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Momentum_Breakout_Failure_Exit_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_momentum_breakout_failure_exit_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'CBC2309B98AE3EC4969E52B4ADBD5E8A4EFCE8780E0654F5F9B1E9A36AD25EE4'
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

& (Join-Path $PSScriptRoot 'test_three_lane_momentum_breakout_failure_exit_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 181) { throw "Expected 181 configurable research inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_momentum_breakout_failure_exit_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='mobfe_control';Role='control';Enabled='false';Bars='3';Buffer='0.05'},
   [pscustomobject]@{Name='mobfe_bars2';Role='lower_time';Enabled='true';Bars='2';Buffer='0.05'},
   [pscustomobject]@{Name='mobfe_center';Role='center';Enabled='true';Bars='3';Buffer='0.05'},
   [pscustomobject]@{Name='mobfe_bars4';Role='upper_time';Enabled='true';Bars='4';Buffer='0.05'},
   [pscustomobject]@{Name='mobfe_buffer000';Role='lower_buffer';Enabled='true';Bars='3';Buffer='0.00'},
   [pscustomobject]@{Name='mobfe_buffer010';Role='upper_buffer';Enabled='true';Bars='3';Buffer='0.10'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='later_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Pre-2021 breakout-failure-exit discovery only. Every report must be profitable. Center must be no worse than control in both disjoint eras; continuous net >= control +5%, CAGR >= control +0.08 point, PF/recovery/return-DD >= control, DD <=1.20% and <=control +0.08 point, trades >= control, and behavior changed. Each time/buffer neighbor must be no worse than control in both eras; continuous net >=control +2%, CAGR >=control +0.03 point, PF/recovery/return-DD >=control, DD <=1.25%, and behavior changed. No post-result retuning.'

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
   Set-FixedInput $inputs 'InpMOUseBreakoutFailureExit' $variant.Enabled
   Set-FixedInput $inputs 'InpMOBreakoutFailureMaximumBars' $variant.Bars
   Set-FixedInput $inputs 'InpMOBreakoutFailureBufferATR' $variant.Buffer
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows) {
      $ordinal++
      $configName = '{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name
      $configPath = Join-Path $configDir $configName
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $configHash = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
      $common = [ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         Phase='three_lane_momentum_breakout_failure_exit_discovery_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         BreakoutFailureExitEnabled=$variant.Enabled;MaximumBars=$variant.Bars;BufferATR=$variant.Buffer
         ExpectedReportName=$reportName;ConfigSha256=$configHash;ProfileSha256=$profileHash
         SourceSha256=$sourceHash;StopRule=$stopRule
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
   '# Three-Lane Momentum Breakout-Failure Exit Discovery Package','',
   '**Status: PREREGISTERED 2015-2020 DISCOVERY. THE ATB150 CHAMPION AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``; configurations: ``$ordinal``",
   '- The center exits a momentum position when one of the first three completed H1 closes returns beyond the stored pre-break channel by 0.05 entry ATR.',
   '- Frozen timing neighbors use two and four completed bars. Frozen buffer neighbors use 0.00 and 0.10 entry ATR.',
   '- Entries, initial stops, targets, requested risk, position limits, account protections, and all other champion settings remain exact.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Momentum Breakout-Failure Exit Discovery Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Use only the frozen disabled control, center (3 bars/0.05 ATR), timing neighbors (2 and 4 bars), and buffer neighbors (0.00 and 0.10 ATR).',
   '- Require every report to remain profitable. Require the center to be no worse than control in both disjoint eras; continuous net at least 5% above control; CAGR at least 0.08 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.20% and no more than 0.08 point above control; trades at least control; and changed behavior.',
   '- Require every neighbor to be no worse than control in both disjoint eras; continuous net at least 2% above control; CAGR at least 0.03 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.25%; and changed behavior.',
   '- Reject a losing window, inactive feature, isolated center, identity mismatch, compiler warning, safety failure, or any result needing post-result timing or buffer adjustment. Only the exact center may open a separately frozen 2021-2026 holdout.',
   '- Exit decisions use completed H1 bars, exact-ticket ownership, the stored pre-break channel, and entry ATR. The exit cannot add risk or widen protection.',
   '- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, period loss limits, lot refusal, post-fill reconciliation, and real-account lock unchanged.',
   '- No martingale, grid, averaging down, recovery sizing, funding change, forward-candidate change, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
