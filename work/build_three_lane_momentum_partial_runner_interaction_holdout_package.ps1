[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Momentum_Partial_Runner_Research.mq5',
   [string]$LeaderProfilePath = 'release\three-lane-momentum-same-side-exit-cooldown-provisional\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_PROVISIONAL.set',
   [string]$PackageDir = 'outputs\three_lane_momentum_partial_runner_interaction_holdout_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_PARTIAL_RUNNER_INTERACTION_HOLDOUT_MODEL1_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = '1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9'
$expectedLeaderHash = 'ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Convert-SourceDefault([string]$Type, [string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq 'string') { return $trimmed.Substring(1, $trimmed.Length - 2) }
   if($Type -eq 'ENUM_TIMEFRAMES') {
      $map = @{PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'}
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
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-output path: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

& (Join-Path $PSScriptRoot 'test_three_lane_momentum_partial_runner_source.ps1') | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$leader = (Resolve-Path -LiteralPath (Resolve-RepoPath $LeaderProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$leaderHash = (Get-FileHash -LiteralPath $leader -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Partial-runner source identity changed: $sourceHash" }
if($leaderHash -ne $expectedLeaderHash) { throw "Leader profile identity changed: $leaderHash" }

$base = Get-SourceInputs $source
if($base.Count -ne 190) { throw "Expected 190 source inputs, found $($base.Count)." }
$leaderCount = 0
foreach($line in Get-Content -LiteralPath $leader) {
   if($line -notmatch '^(Inp[^=]+)=(.*)$') { continue }
   $name = $Matches[1]
   if(!$base.Contains($name)) { throw "Leader input missing from source: $name" }
   $base[$name] = $line
   $leaderCount++
}
if($leaderCount -ne 185) { throw "Expected 185 leader inputs, found $leaderCount." }
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_momentum_partial_runner_interaction_holdout_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='mopri_control';Role='control';Enabled='false';Close='60';Trigger='2.00';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='mopri_close70';Role='training_component_close';Enabled='true';Close='70';Trigger='2.00';Target='4.00';Lock='1.25'},
   [pscustomobject]@{Name='mopri_target500';Role='training_component_target';Enabled='true';Close='60';Trigger='2.00';Target='5.00';Lock='1.25'},
   [pscustomobject]@{Name='mopri_combo';Role='interaction_center';Enabled='true';Close='70';Trigger='2.00';Target='5.00';Lock='1.25'}
)
$windows = @(
   [pscustomobject]@{Name='recent_2021_2023';From='2021.01.01';To='2023.12.31'},
   [pscustomobject]@{Name='latest_2024_2026';From='2024.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2021_2026';From='2021.01.01';To='2026.07.12'}
)
$stopRule = 'Frozen post-2020 interaction holdout after the pre-2021 center was rejected. The disabled control must reproduce prior era results and every row must be profitable. The 70%-close plus 5R interaction must retain >=95% of control net in both disjoint eras, improve continuous net >=5% and CAGR >=control +0.10 point, retain >=95% of control PF/recovery/return-DD, and keep DD <=min(1.50%, control +0.20 point). Partial activity must be confirmed. At least one individual training component must retain both-era floors and improve continuous net >=2% under the same quality/DD gates. Initial risk, entries, portfolio cap, and account protections remain fixed. No post-result rescue.'

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package 'configs'
$profileDir = Join-Path $package 'profiles'
$reportDir = Join-Path $package 'reports_here'
$sourceDir = Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$rows = [Collections.Generic.List[object]]::new()
$ordinal = 0
$candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Copy-Inputs $base
   Set-FixedInput $inputs 'InpMOUsePartialRunner' $variant.Enabled
   Set-FixedInput $inputs 'InpMOPartialClosePercent' $variant.Close
   Set-FixedInput $inputs 'InpMOPartialTriggerR' $variant.Trigger
   Set-FixedInput $inputs 'InpMOPartialTargetR' $variant.Target
   Set-FixedInput $inputs 'InpMOPartialStopLockR' $variant.Lock
   $profilePath = Join-Path $profileDir "$($variant.Name).set"
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows) {
      $ordinal++
      $configName = '{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name
      $configPath = Join-Path $configDir $configName
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $rows.Add([pscustomobject][ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         Phase='momentum_partial_runner_interaction_holdout_model1';Window=$window.Name
         From=$window.From;To=$window.To;Model=1;Deposit=10000
         PartialRunnerEnabled=$variant.Enabled;ClosePercent=$variant.Close;TriggerR=$variant.Trigger
         TargetR=$variant.Target;StopLockR=$variant.Lock
         ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName"
         SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"
         ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      }) | Out-Null
   }
}
$manifest = Resolve-RepoPath $ManifestPath
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@(
   '# Momentum Partial-Runner Interaction Holdout Contract','',
   '**Status: PREREGISTERED POST-2020 HOLDOUT. THE REJECTED DISCOVERY, PUBLISHED LEADER, AND FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Source SHA-256: ``$sourceHash``", "- Leader profile SHA-256: ``$leaderHash``", "- Manifest SHA-256: ``$manifestHash``", '',
   '- Frozen interaction center: split-capable momentum positions bank 70% at +2.00R, first lock the remainder at +1.25R, and target +5.00R. Broker-volume normalization applies; unsplittable positions keep the original +2.00R exit.',
   '- Fixed comparators are the disabled control and the two independently positive pre-2021 training components: 70% close at 4R and 60% close at 5R.',
   '- Partial exits are aggregated by position for lane and portfolio consecutive-loss controls; a profitable scale-out cannot hide a losing remainder.',
   "- $stopRule",
   '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, capital change, forward substitution, or real-account trading.'
) | Set-Content -LiteralPath (Join-Path $package 'DISCOVERY_CONTRACT.md') -Encoding ASCII
[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;LeaderProfileSha256=$leaderHash;ManifestSha256=$manifestHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
