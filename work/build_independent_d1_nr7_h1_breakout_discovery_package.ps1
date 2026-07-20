param(
   [string]$SourcePath = "work\Independent_XAUUSD_D1_NR7_H1_Breakout.mq5",
   [string]$PackageDir = "outputs\independent_d1_nr7_h1_breakout_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_D1_NR7_H1_BREAKOUT_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear non-outputs directory: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}
function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol="XAUUSD"; InpMagicNumber="26072031"; InpUseSymbolSafetyLock="true"
      InpUseRealAccountSafetyLock="true"; InpAllowRealAccountTrading="false"; InpRealAccountApprovalCode="DISABLED"
      InpSignalTimeframe="16385"; InpNarrowRangeLookbackDays="7"; InpDailyATRPeriod="20"; InpMaximumSetupRangeATR="0.85"
      InpBreakoutBufferATR="0.05"; InpMinimumBodyPercent="35.0"; InpVolumeLookbackBars="20"; InpMinimumVolumeRatio="1.00"
      InpAllowBuy="true"; InpAllowSell="true"; InpRequireFreshBreakout="true"
      InpUseTrendEMAFilter="true"; InpTrendTimeframe="16408"; InpTrendEMAPeriod="50"; InpTrendEMASlopeBars="3"
      InpUseADXFilter="false"; InpADXTimeframe="16385"; InpADXPeriod="14"; InpMinimumADX="18.0"
      InpUseVolatilityFilter="true"; InpMinimumATRPercent="0.03"; InpMaximumATRPercent="2.50"
      InpATRPeriod="20"; InpStopLookbackBars="12"; InpStopBufferATR="0.10"; InpMinimumStopATR="0.50"
      InpMaximumStopATR="2.50"; InpMaximumStopPriceDistance="40.00"; InpUseFixedTakeProfit="true"; InpTakeProfitR="3.00"
      InpUseBreakEven="true"; InpBreakEvenTriggerR="1.00"; InpBreakEvenLockR="0.10"; InpUseChandelierTrail="true"
      InpChandelierLookbackBars="24"; InpChandelierATR="2.75"; InpMaximumHoldBars="120"
      InpUseSessionFilter="true"; InpSessionStartHour="6"; InpSessionEndHour="20"; InpDisableFridayAfterHour="true"; InpFridayCutoffHour="18"
      InpRiskPercent="0.10"; InpMaximumPositionLots="1.00"; InpMaximumSimultaneousPositions="1"; InpMaximumTradesPerDay="1"
      InpMaximumDailyLossPercent="0.75"; InpMaximumEquityDrawdownPercent="5.00"; InpMaximumConsecutiveLosses="4"
      InpLossCooldownHours="24"; InpMaximumSpreadPoints="50.0"; InpDeviationPoints="20"
      InpUseAccountWideExposureGuard="true"; InpAccountWideMaxOpenRiskPercent="1.00"; InpAccountWideMaxPositions="3"
      InpAccountWideBlockUnprotectedExposure="true"; InpLogTrades="false"
      InpLogFileName="Independent_XAUUSD_D1_NR7_H1_Breakout_Trades.csv"; InpEvidenceProfileId=""
      InpEvidenceSourceHash=""; InpEvidenceRunLabel=""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_d1_nr7_h1_breakout_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedSourceHash = 'BBFC4214F63658B7D2D22109AC0C536D32A23693C471179DB0E07EA70C974880'
if($sourceHash -ne $expectedSourceHash) { throw "NR7 source identity changed: $sourceHash" }

$variants = @(
   [pscustomobject]@{Name='dnrb_center';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_nr5';Lookback='5';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_nr10';Lookback='10';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_maxatr070';Lookback='7';MaxATR='0.70';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_maxatr100';Lookback='7';MaxATR='1.00';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_buffer000';Lookback='7';MaxATR='0.85';Buffer='0.00';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_buffer010';Lookback='7';MaxATR='0.85';Buffer='0.10';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_body025';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='25.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_body045';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='45.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_volume000';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='0.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_volume115';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.15';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_ema20';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='20';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_ema100';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='100';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_noema';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='false';EMA='50';ADX='false';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_adx18';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='true';TP='3.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_tp200';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='2.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_tp400';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='4.00';Trail='true'},
   [pscustomobject]@{Name='dnrb_no_trail';Lookback='7';MaxATR='0.85';Buffer='0.05';Body='35.0';Volume='1.00';UseEMA='true';EMA='50';ADX='false';TP='3.00';Trail='false'}
)
$windows = @(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='discovery_2019_2020';From='2019.01.01';To='2020.12.31'},
   [pscustomobject]@{Name='continuous_2015_2020';From='2015.01.01';To='2020.12.31'}
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull 'configs'
$profileDir = Join-Path $packageFull 'profiles'
$reportDir = Join-Path $packageFull 'reports_here'
$sourceDir = Join-Path $packageFull 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force

$queueRows=[System.Collections.Generic.List[object]]::new()
$runRows=[System.Collections.Generic.List[object]]::new()
$ordinal=0
$candidateRank=0
$stopRule='Discovery only: both disjoint eras positive; continuous PF >= 1.25; >= 80 trades; DD <= 3%; recovery >= 1.5; center or one-factor row requires adjacent support before 2021+ may open.'
foreach($variant in $variants){
   $candidateRank++
   $inputs=New-BaseInputs
   foreach($pair in @(
      @('InpNarrowRangeLookbackDays',$variant.Lookback),@('InpMaximumSetupRangeATR',$variant.MaxATR),
      @('InpBreakoutBufferATR',$variant.Buffer),@('InpMinimumBodyPercent',$variant.Body),
      @('InpMinimumVolumeRatio',$variant.Volume),@('InpUseTrendEMAFilter',$variant.UseEMA),
      @('InpTrendEMAPeriod',$variant.EMA),@('InpUseADXFilter',$variant.ADX),
      @('InpTakeProfitR',$variant.TP),@('InpUseChandelierTrail',$variant.Trail),
      @('InpEvidenceProfileId',$variant.Name),@('InpEvidenceSourceHash',$sourceHash),
      @('InpEvidenceRunLabel','independent_d1_nr7_h1_breakout_discovery_model1'),
      @('InpLogFileName',"$($variant.Name)_trades.csv")
   )){Set-InputLine -Inputs $inputs -Name $pair[0] -Value ([string]$pair[1])}
   $profileName="$($variant.Name).set"
   $profilePath=Join-Path $profileDir $profileName
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
   foreach($window in $windows){
      $ordinal++
      $configName="{0:000}_{1}_{2}_m1.ini" -f $ordinal,$variant.Name,$window.Name
      $reportName="$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 60
      $common=[ordered]@{QueueRank=$ordinal;Candidate=$variant.Name;CandidateRank=$candidateRank;SourceType='independent_d1_nr7_h1_breakout';Phase='discovery_model1';Window=$window.Name;Model=1;Deposit=10000;ExpectedReportName=$reportName;ProfileSha256=$profileHash;SourceSha256=$sourceHash;StopRule=$stopRule}
      $queueRows.Add([pscustomobject]($common+@{Set=$profileName;From=$window.From;To=$window.To;Config="configs\$configName";ProfileSnapshot="profiles\$profileName";LookbackDays=$variant.Lookback;MaximumSetupRangeATR=$variant.MaxATR;BreakoutBufferATR=$variant.Buffer;MinimumBodyPercent=$variant.Body;MinimumVolumeRatio=$variant.Volume;EMAFilter=$variant.UseEMA;EMAPeriod=$variant.EMA;ADXFilter=$variant.ADX;TakeProfitR=$variant.TP;ChandelierTrail=$variant.Trail}))|Out-Null
      $runRows.Add([pscustomobject]($common+@{PhaseLabel='Independent D1 NR7 / H1 breakout discovery Model1';PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"}))|Out-Null
   }
}
$queueRows|Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows|Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Independent D1 NR7 / H1 Breakout Discovery Package','',
   'Standalone, date-independent research family. No configuration includes data after 2020.','',
   "- Source SHA-256: ``$sourceHash``","- Variants: ``$($variants.Count)``","- Windows: ``$($windows.Name -join ', ')``","- Configurations: ``$ordinal``",'',
   'Every profile reads only completed D1/H1 bars, uses broker-native risk sizing with minimum-lot refusal, risks 0.10% per accepted trade, caps account-wide open risk at 1.00%, caps daily loss at 0.75% and equity drawdown at 5.00%, and keeps real-account trading disabled.'
)|Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{Status='READY';SourceHash=$sourceHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$ordinal;PackageDir=$PackageDir}
