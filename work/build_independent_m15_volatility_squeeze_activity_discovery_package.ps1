param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Volatility_Squeeze.mq5",
   [string]$PackageDir = "outputs\independent_m15_volatility_squeeze_activity_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071772"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpSqueezeBars = "3"; InpBollingerPeriod = "20"; InpBollingerDeviation = "2.00"
      InpKeltnerEMAPeriod = "20"; InpKeltnerATRMultiplier = "1.50"; InpBreakoutLookbackBars = "12"
      InpMaximumBreakoutChannelATR = "3.50"; InpBreakBufferATR = "0.03"
      InpMinimumBreakRangeATR = "0.40"; InpMaximumBreakRangeATR = "1.60"
      InpMinimumExpansionRatio = "1.10"; InpMinimumBreakBodyPercent = "35.0"; InpMinimumBreakCloseLocation = "0.65"
      InpRequireDirectionCandle = "true"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpUseBreakoutTickVolumeFilter = "false"; InpVolumeLookbackBars = "20"; InpMinimumVolumeRatio = "1.05"
      InpUseTrendEMAFilter = "true"; InpTrendTimeframe = "16385"; InpTrendEMAPeriod = "100"
      InpTrendEMASlopeBars = "3"; InpRequireTrendAlignment = "true"
      InpUseADXFilter = "false"; InpADXPeriod = "14"; InpMinimumADX = "14.0"; InpMaximumADX = "45.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopBufferATR = "0.10"; InpMinimumStopATR = "0.25"
      InpMaximumStopATR = "1.25"; InpMaximumStopPriceDistance = "6.00"
      InpUseFixedTakeProfit = "true"; InpTakeProfitR = "1.50"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "0.80"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"; InpUseTrendFailureExit = "false"; InpMaximumHoldBars = "32"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "18"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Volatility_Squeeze_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_volatility_squeeze_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="m15sqa_center_b6"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_b4"; Squeeze="3"; KC="1.50"; Breakout="4"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_b8"; Squeeze="3"; KC="1.50"; Breakout="8"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_b10"; Squeeze="3"; KC="1.50"; Breakout="10"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_sq2"; Squeeze="2"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_sq4"; Squeeze="4"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_kc140"; Squeeze="3"; KC="1.40"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_kc160"; Squeeze="3"; KC="1.60"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_kc170"; Squeeze="3"; KC="1.70"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_exp090"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="0.90"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_exp100"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.00"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_exp120"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.20"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_trend50"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="50"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_trend200"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="200"; Start="6"; End="18" },
   [pscustomobject]@{ Name="m15sqa_session420"; Squeeze="3"; KC="1.50"; Breakout="6"; Channel="3.50"; Expansion="1.10"; TPR="1.50"; Trend="true"; TrendEMA="100"; Start="4"; End="20" }
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
$stopRule = "Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and an adjacent squeeze/breakout/payoff shape must pass before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++; $inputs = New-BaseInputs
   foreach($pair in @(
      @("InpSqueezeBars",$variant.Squeeze), @("InpKeltnerATRMultiplier",$variant.KC),
      @("InpBreakoutLookbackBars",$variant.Breakout), @("InpMaximumBreakoutChannelATR",$variant.Channel),
      @("InpMinimumExpansionRatio",$variant.Expansion), @("InpTakeProfitR",$variant.TPR),
      @("InpUseTrendEMAFilter",$variant.Trend), @("InpTrendEMAPeriod",$variant.TrendEMA),
      @("InpSessionStartHour",$variant.Start), @("InpSessionEndHour",$variant.End),
      @("InpEvidenceProfileId",$variant.Name),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","independent_m15_volatility_squeeze_activity_discovery_model1"),
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
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_volatility_squeeze_activity"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"; SqueezeBars=$variant.Squeeze
         KeltnerATRMultiplier=$variant.KC; BreakoutLookbackBars=$variant.Breakout
         MaximumBreakoutChannelATR=$variant.Channel; MinimumExpansionRatio=$variant.Expansion
         TakeProfitR=$variant.TPR; UseTrend=$variant.Trend; TrendEMAPeriod=$variant.TrendEMA
         SessionStartHour=$variant.Start; SessionEndHour=$variant.End; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 volatility-squeeze activity discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 Volatility-Squeeze Activity Discovery Package", "",
   "Second-stage, pre-holdout activity neighborhood. The source is unchanged and no configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$rank``", "",
   'Every profile requires consecutive M15 Bollinger bands inside a Keltner channel, followed by a closed fresh channel breakout with OHLC range, body, close-location, and expansion confirmation. H1 EMA alignment is the center regime; squeeze duration, Keltner width, breakout lookback, channel width, payoff, and trend length are isolated neighbors. The stop sits beyond the breakout candle, rejects distances above `$6`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.', "",
   "Frozen gate: $stopRule"
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
