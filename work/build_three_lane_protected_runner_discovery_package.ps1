[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Protected_Runner_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_protected_runner_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_PROTECTED_RUNNER_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_PROTECTED_RUNNER_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_PROTECTED_RUNNER_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_PROTECTED_RUNNER_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = '654EEA6299C1D2ABC1F9ACB09F66C41839ABD2EDD6BFD93607A51B043BF26035'
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

& (Join-Path $PSScriptRoot 'test_three_lane_protected_runner_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 186) { throw "Expected 186 protected-runner inputs, found $($base.Count)." }
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
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_protected_runner_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='pr_control';MO='false';ATB='false';Target='4.00';Trigger='1.50';Lock='0.75'},
   [pscustomobject]@{Name='pr_mo_center';MO='true';ATB='false';Target='4.00';Trigger='1.50';Lock='0.75'},
   [pscustomobject]@{Name='pr_mo_lock050';MO='true';ATB='false';Target='4.00';Trigger='1.50';Lock='0.50'},
   [pscustomobject]@{Name='pr_mo_lock100';MO='true';ATB='false';Target='4.00';Trigger='1.50';Lock='1.00'},
   [pscustomobject]@{Name='pr_mo_target300';MO='true';ATB='false';Target='3.00';Trigger='1.50';Lock='0.75'},
   [pscustomobject]@{Name='pr_mo_trigger125';MO='true';ATB='false';Target='4.00';Trigger='1.25';Lock='0.50'},
   [pscustomobject]@{Name='pr_mo_trigger175';MO='true';ATB='false';Target='4.00';Trigger='1.75';Lock='0.75'},
   [pscustomobject]@{Name='pr_atb_center';MO='false';ATB='true';Target='4.00';Trigger='1.50';Lock='0.75'},
   [pscustomobject]@{Name='pr_atb_lock050';MO='false';ATB='true';Target='4.00';Trigger='1.50';Lock='0.50'},
   [pscustomobject]@{Name='pr_atb_lock100';MO='false';ATB='true';Target='4.00';Trigger='1.50';Lock='1.00'},
   [pscustomobject]@{Name='pr_both_center';MO='true';ATB='true';Target='4.00';Trigger='1.50';Lock='0.75'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='calibration_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Protected-runner discovery only. Require both disjoint eras positive, continuous CAGR at least 0.15 points above exact disabled control, PF >= 1.65, DD <= 1.25%, recovery and return/DD no worse than control, and at least two adjacent settings preserving the qualitative gain before any 2021+ or Model4 check.'

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
   foreach($lane in @('MO','ATB')) {
      Set-FixedInput $inputs "Inp${lane}UseProtectedRunner" $variant.$lane
      Set-FixedInput $inputs "Inp${lane}RunnerTakeProfitR" $variant.Target
      Set-FixedInput $inputs "Inp${lane}RunnerLockTriggerR" $variant.Trigger
      Set-FixedInput $inputs "Inp${lane}RunnerLockR" $variant.Lock
   }
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
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Phase='protected_runner_discovery_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         MomentumRunner=$variant.MO;AdaptiveRunner=$variant.ATB;RunnerTakeProfitR=$variant.Target
         RunnerLockTriggerR=$variant.Trigger;RunnerLockR=$variant.Lock
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
   '# Three-Lane Protected Runner Discovery Package','',
   '**Status: DISCOVERY ONLY. THE ATB150 CHAMPION AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``",
   "- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``",
   "- Configurations: ``$ordinal``",
   '- The control reproduces ATB150 with both runner features disabled.',
   '- A runner widens the fixed target and adds a second tightening-only stop milestone after favorable movement. Entry signals, initial stops, requested risk, position limits, and account protections do not change.',
   '- These dates have informed earlier portfolio research, so later checks are historical cross-period validation, not pristine out-of-sample evidence.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Three-Lane Protected Runner Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Keep all entry signals, initial stops, requested risk, lot caps, sessions, and account guards unchanged.',
   '- A runner may widen only the fixed take-profit and may only tighten its protective stop after favorable price movement.',
   '- Require the lock level to remain below its trigger and the target to remain above its trigger.',
   '- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, period loss limits, post-fill reconciliation, and minimum-lot refusal unchanged.',
   '- Reject any profile with a losing broad era, weak PF, poorer risk efficiency, identity mismatch, compiler warning, or safety failure.',
   '- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
