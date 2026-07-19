[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Portfolio.mq5',
   [string]$PackageDir = 'outputs\three_lane_adaptive_trend_gate_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_ADAPTIVE_TREND_GATE_MANIFEST.csv',
   [string]$ContractPath = 'outputs\THREE_LANE_ADAPTIVE_TREND_GATE_CONTRACT.md',
   [ValidateSet(1,4)][int]$Model = 1
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Convert-SourceDefault([string]$Type,[string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq 'string') { return $trimmed.Substring(1,$trimmed.Length - 2) }
   if($Type -eq 'ENUM_TIMEFRAMES') {
      $map = @{ PERIOD_H1='16385'; PERIOD_H4='16388'; PERIOD_D1='16408' }
      if(!$map.ContainsKey($trimmed)) { throw "Unsupported timeframe: $trimmed" }
      return $map[$trimmed]
   }
   return $trimmed
}
function Get-PinnedSourceInputs([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$') { continue }
      $type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3]
      if($inputs.Contains($name)) { throw "Duplicate source input: $name" }
      $inputs[$name] = if($type -eq 'string') { "$name=$value" } else { "$name=$value||$value||0||0||N" }
   }
   if($inputs.Count -lt 170) { throw "Unexpectedly small three-lane input contract: $($inputs.Count)" }
   return $inputs
}
function Set-PinnedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Cannot override unknown input: $Name" }
   $Inputs[$Name] = if($StringValue) { "$Name=$Value" } else { "$Name=$Value||$Value||0||0||N" }
}
function Copy-PinnedInputs($Inputs) {
   $copy=[ordered]@{};foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]};return $copy
}

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedSourceHash = '51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB'
if($sourceHash -ne $expectedSourceHash) { throw "Three-lane source identity changed: $sourceHash" }
$base = Get-PinnedSourceInputs $source

$baseOverrides = [ordered]@{
   InpAllowedSymbol='XAUUSD'; InpAllowRealAccountTrading='false'; InpRealAccountApprovalCode='DISABLED'
   InpUseInitialBalanceContract='true'; InpExpectedInitialBalance='10000.0'; InpInitialBalanceTolerancePercent='1.0'
   InpUseAccountCurrencyLock='true'; InpRequiredAccountCurrency='USD'; InpUseDedicatedAccountContract='true'
   InpRejectFundingChangesAfterRegistration='true'; InpMaximumPortfolioEquityDrawdownPercent='5.00'
   InpMaximumPortfolioDailyLossPercent='0.75'; InpMaximumPortfolioWeeklyLossPercent='1.25'
   InpMaximumPortfolioMonthlyLossPercent='1.50'; InpMaximumPortfolioOpenRiskPercent='0.75'
   InpMaximumAccountPositions='3'; InpBlockUnprotectedAccountExposure='true'; InpCloseUnprotectedManagedPositions='true'
   InpRVEnabled='true'; InpRVRiskPercent='0.45'; InpRVUseDIEdgeGate='true'; InpRVUseD1MomentumCap='true'
   InpRVD1MomentumLookbackBars='126'; InpRVMaximumAbsoluteD1MomentumPercent='12.0'; InpRVMaximumPositionLots='0.10'
   InpMOEnabled='true'; InpMORiskPercent='0.15'; InpMOMaximumPositionLots='1.00'
   InpATBEnabled='true'; InpATBRiskPercent='0.10'; InpATBSignalTimeframe='16388'; InpATBEntryLookbackBars='10'
   InpATBMomentumTimeframe='16408'; InpATBUseLongMomentumAgreement='false'; InpATBUseTrendEMAFilter='true'
   InpATBTrendFastEMAPeriod='20'; InpATBTrendSlowEMAPeriod='100'; InpATBTrendSlopeLookbackBars='5'
   InpATBMinimumTrendSlopeATR='0.00'; InpATBUseSignalEMAFilter='true'; InpATBSignalEMAPeriod='50'
   InpATBSignalEMASlopeLookbackBars='3'; InpATBMinimumSignalSlopeATR='0.00'; InpATBUseADXFilter='true'
   InpATBADXPeriod='14'; InpATBMinimumADX='14.0'; InpATBMaximumADX='50.0'; InpATBUseBreakoutQualityFilter='true'
   InpATBMinimumBreakoutBodyPercent='35.0'; InpATBMinimumBreakoutCloseLocationPercent='60.0'
   InpATBMinimumBreakoutRangeATR='0.40'; InpATBMaximumBreakoutRangeATR='2.50'; InpATBUseTickVolumeExpansion='false'
   InpATBStopLookbackBars='8'; InpATBMinimumStopATR='0.80'; InpATBMaximumStopATR='3.00'
   InpATBMaximumStopPriceDistance='40.00'; InpATBTakeProfitR='2.00'; InpATBExitLookbackBars='10'
   InpATBMaximumHoldBars='180'; InpATBUseSessionFilter='false'; InpATBMaximumPositionLots='0.10'
   InpLogTrades='false'; InpShowDashboard='false'
}
foreach($pair in $baseOverrides.GetEnumerator()) {
   $isString = $pair.Key -in @('InpAllowedSymbol','InpRealAccountApprovalCode','InpRequiredAccountCurrency')
   Set-PinnedInput $base $pair.Key $pair.Value -StringValue:$isString
}
Set-PinnedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-PinnedInput $base 'InpEvidenceRunLabel' 'three_lane_adaptive_trend_wave1_critical' -StringValue

$profiles = @(
   [pscustomobject]@{Candidate='tlat_di11_atb10';DIEdge='-11.0'},
   [pscustomobject]@{Candidate='tlat_di12_atb10_center';DIEdge='-12.0'},
   [pscustomobject]@{Candidate='tlat_di13_atb10';DIEdge='-13.0'}
)
$modelTag=if($Model -eq 4){'m4'}else{'m1'}
$windows = @(
   [pscustomobject]@{Name='critical_2019';From='2019.01.01';To='2019.12.31'},
   [pscustomobject]@{Name='critical_2022';From='2022.01.01';To='2022.12.31'}
)

$package=Resolve-RepoPath $PackageDir
if(Test-Path -LiteralPath $package){Remove-Item -LiteralPath $package -Recurse -Force}
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$rank=0
foreach($profile in $profiles){
   $inputs=Copy-PinnedInputs $base
   Set-PinnedInput $inputs 'InpRVMinimumDIEdge' $profile.DIEdge
   $profileName="$($profile.Candidate).set";$profilePath=Join-Path $profileDir $profileName
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $rank++;$reportName="$($profile.Candidate)_$($window.Name)_$modelTag";$configName=('{0:D3}_{1}.ini' -f $rank,$reportName);$configPath=Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model -Deposit 10000
      $rows.Add([pscustomobject][ordered]@{QueueRank=$rank;Candidate=$profile.Candidate;Window=$window.Name;Model=$Model;Deposit=10000;PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();SourceSha256=$sourceHash;ProfileSha256=$profileHash})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath;$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@('# Three-Lane Adaptive Trend Critical Gate','',
  "**Status: FROZEN CRITICAL GATE / MODEL $Model / NO CANDIDATE CHANGE.**",'',
  "- Source SHA-256: ``$sourceHash``","- Manifest SHA-256: ``$manifestHash``",
  '- Architecture: exact stability source plus independent H4 trend lane; no martingale, grid, averaging, or recovery sizing.',
  '- Frozen allocation: 0.45% reversion, 0.15% original momentum, 0.10% H4 trend; 0.75% account-wide open-risk cap.',
  '- Profiles: DI -11, -12 center, and -13; all other signals and risk settings fixed.',
  "- Fresh USD 10,000 Model $Model restarts for 2019 and 2022 only.",
  '- Center must have positive net, PF at least 1.05, at least 20 trades, and drawdown no more than 2.5% in both years; at least one adjacent DI profile must also pass.',
  '- Failure closes all broad, Model4, annual, stress, broker, forward, and real-money testing.')|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status='FROZEN';Profiles=$profiles.Count;Configurations=$rows.Count;Inputs=$base.Count;SourceSha256=$sourceHash;ManifestSha256=$manifestHash}
