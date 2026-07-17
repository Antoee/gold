param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Dual_Regime_Portfolio.mq5",
   [string]$PackageDir = "outputs\independent_m15_dual_regime_portfolio_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071774"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpEnableVolumeClimax = "true"; InpEnableVolatilitySqueeze = "true"
      InpAllowBuy = "true"; InpAllowSell = "true"
      InpVcrVolumeLookbackBars = "24"; InpVcrMinimumVolumeRatio = "1.30"; InpVcrExtremeLookbackBars = "8"
      InpVcrMinimumRangeATR = "1.10"; InpVcrMaximumRangeATR = "3.00"
      InpVcrMinimumWickPercent = "45.0"; InpVcrMaximumBodyPercent = "55.0"; InpVcrMinimumCloseLocation = "0.55"
      InpVcrMinimumVWAPDeviationATR = "0.45"; InpVcrMaximumVWAPDeviationATR = "2.50"
      InpVcrMinimumRiskReward = "1.10"; InpVcrMaximumTargetR = "1.75"; InpVcrRequireFreshExtreme = "true"
      InpSqSqueezeBars = "3"; InpSqBollingerPeriod = "20"; InpSqBollingerDeviation = "2.00"
      InpSqKeltnerEMAPeriod = "20"; InpSqKeltnerATRMultiplier = "1.50"; InpSqBreakoutLookbackBars = "8"
      InpSqMaximumBreakoutChannelATR = "3.50"; InpSqBreakBufferATR = "0.03"
      InpSqMinimumBreakRangeATR = "0.40"; InpSqMaximumBreakRangeATR = "1.60"; InpSqMinimumExpansionRatio = "1.10"
      InpSqMinimumBreakBodyPercent = "35.0"; InpSqMinimumBreakCloseLocation = "0.65"
      InpSqRequireDirectionCandle = "true"; InpSqUseBreakoutTickVolumeFilter = "false"
      InpSqVolumeLookbackBars = "20"; InpSqMinimumVolumeRatio = "1.05"
      InpTrendTimeframe = "16385"; InpTrendEMAPeriod = "100"; InpADXPeriod = "14"
      InpVcrUseRangePhaseFilter = "true"; InpVcrMaximumADX = "28.0"; InpVcrMaximumTrendDistanceATR = "2.50"
      InpSqUseTrendEMAFilter = "true"; InpSqTrendEMASlopeBars = "3"; InpSqRequireTrendAlignment = "true"
      InpSqUseADXFilter = "false"; InpSqMinimumADX = "14.0"; InpSqMaximumADX = "45.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpMaximumStopPriceDistance = "6.00"
      InpVcrStopBufferATR = "0.08"; InpVcrMinimumStopATR = "0.20"; InpVcrMaximumStopATR = "1.50"
      InpVcrUseBreakEven = "true"; InpVcrBreakEvenTriggerR = "0.90"; InpVcrBreakEvenLockR = "0.10"
      InpVcrUseVWAPCrossExit = "true"; InpVcrMaximumHoldBars = "24"
      InpSqStopBufferATR = "0.10"; InpSqMinimumStopATR = "0.25"; InpSqMaximumStopATR = "1.25"
      InpSqUseFixedTakeProfit = "true"; InpSqTakeProfitR = "1.50"; InpSqUseBreakEven = "true"
      InpSqBreakEvenTriggerR = "0.80"; InpSqBreakEvenLockR = "0.10"
      InpSqUseTrendFailureExit = "false"; InpSqMaximumHoldBars = "32"
      InpUseChandelierTrail = "false"; InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "20"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Dual_Regime_Portfolio_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_dual_regime_portfolio_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="m15drp_center"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_sq_only"; Vcr="false"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_vcr_only"; Vcr="true"; Sq="false"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_vcr140"; Vcr="true"; Sq="true"; VcrVol="1.40"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_vcr150"; Vcr="true"; Sq="true"; VcrVol="1.50"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_sqbreak6"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="6"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_sqbreak10"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="10"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_kc140"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.40"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_kc160"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.60"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_trend50"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="50"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_trend200"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="200"; SessionEnd="20"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_session18"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="18"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_session22"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="22"; MaxTrades="2" },
   [pscustomobject]@{ Name="m15drp_maxtrades3"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="true"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="3" },
   [pscustomobject]@{ Name="m15drp_noextreme"; Vcr="true"; Sq="true"; VcrVol="1.30"; VcrExtreme="8"; RequireExtreme="false"; SqBreak="8"; SqKC="1.50"; SqBars="3"; Trend="100"; SessionEnd="20"; MaxTrades="2" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"; $profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"; $sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new(); $runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0; $candidateRank = 0
$stopRule = "Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and at least two adjacent dual-engine profiles must pass before opening 2021-2026. Engine-only controls are diagnostic and cannot be promoted."
foreach($variant in $variants) {
   $candidateRank++; $inputs = New-BaseInputs
   foreach($pair in @(
      @("InpEnableVolumeClimax",$variant.Vcr), @("InpEnableVolatilitySqueeze",$variant.Sq),
      @("InpVcrMinimumVolumeRatio",$variant.VcrVol), @("InpVcrExtremeLookbackBars",$variant.VcrExtreme),
      @("InpVcrRequireFreshExtreme",$variant.RequireExtreme),
      @("InpSqBreakoutLookbackBars",$variant.SqBreak), @("InpSqKeltnerATRMultiplier",$variant.SqKC),
      @("InpSqSqueezeBars",$variant.SqBars), @("InpTrendEMAPeriod",$variant.Trend),
      @("InpSessionEndHour",$variant.SessionEnd), @("InpMaximumTradesPerDay",$variant.MaxTrades),
      @("InpEvidenceProfileId",$variant.Name),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","independent_m15_dual_regime_portfolio_discovery_model1"),
      @("InpLogFileName","$($variant.Name)_trades.csv")
   )) { Set-InputLine -Inputs $inputs -Name $pair[0] -Value $pair[1] }
   $profileName = "$($variant.Name).set"; $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $rank++; $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_dual_regime_portfolio"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"
         EnableVolumeClimax=$variant.Vcr; EnableVolatilitySqueeze=$variant.Sq
         VcrMinimumVolumeRatio=$variant.VcrVol; VcrExtremeLookbackBars=$variant.VcrExtreme
         VcrRequireFreshExtreme=$variant.RequireExtreme; SqBreakoutLookbackBars=$variant.SqBreak
         SqKeltnerATRMultiplier=$variant.SqKC; SqSqueezeBars=$variant.SqBars
         TrendEMAPeriod=$variant.Trend; SessionEndHour=$variant.SessionEnd
         MaximumTradesPerDay=$variant.MaxTrades; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 dual-regime portfolio discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 Dual-Regime Portfolio Discovery Package", "",
   "Date-independent portfolio combining a trend-phase volatility-squeeze continuation lane with a range-phase volume-climax VWAP-reversion lane. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$rank``", "",
   'The lanes share one position, daily-loss, drawdown, loss-streak, spread, and account-wide exposure manager. Lane-specific comments preserve lane-specific exits: VWAP-cross/mean-reversion management applies only to climax trades, while squeeze trades retain fixed-R/trend-failure management. Every stop rejects distances above `$6`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.', "",
   "Frozen gate: $stopRule"
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
