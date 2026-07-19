[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Residual_Risk_Eligible_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_residual_risk_v2_model4_characterization_package',
   [string]$QueuePath = 'outputs\THREE_LANE_RESIDUAL_RISK_V2_MODEL4_CHARACTERIZATION_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_RESIDUAL_RISK_V2_MODEL4_CHARACTERIZATION_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_RESIDUAL_RISK_V2_MODEL4_CHARACTERIZATION_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_RESIDUAL_RISK_V2_MODEL4_CHARACTERIZATION_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'D468B984972E84FE2F0E368035EB74841D8B1856AEA56A893FB819DFE4C482E4'
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

& (Join-Path $PSScriptRoot 'test_three_lane_residual_risk_eligible_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 183) { throw "Expected 183 research inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_residual_risk_v2_model4_characterization' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rr2c_control';Enabled='false';MOMax='0.150';ATBMax='0.15'},
   [pscustomobject]@{Name='rr2c_mo170';Enabled='true';MOMax='0.170';ATBMax='0.30'},
   [pscustomobject]@{Name='rr2c_center';Enabled='true';MOMax='0.175';ATBMax='0.30'},
   [pscustomobject]@{Name='rr2c_mo180';Enabled='true';MOMax='0.180';ATBMax='0.30'}
)
$from = '2015.01.01'
$to = '2026.07.12'
$stopRule = 'Characterization only. Permit broad Model4 eras only if the center improves CAGR by at least 0.25 points versus exact disabled control, PF >= 1.60, DD <= 2.25%, recovery and return/DD each >= 95% of control, and the 0.170 and 0.180 neighbors do not collapse. This run cannot promote or alter the forward candidate.'

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
foreach($variant in $variants) {
   $ordinal++
   $inputs = Copy-Inputs $base
   Set-FixedInput $inputs 'InpUseResidualRiskAllocation' $variant.Enabled
   Set-FixedInput $inputs 'InpResidualRiskReservePercent' '0.05'
   Set-FixedInput $inputs 'InpRVMaximumEntryRiskPercent' '0.45'
   Set-FixedInput $inputs 'InpMOMaximumEntryRiskPercent' $variant.MOMax
   Set-FixedInput $inputs 'InpATBMaximumEntryRiskPercent' $variant.ATBMax
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   $configName = '{0:000}_{1}_continuous_2015_2026_m4.ini' -f $ordinal,$variant.Name
   $reportName = "$($variant.Name)_continuous_2015_2026_m4"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
      -From $from -To $to -Inputs $inputs -Model 4 -Deposit 10000 -Period 15
   $common = [ordered]@{
      QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$ordinal;Phase='residual_risk_v2_model4_characterization'
      Window='continuous_2015_2026';From=$from;To=$to;Model=4;Deposit=10000
      Enabled=$variant.Enabled;ReservePercent='0.05';RVMaximumEntryRiskPercent='0.45'
      MOMaximumEntryRiskPercent=$variant.MOMax;ATBMaximumEntryRiskPercent=$variant.ATBMax
      ExpectedReportName=$reportName;ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
   }
   $queueRows.Add([pscustomobject]($common + [ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"})) | Out-Null
   $runRows.Add([pscustomobject]($common + [ordered]@{
      PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
      ReportDestination="$PackageDir\reports_here\$reportName"
   })) | Out-Null
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Residual-Risk V2 Model4 Characterization Package','',
   '**Status: HISTORICAL CHARACTERIZATION ONLY. NO PROMOTION OR FORWARD CHANGE IS AUTHORIZED.**','',
   "- Source SHA-256: ``$sourceHash``",
   "- Champion profile SHA-256: ``$championHash``",
   '- Model: `4` real ticks',
   '- Account: `$10,000`',
   '- Window: 2015-01-01 through 2026-07-12',
   '- Profiles: exact disabled control, momentum ceilings 0.170/0.175/0.180 with adaptive ceiling 0.30.',
   '- Every expanded entry must first be tradable at the original ATB150 base-lane risk. No minimum-lot-only signal can be admitted.',
   '- These dates are historically informed and are not pristine out-of-sample evidence.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Residual-Risk V2 Model4 Characterization Contract','',
   '**Status: RESEARCH ONLY. THE PRIOR V2 REJECTION REMAINS IN FORCE.**','',
   '- Characterize the frozen center and immediate lower/upper momentum ceilings under real ticks without changing source or thresholds.',
   '- Keep entry/exit signals, initial stops, minimum-lot refusal, post-fill reconciliation, 0.75% open-risk cap, period loss limits, and real-account lock unchanged.',
   '- Open broad Model4 eras only if center CAGR improves by at least 0.25 percentage points, PF is at least 1.60, drawdown is at most 2.25%, recovery and return/drawdown retain at least 95% of control, and adjacent profiles do not collapse.',
   '- A characterization pass permits more testing only. It does not override the prior neighborhood rejection, prove forward performance, or authorize real trading.',
   '- No martingale, grid, averaging down, recovery sizing, funding changes, or forward-candidate changes.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Configurations=$ordinal;Model=4;Inputs=$base.Count;PackageDir=$PackageDir
}
