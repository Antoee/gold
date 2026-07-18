param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Trend_Liquidity_Reclaim.mq5",
   [string]$PackageDir = "outputs\independent_m15_trend_liquidity_reclaim_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path

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

function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071941"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpLiquidityLookbackBars = "12"; InpMinimumSweepATR = "0.05"
      InpMinimumSweepPoints = "20.0"; InpMaximumSweepATR = "0.75"; InpMinimumReclaimATR = "0.02"
      InpMinimumWickToBodyRatio = "0.50"; InpMinimumBodyPercent = "20.0"; InpMinimumCloseLocation = "0.60"
      InpRequireDirectionCandle = "true"; InpRequireFreshSweep = "true"; InpAllowBuy = "true"
      InpAllowSell = "true"; InpUseTickVolumeFilter = "false"; InpVolumeLookbackBars = "20"
      InpMinimumVolumeRatio = "1.10"; InpUseTrendEMAFilter = "true"; InpTrendTimeframe = "16385"
      InpTrendEMAPeriod = "200"; InpTrendEMASlopeBars = "4"; InpRequireTrendAlignment = "true"
      InpUseMinimumADXFilter = "true"; InpADXPeriod = "14"; InpMinimumADX = "20.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopBufferATR = "0.18"; InpMinimumStopATR = "0.40"
      InpMaximumStopATR = "5.00"; InpMaximumStopPriceDistance = "10.00"; InpUseFixedTakeProfit = "true"
      InpTakeProfitR = "2.00"; InpUseBreakEven = "true"; InpBreakEvenTriggerR = "0.80"
      InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"; InpChandelierLookbackBars = "8"
      InpChandelierATR = "2.50"; InpUseTrendFailureExit = "false"; InpMaximumHoldBars = "32"
      InpUseSessionFilter = "true"; InpEntryStartHour = "9"; InpEntryEndHour = "11"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"; InpRiskPercent = "0.10"
      InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"; InpMaximumTradesPerDay = "1"
      InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpUsePostLossQuarantine = "true"
      InpPostLossQuarantineDays = "14"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Trend_Liquidity_Reclaim_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_trend_liquidity_reclaim_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name="tlr_control_q0"; Lookback="12"; Body="20.0"; UseQ="false"; QDays="0"; Role="control" },
   [pscustomobject]@{ Name="tlr_center_q14"; Lookback="12"; Body="20.0"; UseQ="true"; QDays="14"; Role="center" },
   [pscustomobject]@{ Name="tlr_q07"; Lookback="12"; Body="20.0"; UseQ="true"; QDays="7"; Role="quarantine_neighbor" },
   [pscustomobject]@{ Name="tlr_q21"; Lookback="12"; Body="20.0"; UseQ="true"; QDays="21"; Role="quarantine_neighbor" },
   [pscustomobject]@{ Name="tlr_body30"; Lookback="12"; Body="30.0"; UseQ="true"; QDays="14"; Role="structural_neighbor" },
   [pscustomobject]@{ Name="tlr_lookback08"; Lookback="8"; Body="20.0"; UseQ="true"; QDays="14"; Role="structural_neighbor" },
   [pscustomobject]@{ Name="tlr_lookback20"; Lookback="20"; Body="20.0"; UseQ="true"; QDays="14"; Role="structural_neighbor" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="repair_2019"; From="2019.01.01"; To="2019.12.31" },
   [pscustomobject]@{ Name="repair_2020"; From="2020.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new()
$manifestRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$runLabel = "trend_liquidity_reclaim_discovery_model1"
$stopRule = "Pre-2021 only: the 14-day center, a quarantine neighbor, and a body/lookback neighbor must pass exact identity, era, PF, activity, DD, payoff, and return-efficiency gates before recent data opens."

foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpLiquidityLookbackBars" -Value $variant.Lookback
   Set-InputLine -Inputs $inputs -Name "InpMinimumBodyPercent" -Value $variant.Body
   Set-InputLine -Inputs $inputs -Name "InpUsePostLossQuarantine" -Value $variant.UseQ
   Set-InputLine -Inputs $inputs -Name "InpPostLossQuarantineDays" -Value $variant.QDays
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value $runLabel
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($variant.Name)_trades.csv"

   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         SourceType="independent_m15_trend_liquidity_reclaim";Phase="discovery_model1"
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         Config="configs\$configName";ExpectedReportName=$reportName;ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;RunLabel=$runLabel
         LiquidityLookbackBars=$variant.Lookback;MinimumBodyPercent=$variant.Body
         UsePostLossQuarantine=$variant.UseQ;PostLossQuarantineDays=$variant.QDays
         RiskPercent="0.10";EntryStartHour="9";EntryEndHour="11";StopRule=$stopRule
      }) | Out-Null
      $manifestRows.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;Phase="discovery_model1";Window=$window.Name
         Model=1;Deposit=10000;PackageConfig="$PackageDir\configs\$configName"
         ReportDestination="$PackageDir\reports_here\$reportName";ExpectedReportName=$reportName
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;RunLabel=$runLabel;StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   '# Trend-Liquidity Reclaim Discovery Package','',
   'Frozen standalone research family. No configuration includes data after 2020.','',
   "- Source SHA-256: ``$sourceHash``",
   "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``",
   "- Configurations: ``$rank``",
   '- Risk per trade: `0.10%`','- Real-account trading default: `false`','',
   'The package is a fast rejection screen. Passing Model 1 permits frozen holdout testing only; it is not evidence of money readiness.'
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{Status='READY';SourceHash=$sourceHash;Variants=$variants.Count;Windows=$windows.Count;Configurations=$rank;PackageDir=$PackageDir}
