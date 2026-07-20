[CmdletBinding()]
param(
   [string]$SourcePath = 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_lot_cap_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_CONTRACT.md'
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
function Get-ProfileInputs([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^(Inp[^=]+)=(.*)$') { continue }
      $name = $Matches[1]
      if($inputs.Contains($name)) { throw "Duplicate profile input: $name" }
      $inputs[$name] = $line
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

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash = (Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Champion source identity changed: $sourceHash" }
if($championHash -ne $expectedChampionHash) { throw "Champion profile identity changed: $championHash" }

$base = Get-ProfileInputs $championProfile
if($base.Count -ne 178) { throw "Expected 178 champion inputs, found $($base.Count)." }
$sourceInputNames = @(Get-Content -LiteralPath $source | ForEach-Object {
   if($_ -match '^\s*input\s+(?!group\b)[A-Za-z_][A-Za-z0-9_]*\s+(Inp[A-Za-z0-9_]+)\s*=') { $Matches[1] }
})
if($sourceInputNames.Count -ne 178 -or @($sourceInputNames | Where-Object { !$base.Contains($_) }).Count -ne 0) {
   throw 'Champion source/profile input topology changed.'
}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_lot_cap_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'

$variants = @(
   [pscustomobject]@{Name='rvlc_control';Role='control';LotCap='0.10'},
   [pscustomobject]@{Name='rvlc_low012';Role='lower_neighbor';LotCap='0.12'},
   [pscustomobject]@{Name='rvlc_center015';Role='center';LotCap='0.15'},
   [pscustomobject]@{Name='rvlc_high018';Role='upper_neighbor';LotCap='0.18'},
   [pscustomobject]@{Name='rvlc_stress020';Role='upper_stress';LotCap='0.20'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='later_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule = 'Pre-2021 reversion lot-cap discovery only. Every report must be profitable. Center 0.15 must be no worse than control in both disjoint eras; continuous net >=control +6%, CAGR >=control +0.10 point, PF/recovery/return-DD >=95% of control, DD <=1.35% and <=control +0.20 point, trades >=control -2, and behavior changed. Both 0.12/0.18 neighbors must be no worse than control in both eras; continuous net >=control +3%, CAGR >=control +0.05 point, PF/recovery/return-DD >=93% of control, DD <=1.35%, and behavior changed. The 0.20 stress row must stay profitable with recovery/return-DD >=85% of control and DD <=1.50%. No post-result cap change.'

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
   Set-FixedInput $inputs 'InpRVMaximumPositionLots' $variant.LotCap
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
         Phase='three_lane_reversion_lot_cap_discovery_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         ReversionRiskPercent='0.45';ReversionMaximumPositionLots=$variant.LotCap
         MaximumPortfolioOpenRiskPercent='0.75';ExpectedInitialBalance='10000'
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
   '# Three-Lane Reversion Lot-Cap Discovery Package','',
   '**Status: PREREGISTERED 2015-2020 DISCOVERY. ATB150 AND THE FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Exact ATB150 source SHA-256: ``$sourceHash``",
   "- Frozen ATB150 profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``; configurations: ``$ordinal``",
   '- The only trading input changed is reversion maximum position lots: 0.10 control, 0.12 lower, 0.15 center, 0.18 upper, and 0.20 stress.',
   '- Reversion requested risk remains 0.45%; portfolio open-risk cap remains 0.75%; all stop, entry, exit, and loss-limit logic remains exact ATB150.'
) | Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Three-Lane Reversion Lot-Cap Discovery Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Freeze exact ATB150 source/profile identity and the 0.10 / 0.12 / 0.15 / 0.18 / 0.20 lot-cap ladder before testing.',
   '- The 0.15 center must be no worse than control in both disjoint eras; improve continuous net by at least 6% and CAGR by at least 0.10 point; retain at least 95% of control PF, recovery, and return/drawdown; keep drawdown at or below 1.35% and no more than 0.20 point above control; keep at least control trades minus two; and change behavior.',
   '- Both 0.12 and 0.18 neighbors must be no worse than control in both disjoint eras; improve continuous net by at least 3% and CAGR by at least 0.05 point; retain at least 93% of control PF, recovery, and return/drawdown; keep drawdown at or below 1.35%; and change behavior.',
   '- The 0.20 stress row must remain profitable in every window, retain at least 85% of control recovery and return/drawdown, and keep drawdown at or below 1.50%.',
   '- Reject any losing window, isolated center, identity mismatch, compiler warning, safety failure, or result needing a different cap after observation. Only the exact frozen center may advance to a separately frozen recent-data gate.',
   '- Change only InpRVMaximumPositionLots. Keep requested reversion risk at 0.45%, momentum and adaptive-trend risk at 0.15%, total open risk at 0.75%, expected capital at $10,000, minimum-lot refusal, post-fill reconciliation, initial stops, targets, exits, period loss limits, and the 5% equity guard unchanged.',
   '- No martingale, grid, averaging down, recovery sizing, account-profit sizing, funding change, forward-candidate change, or real-account trading.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash
   Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir
}
