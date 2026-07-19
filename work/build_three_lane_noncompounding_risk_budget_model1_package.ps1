[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Noncompounding_Risk_Budget_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_noncompounding_risk_budget_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_NONCOMPOUNDING_RISK_BUDGET_MODEL1_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'B72F61E0633F5A57C3BC4D5688C8F7F29155B772F7D2BDE3EDC72429A41E9EA8'
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

& (Join-Path $PSScriptRoot 'test_three_lane_noncompounding_risk_budget_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 182) { throw "Expected 182 research inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_noncompounding_risk_budget_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='ncrb_control';Strong='false';Budget='false'},
   [pscustomobject]@{Name='ncrb_budget_only';Strong='false';Budget='true'},
   [pscustomobject]@{Name='ncrb_strong_dynamic';Strong='true';Budget='false'},
   [pscustomobject]@{Name='ncrb_strong_noncomp';Strong='true';Budget='true'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$stopRule = 'Fixed noncompounding risk-budget Model1 gate. Require all windows positive; strong+budget net >= control in every era; continuous net >= control +5%; CAGR >= control +0.08 points; PF >= control; DD <= 1.25% and <= control +0.05 points; recovery and return/DD >= control; at least 400 trades. No parameter search or post-result retuning.'

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
   Set-FixedInput $inputs 'InpUseNoncompoundingRiskBudget' $variant.Budget
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Phase='noncompounding_risk_budget_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         StrongSignalRiskEnabled=$variant.Strong;NoncompoundingRiskBudgetEnabled=$variant.Budget
         StrongSignalMinimumBodyRatio='0.25';StrongSignalRiskPercent='0.70'
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
   '# Three-Lane Noncompounding Risk-Budget Model 1 Package','',
   '**Status: FROZEN HISTORICAL RESEARCH. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``",
   "- Configurations: ``$ordinal``",
   '- The feature changes only the capital base used by existing broker-valued lot sizing.',
   '- When enabled, sizing capital is min(current equity, frozen initial capital); losses reduce size and profits cannot increase it.',
   '- The four-way design separates the budget effect from the already-rejected strong-risk effect.',
   '- These periods informed earlier research and are historical cross-period validation, not pristine out-of-sample evidence.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Three-Lane Noncompounding Risk-Budget Model 1 Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Test exactly four fixed profiles: champion control, budget only, strong risk only, and strong risk plus budget.',
   '- Freeze strong-signal body ratio at 0.25 and requested risk at 0.70%; do not add another threshold or risk rung.',
   '- The budget may only replace sizing equity with min(current equity, expected initial balance). It may never increase risk after profit or loss.',
   '- Keep signals, entries, initial stops, targets, exits, lot caps, exact-ticket ownership, minimum-lot refusal, post-fill reconciliation, and all account-wide limits unchanged.',
   '- Require every profile/window profitable and strong+budget net no lower than control in any disjoint era.',
   '- Require strong+budget continuous net at least 5% above control, CAGR at least 0.08 points above control, PF no lower than control, DD at most 1.25% and no more than 0.05 points above control, recovery and return/drawdown no lower than control, and at least 400 trades.',
   '- Only a full Model 1 pass may open the same fixed profiles on Model 4 real ticks.',
   '- Reject identity mismatch, compiler warning, missing report, losing era, isolated growth, or any post-result retuning.',
   '- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
