[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Reversion_Protected_Winner_AddOn_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_protected_winner_addon_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_PROTECTED_WINNER_ADDON_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = '1C28EC85646409F3C82E584AD2DA66E6A4FA936CEFAE142D09846694E5369FE2'
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

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_protected_winner_addon_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 191) { throw "Expected 191 research inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_protected_winner_addon_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvpwa_control';Role='control';Enabled='false';Trigger='1.00';Lock='0.50';Risk='0.15'},
   [pscustomobject]@{Name='rvpwa_trigger075';Role='lower_trigger';Enabled='true';Trigger='0.75';Lock='0.40';Risk='0.15'},
   [pscustomobject]@{Name='rvpwa_center';Role='center';Enabled='true';Trigger='1.00';Lock='0.50';Risk='0.15'},
   [pscustomobject]@{Name='rvpwa_trigger125';Role='upper_trigger';Enabled='true';Trigger='1.25';Lock='0.75';Risk='0.15'},
   [pscustomobject]@{Name='rvpwa_risk010';Role='lower_risk';Enabled='true';Trigger='1.00';Lock='0.50';Risk='0.10'},
   [pscustomobject]@{Name='rvpwa_risk020';Role='upper_risk';Enabled='true';Trigger='1.00';Lock='0.50';Risk='0.20'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='later_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Protected strong-reversion winner add-on discovery only through 2020. Center must keep both disjoint eras positive and >= control; continuous net >= control +3%, CAGR >= control +0.05 point, PF/recovery/return-DD >= control, DD <=1.25% and <=control +0.08 point, and >=3 completed add-ons. Trigger and risk neighbors must each remain positive in both eras, produce continuous net >=control +1%, CAGR >=control +0.02 point, PF/recovery/return-DD >=control, DD <=1.25%, and >=2 add-ons. No post-result retuning.'

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
   Set-FixedInput $inputs 'InpRVUseStrongSignalRisk' 'true'
   Set-FixedInput $inputs 'InpRVStrongSignalMinimumBodyRatio' '0.25'
   Set-FixedInput $inputs 'InpRVStrongSignalRiskPercent' '0.70'
   Set-FixedInput $inputs 'InpRVUseStrongSignalProtection' 'false'
   Set-FixedInput $inputs 'InpATBRiskPercent' '0.15'
   Set-FixedInput $inputs 'InpMaximumAccountPositions' $(if($variant.Enabled -eq 'true'){'4'}else{'3'})
   Set-FixedInput $inputs 'InpRVUseProtectedWinnerAddOn' $variant.Enabled
   Set-FixedInput $inputs 'InpRVAddOnTriggerR' $variant.Trigger
   Set-FixedInput $inputs 'InpRVAddOnPrimaryLockR' $variant.Lock
   Set-FixedInput $inputs 'InpRVAddOnRiskPercent' $variant.Risk
   Set-FixedInput $inputs 'InpRVAddOnLockedProfitCoverage' '1.25'
   Set-FixedInput $inputs 'InpRVAddOnMinimumRemainingRR' '1.20'
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase='three_lane_reversion_protected_winner_addon_discovery_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         StrongSignalRiskEnabled='true';StrongSignalMinimumBodyRatio='0.25';StrongSignalRiskPercent='0.70';AdaptiveTrendRiskPercent='0.15'
         AddOnEnabled=$variant.Enabled;AddOnTriggerR=$variant.Trigger;AddOnPrimaryLockR=$variant.Lock;AddOnRiskPercent=$variant.Risk
         AddOnLockedProfitCoverage='1.25';AddOnMinimumRemainingRR='1.20'
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
   '# Three-Lane Reversion Protected Winner Add-On Discovery Package','',
   '**Status: PREREGISTERED 2015-2020 DISCOVERY. ATB150 AND THE FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``; configurations: ``$ordinal``",
   '- The center adds at 1.00R, locks the primary at 0.50R, requests 0.15% add-on risk, requires 1.25x locked-profit coverage, and requires at least 1.20 remaining reward/risk to the original VWAP target.',
   '- Frozen trigger neighbors are 0.75R/0.40R and 1.25R/0.75R. Frozen add-on-risk neighbors are 0.10% and 0.20%.',
   '- The completed ATB150 reversion ledger informed this mechanism. Only 2015-2020 is open for feature discovery; 2021-2026 remains closed until a complete frozen discovery gate passes.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Reversion Protected Winner Add-On Discovery Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Freeze one disabled-feature strong-reversion control, center trigger/lock/risk at 1.00R/0.50R/0.15%, trigger neighbors 0.75R/0.40R and 1.25R/0.75R, and risk neighbors 0.10% and 0.20%.',
   '- Require the center to remain positive and no worse than control in both 2015-2018 and 2019-2020; continuous net at least 3% above control; CAGR at least 0.05 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.25% and no more than 0.08 point above control; and at least three completed add-ons.',
   '- Require every trigger and risk neighbor to remain positive in both eras; continuous net at least 1% above control; CAGR at least 0.02 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.25%; and at least two completed add-ons.',
   '- Reject zero activity, a losing era, an isolated center, identity mismatch, safety failure, or any result needing post-result trigger, lock, risk, coverage, or reward adjustment. Only the exact center may open a separately frozen 2021-2026 holdout.',
   '- The add-on is strong-signal-only and winner-only. Lock the primary stop first; require broker-valued locked profit to cover add-on risk; keep the original VWAP target; permit one persistent attempt and one add-on maximum.',
   '- Keep exact-ticket ownership, broker-valued sizing, maximum-lot refusal, hypothetical exposure precheck, post-fill reconciliation, the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, and real-account lock unchanged.',
   '- No martingale, grid, averaging down, recovery sizing, funding change, forward-candidate change, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
