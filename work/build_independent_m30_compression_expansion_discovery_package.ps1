param(
   [string]$SourcePath = "work\Independent_XAUUSD_M30_Compression_Expansion.mq5",
   [string]$PackageDir = "outputs\independent_m30_compression_expansion_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071771"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "30"; InpBoxLookbackBars = "10"; InpMinimumBoxRangeATR = "0.40"
      InpMaximumBoxRangeATR = "1.80"; InpMaximumAverageBoxBarRangeATR = "0.45"
      InpBreakBufferATR = "0.03"; InpMinimumBreakRangeATR = "0.45"; InpMaximumBreakRangeATR = "1.80"
      InpMinimumExpansionRatio = "1.40"; InpMinimumBreakBodyPercent = "35.0"; InpMinimumBreakCloseLocation = "0.65"
      InpRequireDirectionCandle = "true"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpUseBreakoutTickVolumeFilter = "false"; InpVolumeLookbackBars = "20"; InpMinimumVolumeRatio = "1.05"
      InpUseTrendEMAFilter = "false"; InpTrendTimeframe = "16385"; InpTrendEMAPeriod = "100"
      InpTrendEMASlopeBars = "3"; InpRequireTrendAlignment = "true"
      InpUseADXFilter = "false"; InpADXPeriod = "14"; InpMinimumADX = "14.0"; InpMaximumADX = "45.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopBufferATR = "0.10"; InpMinimumStopATR = "0.25"
      InpMaximumStopATR = "1.50"; InpMaximumStopPriceDistance = "8.00"
      InpUseFixedTakeProfit = "true"; InpTakeProfitR = "1.75"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "0.80"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"; InpUseTrendFailureExit = "false"; InpMaximumHoldBars = "24"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "18"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M30_Compression_Expansion_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m30_compression_expansion_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="m30ce_center"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_box8"; Box="8"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_box12"; Box="12"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_boxmax150"; Box="10"; BoxMax="1.50"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_boxmax210"; Box="10"; BoxMax="2.10"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_avg035"; Box="10"; BoxMax="1.80"; AvgMax="0.35"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_avg055"; Box="10"; BoxMax="1.80"; AvgMax="0.55"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_exp120"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.20"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_exp160"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.60"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_body45"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="45.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_tp150"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.50"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_tp200"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="2.00"; Volume="false"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_volume105"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="true"; Trend="false"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_h1trend"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="true"; ADX="false" },
   [pscustomobject]@{ Name="m30ce_adx14"; Box="10"; BoxMax="1.80"; AvgMax="0.45"; Expansion="1.40"; Body="35.0"; TPR="1.75"; Volume="false"; Trend="false"; ADX="true" }
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
$stopRule = "Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 100, DD <= 5%, and an adjacent compression/payoff shape must pass before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++; $inputs = New-BaseInputs
   foreach($pair in @(
      @("InpBoxLookbackBars",$variant.Box), @("InpMaximumBoxRangeATR",$variant.BoxMax),
      @("InpMaximumAverageBoxBarRangeATR",$variant.AvgMax), @("InpMinimumExpansionRatio",$variant.Expansion),
      @("InpMinimumBreakBodyPercent",$variant.Body), @("InpTakeProfitR",$variant.TPR),
      @("InpUseBreakoutTickVolumeFilter",$variant.Volume), @("InpUseTrendEMAFilter",$variant.Trend),
      @("InpUseADXFilter",$variant.ADX), @("InpEvidenceProfileId",$variant.Name),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","independent_m30_compression_expansion_discovery_model1"),
      @("InpLogFileName","$($variant.Name)_trades.csv")
   )) { Set-InputLine -Inputs $inputs -Name $pair[0] -Value $pair[1] }
   $profileName = "$($variant.Name).set"; $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $rank++; $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 30
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m30_compression_expansion"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="30"; BoxLookbackBars=$variant.Box
         MaximumBoxRangeATR=$variant.BoxMax; MaximumAverageBoxBarRangeATR=$variant.AvgMax; MinimumExpansionRatio=$variant.Expansion
         MinimumBreakBodyPercent=$variant.Body; TakeProfitR=$variant.TPR; UseVolume=$variant.Volume; UseTrend=$variant.Trend
         UseADX=$variant.ADX; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M30 compression-expansion discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M30 Compression-Expansion Discovery Package", "",
   "Standalone, date-independent continuation family. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$rank``", "",
   'Every profile requires a bounded M30 compression box followed by a closed expansion candle outside the box. OHLC range, body, close location, and expansion ratio define the signal; tick volume, H1 EMA alignment, and bounded ADX are isolated variants. The stop sits beyond the breakout candle, rejects distances above `$8`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.', "",
   "Frozen gate: $stopRule"
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
