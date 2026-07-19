[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Protected_Winner_AddOn_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_protected_winner_addon_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46'
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
      $type = $Matches[1]; $name = $Matches[2]; $value = Convert-SourceDefault $type $Matches[3]
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

& (Join-Path $PSScriptRoot 'test_three_lane_protected_winner_addon_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 187) { throw "Expected 187 research inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_protected_winner_addon_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='pwa_control';Enabled='false';MaxPositions='3';Trigger='1.25';Lookback='6';RiskMultiplier='0.50';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_center';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='6';RiskMultiplier='0.50';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_lookback4';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='4';RiskMultiplier='0.50';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_lookback8';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='8';RiskMultiplier='0.50';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_trigger100';Enabled='true';MaxPositions='4';Trigger='1.00';Lookback='6';RiskMultiplier='0.50';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_trigger150';Enabled='true';MaxPositions='4';Trigger='1.50';Lookback='6';RiskMultiplier='0.50';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_risk025';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='6';RiskMultiplier='0.25';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_risk060';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='6';RiskMultiplier='0.60';LockR='0.75';Coverage='1.25'},
   [pscustomobject]@{Name='pwa_coverage100';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='6';RiskMultiplier='0.50';LockR='0.75';Coverage='1.00'},
   [pscustomobject]@{Name='pwa_coverage150';Enabled='true';MaxPositions='4';Trigger='1.25';Lookback='6';RiskMultiplier='0.50';LockR='0.75';Coverage='1.50'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Discovery only: no post-2020 data. Require both disjoint eras positive, continuous net and return/DD improvement versus exact disabled-feature control, PF at least 1.50, DD at most 2%, add-on activity, and adjacent parameter support before any holdout.'

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
   Set-FixedInput $inputs 'InpMOUseProtectedWinnerAddOn' $variant.Enabled
   Set-FixedInput $inputs 'InpMaximumAccountPositions' $variant.MaxPositions
   Set-FixedInput $inputs 'InpMOAddOnMinimumProfitR' $variant.Trigger
   Set-FixedInput $inputs 'InpMOAddOnMinimumHoldBars' '4'
   Set-FixedInput $inputs 'InpMOAddOnBreakoutLookbackBars' $variant.Lookback
   Set-FixedInput $inputs 'InpMOAddOnBreakoutBufferATR' '0.00'
   Set-FixedInput $inputs 'InpMOAddOnRiskMultiplier' $variant.RiskMultiplier
   Set-FixedInput $inputs 'InpMOAddOnPrimaryLockR' $variant.LockR
   Set-FixedInput $inputs 'InpMOAddOnLockedProfitCoverage' $variant.Coverage
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows) {
      $ordinal++
      $configName = '{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      $configPath = Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $common = [ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Phase='discovery_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         Enabled=$variant.Enabled;MaximumAccountPositions=$variant.MaxPositions;MinimumProfitR=$variant.Trigger
         BreakoutLookbackBars=$variant.Lookback;RiskMultiplier=$variant.RiskMultiplier;PrimaryLockR=$variant.LockR
         LockedProfitCoverage=$variant.Coverage;ExpectedReportName=$reportName;ProfileSha256=$profileHash
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
$packageLines = @(
   '# Three-Lane Protected Winner Add-On Discovery Package','',
   '**Status: SEALED MODEL 1 DISCOVERY. NO POST-2020 DATA.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``",
   "- Configurations: ``$ordinal``",
   '- The control is the exact ATB150 profile with the feature disabled and its original three-position cap.',
   '- Add-on variants permit at most one separately owned momentum add-on and four account positions, while the 0.75% account-wide open-risk cap remains unchanged.',
   '- Selection cannot inspect 2021-2026. Any holdout or real-tick run requires a documented discovery pass.'
)
$packageLines | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
$contractLines = @(
   '# Protected Momentum Winner Add-On Contract','',
   '**Status: RESEARCH ONLY. ATB150 AND THE FROZEN FORWARD CANDIDATE ARE UNCHANGED.**','',
   '- Never add to a losing or unprotected position.',
   '- Require exactly one primary momentum position and zero existing add-ons.',
   '- Require same-direction fresh H1 continuation plus unchanged D1 momentum agreement.',
   '- Move the primary stop into profit before entry and require broker-valued locked profit to cover the add-on risk by the configured multiple.',
   '- Use broker-aware risk sizing with minimum-lot refusal, a unique magic number, post-fill reconciliation, and the unchanged 0.75% portfolio open-risk cap.',
   '- Permit one add-on maximum. No martingale, grid, averaging down, recovery sizing, or real-account trading.',
   '- Reject on a losing discovery era, weak return/drawdown, missing adjacent support, identity mismatch, compiler warning, or safety violation.'
)
$contractLines | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
