param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Trend_Pullback.mq5",
   [string]$PackageDir = "outputs\independent_m15_trend_pullback_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071761"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpPullbackEMAPeriod = "20"; InpPullbackLookbackBars = "3"
      InpPullbackTouchToleranceATR = "0.10"; InpMaximumCloseDistanceATR = "0.75"
      InpMinimumPriorImpulseATR = "0.60"; InpPriorImpulseLookbackBars = "8"
      InpMinimumSignalRangeATR = "0.35"; InpMaximumSignalRangeATR = "1.80"
      InpMinimumSignalBodyPercent = "35.0"; InpMinimumSignalCloseLocation = "0.65"
      InpMinimumRejectionWickPercent = "15.0"; InpRequirePreviousHighLowBreak = "true"
      InpAllowBuy = "true"; InpAllowSell = "true"; InpUseSignalVolumeFilter = "false"
      InpVolumeLookbackBars = "20"; InpMinimumSignalVolumeRatio = "1.05"
      InpTrendTimeframe = "16385"; InpTrendFastEMAPeriod = "50"; InpTrendSlowEMAPeriod = "200"
      InpTrendSlopeBars = "3"; InpMinimumTrendSeparationATR = "0.15"
      InpUseADXFilter = "true"; InpADXPeriod = "14"; InpMinimumADX = "18.0"; InpMaximumADX = "45.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopBufferATR = "0.10"; InpMinimumStopATR = "0.25"
      InpMaximumStopATR = "1.50"; InpMaximumStopPriceDistance = "8.00"
      InpUseFixedTakeProfit = "true"; InpTakeProfitR = "1.75"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "0.90"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"; InpUseTrendFailureExit = "false"; InpMaximumHoldBars = "32"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "18"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Trend_Pullback_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_trend_pullback_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name = "m15tpb_center"; PullbackEMA = "20"; PullbackBars = "3"; MinimumADX = "18.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_ema15"; PullbackEMA = "15"; PullbackBars = "3"; MinimumADX = "18.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_ema30"; PullbackEMA = "30"; PullbackBars = "3"; MinimumADX = "18.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_pb2"; PullbackEMA = "20"; PullbackBars = "2"; MinimumADX = "18.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_pb4"; PullbackEMA = "20"; PullbackBars = "4"; MinimumADX = "18.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_adx14"; PullbackEMA = "20"; PullbackBars = "3"; MinimumADX = "14.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_adx22"; PullbackEMA = "20"; PullbackBars = "3"; MinimumADX = "22.0"; TPR = "1.75"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_tp150"; PullbackEMA = "20"; PullbackBars = "3"; MinimumADX = "18.0"; TPR = "1.50"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_tp200"; PullbackEMA = "20"; PullbackBars = "3"; MinimumADX = "18.0"; TPR = "2.00"; UseVolume = "false" },
   [pscustomobject]@{ Name = "m15tpb_volume105"; PullbackEMA = "20"; PullbackBars = "3"; MinimumADX = "18.0"; TPR = "1.75"; UseVolume = "true" }
)
$windows = @(
   [pscustomobject]@{ Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Name = "discovery_2019_2020"; From = "2019.01.01"; To = "2020.12.31" },
   [pscustomobject]@{ Name = "continuous_2015_2020"; From = "2015.01.01"; To = "2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "Discovery only: require both disjoint eras positive, continuous PF at least 1.20, at least 120 continuous trades, DD at or below 5%, and support from an adjacent EMA/pullback/ADX/payoff shape before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpPullbackEMAPeriod" -Value $variant.PullbackEMA
   Set-InputLine -Inputs $inputs -Name "InpPullbackLookbackBars" -Value $variant.PullbackBars
   Set-InputLine -Inputs $inputs -Name "InpMinimumADX" -Value $variant.MinimumADX
   Set-InputLine -Inputs $inputs -Name "InpTakeProfitR" -Value $variant.TPR
   Set-InputLine -Inputs $inputs -Name "InpUseSignalVolumeFilter" -Value $variant.UseVolume
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_trend_pullback_discovery_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; CandidateRank = $candidateRank
         SourceType = "independent_m15_trend_pullback"; SourceRank = 1; Phase = "discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; SignalTimeframe = "15"
         PullbackEMAPeriod = $variant.PullbackEMA; PullbackLookbackBars = $variant.PullbackBars
         MinimumADX = $variant.MinimumADX; TakeProfitR = $variant.TPR
         UseSignalVolumeFilter = $variant.UseVolume; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "discovery_model1"
         PhaseLabel = "Independent M15 trend-pullback continuation discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Trend-Pullback Continuation Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent research family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Every profile requires an aligned and rising/falling H1 50/200 EMA regime, bounded H1 ADX, a prior M15 impulse, an M15 EMA pullback, and a directional rejection candle confirmed by OHLC body, wick, close-location, and optional tick volume. Stops sit behind the pullback structure, reject distances above `$8`, use broker-accurate `OrderCalcProfit` sizing at `0.10%` risk, and keep real-account trading disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir }
