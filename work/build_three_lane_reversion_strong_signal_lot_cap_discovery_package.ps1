[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5',
   [string]$ChampionProfilePath = 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set',
   [string]$PackageDir = 'outputs\three_lane_reversion_strong_signal_lot_cap_discovery_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_DISCOVERY_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
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
      $type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3]
      if($inputs.Contains($name)) { throw "Duplicate source input: $name" }
      $inputs[$name]=if($type -eq 'string'){"$name=$value"}else{"$name=$value||$value||0||0||N"}
   }
   return $inputs
}
function Copy-Inputs($Inputs) {
   $copy=[ordered]@{}
   foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]}
   return $copy
}
function Set-FixedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue) {
   if(!$Inputs.Contains($Name)){throw "Unknown input override: $Name"}
   $Inputs[$Name]=if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}
}

& (Join-Path $PSScriptRoot 'test_three_lane_reversion_strong_signal_lot_cap_source.ps1') | Out-Null
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$championProfile=(Resolve-Path -LiteralPath (Resolve-RepoPath $ChampionProfilePath)).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$championHash=(Get-FileHash -LiteralPath $championProfile -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash){throw "Selective-cap source identity changed: $sourceHash"}
if($championHash -ne $expectedChampionHash){throw "Champion profile identity changed: $championHash"}

$base=Get-SourceInputs $source
if($base.Count -ne 183){throw "Expected 183 research inputs, found $($base.Count)."}
$championKeys=[Collections.Generic.List[string]]::new()
foreach($line in Get-Content -LiteralPath $championProfile){
   if($line -notmatch '^(Inp[^=]+)=(.*)$'){continue}
   $name=$Matches[1]
   if(!$base.Contains($name)){throw "Champion input missing from source: $name"}
   $base[$name]=$line
   $championKeys.Add($name)|Out-Null
}
if($championKeys.Count -ne 178){throw "Expected 178 champion inputs, found $($championKeys.Count)."}
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'three_lane_reversion_strong_signal_lot_cap_discovery_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'
Set-FixedInput $base 'InpShowDashboard' 'false'
Set-FixedInput $base 'InpRVUseStrongSignalRisk' 'false'
Set-FixedInput $base 'InpRVStrongSignalMinimumBodyRatio' '0.25'
Set-FixedInput $base 'InpRVStrongSignalRiskPercent' '0.60'

$variants=@(
   [pscustomobject]@{Name='sslc_control';Role='control';Selective='false';BaseCap='0.10';StrongCap='0.15'},
   [pscustomobject]@{Name='sslc_unconditional015';Role='unconditional_reference';Selective='false';BaseCap='0.15';StrongCap='0.15'},
   [pscustomobject]@{Name='sslc_low012';Role='lower_neighbor';Selective='true';BaseCap='0.10';StrongCap='0.12'},
   [pscustomobject]@{Name='sslc_center015';Role='center';Selective='true';BaseCap='0.10';StrongCap='0.15'},
   [pscustomobject]@{Name='sslc_high018';Role='upper_neighbor';Selective='true';BaseCap='0.10';StrongCap='0.18'}
)
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='later_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)
$stopRule='Pre-2021 selective strong-signal lot-cap discovery only. Every report profitable. Center must be no worse than control in both eras; continuous net >=control +5%, CAGR >=control +0.08 point, PF/recovery/return-DD >=control, DD <=1.22% and <=control +0.10 point, trades >=control -2, changed behavior, retain >=50% of unconditional incremental net, and improve DD/recovery/return-DD versus unconditional. Both selective neighbors no worse in both eras; net >=control +3%, CAGR >=control +0.05 point, PF/recovery/return-DD >=97% control, DD <=1.25%, and changed behavior. No post-result threshold or cap change.'

$package=Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles'
$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$queueRows=[Collections.Generic.List[object]]::new();$runRows=[Collections.Generic.List[object]]::new()
$ordinal=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++
   $inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpRVUseStrongSignalLotCap' $variant.Selective
   Set-FixedInput $inputs 'InpRVMaximumPositionLots' $variant.BaseCap
   Set-FixedInput $inputs 'InpRVStrongSignalMaximumPositionLots' $variant.StrongCap
   $profileName="$($variant.Name).set";$profilePath=Join-Path $profileDir $profileName
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++
      $configName='{0:000}_{1}_{2}_m1.ini' -f $ordinal,$variant.Name,$window.Name
      $configPath=Join-Path $configDir $configName;$reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $configHash=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
      $common=[ordered]@{
         QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         Phase='three_lane_reversion_strong_signal_lot_cap_discovery_model1';Window=$window.Name
         From=$window.From;To=$window.To;Model=1;Deposit=10000;StrongSignalBodyRatio='0.25'
         StrongSignalRiskEnabled='false';ReversionRiskPercent='0.45';SelectiveLotCapEnabled=$variant.Selective
         BaseReversionMaximumPositionLots=$variant.BaseCap;StrongSignalMaximumPositionLots=$variant.StrongCap
         MaximumPortfolioOpenRiskPercent='0.75';ExpectedReportName=$reportName;ConfigSha256=$configHash
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      }
      $queueRows.Add([pscustomobject]($common+[ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"}))|Out-Null
      $runRows.Add([pscustomobject]($common+[ordered]@{PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"}))|Out-Null
   }
}
$queueRows|Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$runRows|Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Three-Lane Strong-Signal Selective Lot-Cap Discovery Package','',
   '**Status: PREREGISTERED 2015-2020 DISCOVERY. ATB150 AND THE FORWARD CANDIDATE ARE UNCHANGED.**','',
   "- Research source SHA-256: ``$sourceHash``","- Frozen champion profile SHA-256: ``$championHash``",
   "- Variants: ``$($variants.Count)``; configurations: ``$ordinal``",
   '- Completed-H1 directional body ratio is frozen at 0.25 from the prior strong-signal research.',
   '- Control uses 0.10 lots. The unconditional reference uses 0.15 for every reversion. Selective rows use 0.12 / 0.15 / 0.18 only when the completed signal qualifies.',
   '- Requested reversion risk remains 0.45%; strong-risk allocation is disabled; portfolio open risk remains capped at 0.75%.'
)|Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Strong-Signal Selective Reversion Lot-Cap Discovery Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Freeze exact source/profile identity, completed-H1 body ratio 0.25, control 0.10, unconditional 0.15 reference, and selective 0.12 / 0.15 / 0.18 neighborhood before testing.',
   '- Require every report profitable. Require the selective 0.15 center no worse than control in both disjoint eras; continuous net at least 5% above control; CAGR at least 0.08 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.22% and no more than 0.10 point above control; trades at least control minus two; and changed behavior.',
   '- Require center to retain at least 50% of unconditional incremental net while strictly improving drawdown, recovery, and return/drawdown versus unconditional 0.15.',
   '- Require selective 0.12 and 0.18 neighbors no worse than control in both eras; continuous net at least 3% above control; CAGR at least 0.05 point above control; PF, recovery, and return/drawdown at least 97% of control; drawdown at most 1.25%; and changed behavior.',
   '- Reject a losing window, inactive feature, isolated center, identity mismatch, compiler warning, safety failure, or any result needing a different body threshold or lot cap after observation. Only exact center may open a separately frozen recent-data gate.',
   '- Keep requested reversion risk 0.45%, momentum/adaptive risk 0.15%, portfolio open risk 0.75%, initial stops, targets, exits, minimum-lot refusal, post-fill reconciliation, loss limits, $10,000 capital contract, and real-account lock unchanged.',
   '- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, funding change, forward-candidate change, or real-account trading.'
)|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;ChampionProfileSha256=$championHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;Inputs=$base.Count;PackageDir=$PackageDir}
