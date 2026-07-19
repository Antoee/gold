[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Trade_Ready_RC2.mq5',
   [string]$PackageDir = 'outputs\three_lane_trade_ready_rc2_critical_model1_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_TRADE_READY_RC2_CRITICAL_MODEL1_MANIFEST.csv',
   [string]$ContractPath = 'outputs\THREE_LANE_TRADE_READY_RC2_CRITICAL_MODEL1_CONTRACT.md',
   [ValidateSet(1,4)][int]$Model = 1,
   [ValidateSet('Critical','Broad','Annual','Growth','GrowthAnnual','GrowthDecomp','GrowthDecompAnnual')][string]$Gate = 'Critical'
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

function Get-PinnedInputs([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$') { continue }
      $type=$Matches[1];$name=$Matches[2];$value=Convert-SourceDefault $type $Matches[3]
      if($inputs.Contains($name)) { throw "Duplicate source input: $name" }
      $inputs[$name] = if($type -eq 'string') { "$name=$value" } else { "$name=$value||$value||0||0||N" }
   }
   if($inputs.Count -lt 175) { throw "Unexpectedly small RC2 input contract: $($inputs.Count)" }
   return $inputs
}

function Set-PinnedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Cannot override unknown input: $Name" }
   $Inputs[$Name] = if($StringValue) { "$Name=$Value" } else { "$Name=$Value||$Value||0||0||N" }
}

function Copy-PinnedInputs($Inputs) {
   $copy=[ordered]@{}
   foreach($key in $Inputs.Keys){$copy[$key]=$Inputs[$key]}
   return $copy
}

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedSourceHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
if($sourceHash -ne $expectedSourceHash) { throw "RC2 source identity changed: $sourceHash" }
$base = Get-PinnedInputs $source

$overrides = [ordered]@{
   InpAllowedSymbol='XAUUSD';InpAllowRealAccountTrading='false';InpRealAccountApprovalCode='DISABLED'
   InpUseInitialBalanceContract='true';InpExpectedInitialBalance='10000.0';InpInitialBalanceTolerancePercent='1.0'
   InpUseAccountCurrencyLock='true';InpRequiredAccountCurrency='USD';InpUseDedicatedAccountContract='true'
   InpRejectFundingChangesAfterRegistration='true';InpMaximumPortfolioEquityDrawdownPercent='5.00'
   InpMaximumPortfolioDailyLossPercent='0.75';InpMaximumPortfolioWeeklyLossPercent='1.25'
   InpMaximumPortfolioMonthlyLossPercent='1.50';InpMaximumPortfolioOpenRiskPercent='0.75'
   InpMaximumAccountPositions='3';InpBlockUnprotectedAccountExposure='true';InpCloseUnprotectedManagedPositions='true'
   InpUseTradeEnvironmentGuard='true';InpMaximumQuoteAgeSeconds='30';InpMaximumStopsLevelPoints='250.0'
   InpMaximumFreezeLevelPoints='250.0';InpRequireConfirmedTradeResults='true'
   InpUsePostFillRiskReconciliation='true';InpPostFillRiskTolerancePercent='0.005'
   InpRVEnabled='true';InpRVRiskPercent='0.45';InpRVUseDIEdgeGate='true';InpRVUseD1MomentumCap='true'
   InpRVD1MomentumLookbackBars='126';InpRVMaximumAbsoluteD1MomentumPercent='12.0';InpRVMaximumPositionLots='0.10'
   InpMOEnabled='true';InpMORiskPercent='0.15';InpMOMaximumPositionLots='1.00'
   InpATBEnabled='true';InpATBRiskPercent='0.10';InpATBSignalTimeframe='16388';InpATBEntryLookbackBars='10'
   InpATBMomentumTimeframe='16408';InpATBUseLongMomentumAgreement='false';InpATBUseTrendEMAFilter='true'
   InpATBTrendFastEMAPeriod='20';InpATBTrendSlowEMAPeriod='100';InpATBTrendSlopeLookbackBars='5'
   InpATBMinimumTrendSlopeATR='0.00';InpATBUseSignalEMAFilter='true';InpATBSignalEMAPeriod='50'
   InpATBSignalEMASlopeLookbackBars='3';InpATBMinimumSignalSlopeATR='0.00';InpATBUseADXFilter='true'
   InpATBADXPeriod='14';InpATBMinimumADX='14.0';InpATBMaximumADX='50.0';InpATBUseBreakoutQualityFilter='true'
   InpATBMinimumBreakoutBodyPercent='35.0';InpATBMinimumBreakoutCloseLocationPercent='60.0'
   InpATBMinimumBreakoutRangeATR='0.40';InpATBMaximumBreakoutRangeATR='2.50';InpATBUseTickVolumeExpansion='false'
   InpATBStopLookbackBars='8';InpATBMinimumStopATR='0.80';InpATBMaximumStopATR='3.00'
   InpATBMaximumStopPriceDistance='40.00';InpATBTakeProfitR='2.00';InpATBExitLookbackBars='10'
   InpATBMaximumHoldBars='180';InpATBUseSessionFilter='false';InpATBMaximumPositionLots='0.10'
   InpLogTrades='false';InpShowDashboard='false'
}
foreach($pair in $overrides.GetEnumerator()) {
   $isString = $pair.Key -in @('InpAllowedSymbol','InpRealAccountApprovalCode','InpRequiredAccountCurrency')
   Set-PinnedInput $base $pair.Key $pair.Value -StringValue:$isString
}
Set-PinnedInput $base 'InpEvidenceSourceHash' $sourceHash -StringValue
Set-PinnedInput $base 'InpEvidenceRunLabel' ("three_lane_trade_ready_rc2_{0}" -f $Gate.ToLowerInvariant()) -StringValue

$profiles = @(
   if($Gate -eq 'Growth') {
      [pscustomobject]@{Profile='tlat_rc2_growth_100';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.10';OpenRisk='0.75';RiskScale='1.00'},
      [pscustomobject]@{Profile='tlat_rc2_growth_125';DIEdge='-12.0';RVRisk='0.5625';MORisk='0.1875';ATBRisk='0.125';OpenRisk='0.9375';RiskScale='1.25'},
      [pscustomobject]@{Profile='tlat_rc2_growth_150';DIEdge='-12.0';RVRisk='0.675';MORisk='0.225';ATBRisk='0.15';OpenRisk='1.125';RiskScale='1.50'},
      [pscustomobject]@{Profile='tlat_rc2_growth_200';DIEdge='-12.0';RVRisk='0.90';MORisk='0.30';ATBRisk='0.20';OpenRisk='1.50';RiskScale='2.00'}
   } elseif($Gate -eq 'GrowthDecomp') {
      [pscustomobject]@{Profile='tlat_rc2_decomp_control';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.10';OpenRisk='0.75';RiskScale='control'},
      [pscustomobject]@{Profile='tlat_rc2_decomp_atb125';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.125';OpenRisk='0.75';RiskScale='atb_1.25'},
      [pscustomobject]@{Profile='tlat_rc2_decomp_atb150';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.15';OpenRisk='0.75';RiskScale='atb_1.50'},
      [pscustomobject]@{Profile='tlat_rc2_decomp_mo125';DIEdge='-12.0';RVRisk='0.45';MORisk='0.1875';ATBRisk='0.10';OpenRisk='0.75';RiskScale='mo_1.25'},
      [pscustomobject]@{Profile='tlat_rc2_decomp_rv125';DIEdge='-12.0';RVRisk='0.5625';MORisk='0.15';ATBRisk='0.10';OpenRisk='0.85';RiskScale='rv_1.25'}
   } elseif($Gate -eq 'GrowthDecompAnnual') {
      [pscustomobject]@{Profile='tlat_rc2_decomp_atb150';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.15';OpenRisk='0.75';RiskScale='atb_1.50'}
   } elseif($Gate -eq 'GrowthAnnual') {
      [pscustomobject]@{Profile='tlat_rc2_growth_125';DIEdge='-12.0';RVRisk='0.5625';MORisk='0.1875';ATBRisk='0.125';OpenRisk='0.9375';RiskScale='1.25'}
   } elseif($Gate -eq 'Annual') {
      [pscustomobject]@{Profile='tlat_rc2_di12_center';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.10';OpenRisk='0.75';RiskScale='1.00'}
   } else {
      [pscustomobject]@{Profile='tlat_rc2_di11';DIEdge='-11.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.10';OpenRisk='0.75';RiskScale='1.00'},
      [pscustomobject]@{Profile='tlat_rc2_di12_center';DIEdge='-12.0';RVRisk='0.45';MORisk='0.15';ATBRisk='0.10';OpenRisk='0.75';RiskScale='1.00'}
   }
)
$windows = switch($Gate) {
   'Critical' {
      @(
         [pscustomobject]@{Name='critical_2019';From='2019.01.01';To='2019.12.31'},
         [pscustomobject]@{Name='critical_2022';From='2022.01.01';To='2022.12.31'}
      )
   }
   'Broad' {
      @(
         [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
         [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
         [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
         [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
      )
   }
   'Growth' {
      @(
         [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
         [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
         [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
         [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
      )
   }
   'GrowthDecomp' {
      @(
         [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
         [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
         [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
         [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
      )
   }
   'GrowthDecompAnnual' {
      $annualWindows = [Collections.Generic.List[object]]::new()
      foreach($year in 2015..2025) {
         $annualWindows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"}) | Out-Null
      }
      $annualWindows.Add([pscustomobject]@{Name='year_2026_ytd';From='2026.01.01';To='2026.07.12'}) | Out-Null
      @($annualWindows)
   }
   'GrowthAnnual' {
      $annualWindows = [Collections.Generic.List[object]]::new()
      foreach($year in 2015..2025) {
         $annualWindows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"}) | Out-Null
      }
      $annualWindows.Add([pscustomobject]@{Name='year_2026_ytd';From='2026.01.01';To='2026.07.12'}) | Out-Null
      @($annualWindows)
   }
   'Annual' {
      $annualWindows = [Collections.Generic.List[object]]::new()
      foreach($year in 2015..2025) {
         $annualWindows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"}) | Out-Null
      }
      $annualWindows.Add([pscustomobject]@{Name='year_2026_ytd';From='2026.01.01';To='2026.07.12'}) | Out-Null
      @($annualWindows)
   }
}
$modelTag=if($Model -eq 4){'m4'}else{'m1'}

$package=Resolve-RepoPath $PackageDir
if(Test-Path -LiteralPath $package){Remove-Item -LiteralPath $package -Recurse -Force}
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$rank=0
foreach($profile in $profiles){
   $inputs=Copy-PinnedInputs $base
   Set-PinnedInput $inputs 'InpRVMinimumDIEdge' $profile.DIEdge
   Set-PinnedInput $inputs 'InpRVRiskPercent' $profile.RVRisk
   Set-PinnedInput $inputs 'InpMORiskPercent' $profile.MORisk
   Set-PinnedInput $inputs 'InpATBRiskPercent' $profile.ATBRisk
   Set-PinnedInput $inputs 'InpMaximumPortfolioOpenRiskPercent' $profile.OpenRisk
   $profileName="$($profile.Profile).set";$profilePath=Join-Path $profileDir $profileName
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $rank++;$reportName="$($profile.Profile)_$($window.Name)_$modelTag";$configName=('{0:D3}_{1}.ini' -f $rank,$reportName);$configPath=Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model -Deposit 10000
      $rows.Add([pscustomobject][ordered]@{QueueRank=$rank;Profile=$profile.Profile;Candidate=$profile.Profile;Phase=$Gate.ToLowerInvariant();Set='trade_ready_rc2';Window=$window.Name;From=$window.From;To=$window.To;Model=$Model;Deposit=10000;RiskScale=$profile.RiskScale;RVRiskPercent=$profile.RVRisk;MORiskPercent=$profile.MORisk;ATBRiskPercent=$profile.ATBRisk;PortfolioOpenRiskPercent=$profile.OpenRisk;PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();SourceSha256=$sourceHash;ProfileSha256=$profileHash})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath;$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
$contractLines = if($Gate -in @('Growth','GrowthAnnual','GrowthDecomp','GrowthDecompAnnual')) {
   @("# Three-Lane Trade-Ready RC2 Growth Screen",'',"**Status: MODEL $Model RESEARCH ONLY. RC2 RELEASE UNCHANGED.**",'',
     "- Source SHA-256: ``$sourceHash``","- Manifest SHA-256: ``$manifestHash``",
     '- Signal, exit, calendar, and execution logic remain byte-identical to Trade-Ready RC2.',
     '- Only lane risk and the matching portfolio open-risk allowance vary by adjacent scale.',
     '- Daily, weekly, monthly, and 5% portfolio equity-loss limits remain fixed.',
     '- Every broad era must be profitable; continuous PF >= 1.50, DD <= 3%, recovery >= 6, and useful profit scaling are required before Model 4.',
     '- Any losing era, protection-driven trade collapse, or dominated return/drawdown profile rejects the scale.')
} else {
   @("# Three-Lane Trade-Ready RC2 $Gate Gate",'',"**Status: FROZEN MODEL $Model EQUIVALENCE GATE.**",'',
     "- Source SHA-256: ``$sourceHash``","- Manifest SHA-256: ``$manifestHash``",
     '- Strategy and risk settings match RC1; only fail-closed execution hardening is added.',
     "- $Gate windows must reproduce RC1 trade counts, profitability, and risk behavior.",
     '- Any compiler warning, missing report, losing row, risk closure, or material trade/net mismatch rejects RC2.')
}
$contractLines|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status=if($Gate -in @('Growth','GrowthAnnual','GrowthDecomp','GrowthDecompAnnual')){'RESEARCH'}else{'FROZEN'};Gate=$Gate;Model=$Model;Profiles=$profiles.Count;Configurations=$rows.Count;Inputs=$base.Count;SourceSha256=$sourceHash;ManifestSha256=$manifestHash}
