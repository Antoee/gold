[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Independent_XAUUSD_M15_Dual_Regime_Normalized_Stop.mq5',
   [string]$PackageDir = 'outputs\independent_m15_dual_regime_normalized_stop_model1_package',
   [string]$QueuePath = 'outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_MANIFEST.csv',
   [string]$PackageMarkdownPath = 'outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_PACKAGE.md',
   [string]$ContractPath = 'outputs\INDEPENDENT_M15_DUAL_REGIME_NORMALIZED_STOP_MODEL1_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'E6AB84CA7780A47FDE04A01CB74966204220B91B2DA97B65F1095066A10D2F50'
$expectedParentHash = 'DEA3B16FB2D14E4A1253B422CCE80AEC4CB49DCF03067EDBCE96008F694FA5E1'

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}
function Convert-SourceDefault([string]$Type,[string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq 'string') { return $trimmed.Substring(1,$trimmed.Length-2) }
   if($Type -eq 'ENUM_TIMEFRAMES') {
      $map = @{PERIOD_M15='15';PERIOD_H1='16385';PERIOD_H4='16388';PERIOD_D1='16408'}
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

& (Join-Path $PSScriptRoot 'test_independent_m15_dual_regime_normalized_stop_source.ps1') | Out-Null
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$parent=(Resolve-Path -LiteralPath (Resolve-RepoPath 'work\Independent_XAUUSD_M15_Dual_Regime_Portfolio.mq5')).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$parentHash=(Get-FileHash -LiteralPath $parent -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash){throw "Normalized-stop source identity changed: $sourceHash"}
if($parentHash -ne $expectedParentHash){throw "Parent source identity changed: $parentHash"}

$base=Get-SourceInputs $source
if($base.Count -ne 105){throw "Expected 105 inputs, found $($base.Count)."}
Set-FixedInput $base 'InpVcrMinimumVolumeRatio' '1.50'
Set-FixedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-FixedInput $base 'InpEvidenceRunLabel' 'independent_m15_dual_regime_normalized_stop_model1' -StringValue
Set-FixedInput $base 'InpLogTrades' 'false'

$variants=@(
   [pscustomobject]@{Name='drns_fixed6';Normalized='false';PriceDistance='6.00';PricePercent='0.30';Promotable=$false},
   [pscustomobject]@{Name='drns_pct025';Normalized='true';PriceDistance='6.00';PricePercent='0.25';Promotable=$true},
   [pscustomobject]@{Name='drns_pct030';Normalized='true';PriceDistance='6.00';PricePercent='0.30';Promotable=$true},
   [pscustomobject]@{Name='drns_pct035';Normalized='true';PriceDistance='6.00';PricePercent='0.35';Promotable=$true},
   [pscustomobject]@{Name='drns_atr_only';Normalized='false';PriceDistance='0.00';PricePercent='0.30';Promotable=$false}
)
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='pre_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='transition_2021_2023';From='2021.01.01';To='2023.12.31'},
   [pscustomobject]@{Name='recent_2024_2026';From='2024.01.01';To='2026.07.17'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.17'}
)
$stopRule='Historical repair gate: require the 0.30% center positive in all four disjoint eras; recent net > 0 and PF >= 1.05; continuous net >= fixed-$6 control +25%, PF >= 1.25, trades >= 300, DD <= 2.00%; require at least one adjacent percentage profile to pass the same era/recent/continuous quality gates. ATR-only is diagnostic. No post-result retuning.'

$package=Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles'
$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$queueRows=[Collections.Generic.List[object]]::new();$runRows=[Collections.Generic.List[object]]::new()
$rank=0;$candidateRank=0
foreach($variant in $variants){
   $candidateRank++;$inputs=Copy-Inputs $base
   Set-FixedInput $inputs 'InpUsePriceNormalizedStopCap' $variant.Normalized
   Set-FixedInput $inputs 'InpMaximumStopPriceDistance' $variant.PriceDistance
   Set-FixedInput $inputs 'InpMaximumStopPricePercent' $variant.PricePercent
   Set-FixedInput $inputs 'InpEvidenceProfileId' $variant.Name -StringValue
   Set-FixedInput $inputs 'InpLogFileName' "$($variant.Name)_trades.csv" -StringValue
   $profileName="$($variant.Name).set";$profilePath=Join-Path $profileDir $profileName
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $rank++;$configName='{0:000}_{1}_{2}_m1.ini' -f $rank,$variant.Name,$window.Name
      $reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $common=[ordered]@{
         QueueRank=$rank;Candidate=$variant.Name;CandidateRank=$candidateRank;Phase='normalized_stop_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         PriceNormalizedStopCap=$variant.Normalized;MaximumStopPriceDistance=$variant.PriceDistance
         MaximumStopPricePercent=$variant.PricePercent;Promotable=$variant.Promotable
         ExpectedReportName=$reportName;ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule
      }
      $queueRows.Add([pscustomobject]($common+[ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"}))|Out-Null
      $runRows.Add([pscustomobject]($common+[ordered]@{
         PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
         ReportDestination="$PackageDir\reports_here\$reportName"
      }))|Out-Null
   }
}
$queueRows|Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$runRows|Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Independent M15 Dual-Regime Normalized-Stop Model 1 Package','',
   '**Status: HISTORICAL STRUCTURAL REPAIR. NO OUT-OF-SAMPLE CLAIM, PROMOTION, OR REAL TRADING IS AUTHORIZED.**','',
   "- Source SHA-256: ``$sourceHash``","- Parent SHA-256: ``$parentHash``",
   "- Variants: ``$($variants.Count)``","- Windows: ``$($windows.Count)``","- Configurations: ``$rank``",'',
   '- All profiles use the previously frozen vcr150 signal settings; only stop-distance ceiling units change.',
   '- Fixed-$6 is the exact behavior control, ATR-only is diagnostic, and 0.25%/0.30%/0.35% form the scale-invariant neighborhood.',
   '- The 2024-2026 window informed the repair hypothesis, so every result is development evidence rather than untouched holdout evidence.'
)|Set-Content -LiteralPath (Resolve-RepoPath $PackageMarkdownPath) -Encoding ASCII
@(
   '# Independent M15 Dual-Regime Normalized-Stop Model 1 Contract','',
   '**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**','',
   '- Freeze the vcr150 signal profile. Change only the unit used by the secondary stop-distance ceiling.',
   '- Compare exact fixed $6, ATR-only, and 0.25%/0.30%/0.35% of entry price. Do not add a post-result percentage.',
   '- Keep entries, ATR stop minima/maxima, targets, exits, sessions, 0.10% risk, lot caps, minimum-lot refusal, exposure guards, and loss limits unchanged.',
   '- Require the 0.30% center positive in 2015-2018, 2019-2020, 2021-2023, and 2024-2026.',
   '- Require recent net > 0 and PF >= 1.05; continuous net >= fixed-$6 control +25%, PF >= 1.25, at least 300 trades, and DD <= 2.00%.',
   '- Require at least one adjacent percentage profile to pass the same era, recent, and continuous quality gates.',
   '- ATR-only is diagnostic and cannot promote. Only a full center-plus-neighbor pass may open Model 4.',
   '- This is historical development evidence because 2024-2026 informed the rewrite. It is not forward evidence.',
   '- Reject identity mismatch, warning, missing report, losing era, isolated winner, threshold chase, martingale, grid, averaging down, recovery sizing, or real-account trading.'
)|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;ParentSha256=$parentHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$rank;Inputs=$base.Count;PackageDir=$PackageDir}
