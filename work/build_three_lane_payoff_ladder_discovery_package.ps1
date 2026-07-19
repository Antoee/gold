[CmdletBinding()]
param(
   [string]$SourcePath = 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_payoff_ladder_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_PAYOFF_LADDER_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_PAYOFF_LADDER_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_PAYOFF_LADDER_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_PAYOFF_LADDER_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
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

& (Join-Path $PSScriptRoot 'test_three_lane_trade_ready_rc2_atb150_static_safety.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 178) { throw "Expected 178 ATB150 inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_payoff_ladder_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='tpl_control';MOTP='2.00';ATBTP='2.00'},
   [pscustomobject]@{Name='tpl_mo250';MOTP='2.50';ATBTP='2.00'},
   [pscustomobject]@{Name='tpl_mo300';MOTP='3.00';ATBTP='2.00'},
   [pscustomobject]@{Name='tpl_mo400';MOTP='4.00';ATBTP='2.00'},
   [pscustomobject]@{Name='tpl_atb250';MOTP='2.00';ATBTP='2.50'},
   [pscustomobject]@{Name='tpl_atb300';MOTP='2.00';ATBTP='3.00'},
   [pscustomobject]@{Name='tpl_atb400';MOTP='2.00';ATBTP='4.00'},
   [pscustomobject]@{Name='tpl_both250';MOTP='2.50';ATBTP='2.50'},
   [pscustomobject]@{Name='tpl_both300';MOTP='3.00';ATBTP='3.00'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='calibration_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Payoff discovery only. Require both disjoint eras positive, continuous CAGR at least 0.25 points above the exact 2R control, PF >= 1.60, DD <= 1.75%, return/DD and recovery no worse than control, and adjacent target support before any 2021+ check.'

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
   Set-FixedInput $inputs 'InpMOTakeProfitR' $variant.MOTP
   Set-FixedInput $inputs 'InpATBTakeProfitR' $variant.ATBTP
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Phase='payoff_discovery_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         MOTakeProfitR=$variant.MOTP;ATBTakeProfitR=$variant.ATBTP
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
   '# Three-Lane Payoff Ladder Discovery Package','',
   '**Status: PAYOFF DISCOVERY ONLY. THE ATB150 CHAMPION AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``",
   "- Configurations: ``$ordinal``",
   '- The control is exact ATB150 with both trend-lane targets at 2R.',
   '- Candidates change only momentum and/or adaptive-trend fixed target distance. Entries, stops, risk, channel exits, loss limits, and the 0.75% open-risk cap remain unchanged.',
   '- These dates have informed earlier portfolio research, so later checks are historical cross-period validation, not pristine out-of-sample evidence.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Three-Lane Payoff Ladder Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Keep every entry signal, initial stop, requested risk, lot cap, session, and account guard unchanged.',
   '- Change only the fixed take-profit distance for the two trend lanes; existing channel, momentum-failure, break-even, and time exits remain active.',
   '- Require a broad risk-normalized improvement rather than a larger target headline.',
   '- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.',
   '- Reject any profile with a losing broad era, weak PF, poor return/drawdown, identity mismatch, compiler warning, or safety failure.',
   '- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
