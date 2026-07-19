[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Risk_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_strict_body_risk_ladder_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_REVERSION_STRICT_BODY_RISK_LADDER_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_STRICT_BODY_RISK_LADDER_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_REVERSION_STRICT_BODY_RISK_LADDER_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_STRICT_BODY_RISK_LADDER_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = '36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF'
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

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_strong_signal_risk_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Strong-signal risk source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 181) { throw "Expected 181 research inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_strict_body_risk_ladder_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvsrl_control';Enabled='false';BodyRatio='0.25';StrongRisk='0.60'},
   [pscustomobject]@{Name='rvsrl_b250_r060';Enabled='true';BodyRatio='0.25';StrongRisk='0.60'},
   [pscustomobject]@{Name='rvsrl_b250_r0625';Enabled='true';BodyRatio='0.25';StrongRisk='0.625'},
   [pscustomobject]@{Name='rvsrl_b250_r065';Enabled='true';BodyRatio='0.25';StrongRisk='0.65'},
   [pscustomobject]@{Name='rvsrl_b250_r0675';Enabled='true';BodyRatio='0.25';StrongRisk='0.675'},
   [pscustomobject]@{Name='rvsrl_b250_r070';Enabled='true';BodyRatio='0.25';StrongRisk='0.70'},
   [pscustomobject]@{Name='rvsrl_b225_r065';Enabled='true';BodyRatio='0.225';StrongRisk='0.65'},
   [pscustomobject]@{Name='rvsrl_b275_r065';Enabled='true';BodyRatio='0.275';StrongRisk='0.65'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$stopRule = 'Strict-body reversion risk ladder. Require every era positive; continuous CAGR >= control + 0.15 points; PF >= 1.87; DD <= 1.35%; recovery and return/DD >= control; at least 400 trades; no era worse than control by more than $10; two adjacent risk rows and one adjacent body row meeting the frozen support floor before Model4.'

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
   Set-FixedInput $inputs 'InpRVUseStrongSignalRisk' $variant.Enabled
   Set-FixedInput $inputs 'InpRVStrongSignalMinimumBodyRatio' $variant.BodyRatio
   Set-FixedInput $inputs 'InpRVStrongSignalRiskPercent' $variant.StrongRisk
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Phase='reversion_strict_body_risk_ladder_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         Enabled=$variant.Enabled;StrongSignalMinimumBodyRatio=$variant.BodyRatio;StrongSignalRiskPercent=$variant.StrongRisk
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
   '# Three-Lane Reversion Strict-Body Risk Ladder Package','',
   '**Status: DATA-INFORMED FOLLOW-UP. THE PRIOR DISCOVERY REJECTION, ATB150 CHAMPION, AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``",
   "- Configurations: ``$ordinal``",
   '- This separately preregistered follow-up tests only the prior rejected discovery family''s efficient 0.25 body threshold across a narrow risk ladder plus two body neighbors.',
   '- The optional allocator may raise requested reversion risk only when the already-valid completed H1 signal candle meets the frozen directional-body ratio.',
   '- Entries, initial stops, VWAP targets, trend lanes, lot cap, portfolio exposure cap, and every loss limit remain identical to ATB150.',
   '- These dates have informed earlier portfolio research, so later checks are historical cross-period validation, not pristine out-of-sample evidence.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Reversion Strict-Body Risk Ladder Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- This is a new data-informed follow-up and cannot amend or reverse the rejected broad strong-signal discovery contract.',
   '- Change only the requested risk of an already-valid reversion entry when the completed H1 directional body ratio meets a frozen threshold; keep entry eligibility, initial stops, VWAP targets, exits, and both trend lanes unchanged.',
   '- Use only completed signal-bar OHLC data. Never use current-bar data, future data, prior outcomes, drawdown, loss streaks, account profit, or calendar exclusions to qualify stronger risk.',
   '- Never add to a position. Keep exact-ticket ownership, broker-valued sizing, maximum-lot refusal, exposure refusal, and post-fill reconciliation.',
   '- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.',
   '- Require every disjoint era profitable, continuous CAGR at least 0.15 points above control, PF at least 1.87, drawdown at most 1.35%, recovery and return/drawdown no worse than control, and at least 400 continuous trades.',
   '- Reject if any era trails control by more than $10. Require two adjacent risk rows and at least one adjacent body row to reach CAGR at least control + 0.10 points, PF at least 1.85, drawdown at most 1.35%, and both efficiency measures at least 95% of control.',
   '- Reject an isolated winner, losing era, identity mismatch, compiler warning, safety failure, or any candidate that qualifies by relaxing these gates after results.',
   '- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
