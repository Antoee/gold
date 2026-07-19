param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Overnight_Drift_Continuation.mq5",
   [string]$PackageDir = "outputs\independent_m15_overnight_drift_continuation_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_OVERNIGHT_DRIFT_CONTINUATION_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071991"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpEnforceInitialBalanceContract = "true"; InpExpectedInitialBalance = "10000.0"; InpInitialBalanceTolerance = "1.0"
      InpEnforceAccountCurrency = "true"; InpExpectedAccountCurrency = "USD"
      InpSignalTimeframe = "15"; InpATRTimeframe = "16408"; InpATRPeriod = "14"
      InpEntryHour = "7"; InpEntryWindowBars = "4"; InpExitHour = "17"
      InpMinimumPriorDayMoveATR = "0.30"; InpMaximumPriorDayMoveATR = "1.50"; InpMinimumPriorDayBodyPercent = "45.0"
      InpMinimumAsianRangeATR = "0.08"; InpMaximumAsianRangeATR = "0.55"
      InpMinimumAsianDriftATR = "-0.15"; InpMaximumAsianDriftATR = "0.35"; InpMinimumSignalBodyPercent = "35.0"
      InpRequireSignalDirection = "true"; InpRequireCloseBeyondAsianMidpoint = "true"; InpTradeFriday = "false"
      InpAllowBuy = "true"; InpAllowSell = "true"; InpStopBufferATR = "0.05"
      InpMinimumStopATR = "0.20"; InpMaximumStopATR = "0.60"; InpMaximumStopPriceDistance = "8.00"
      InpTakeProfitR = "1.50"; InpMaximumHoldBars = "48"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "1.00"; InpBreakEvenLockR = "0.10"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumDailyLossPercent = "0.75"
      InpMaximumEquityDrawdownPercent = "5.00"; InpMaximumConsecutiveLosses = "3"; InpLossCooldownHours = "72"
      InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"; InpRequireEmptyAccountAtEntry = "true"
      InpAccountWideMaxOpenRiskPercent = "1.00"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Overnight_Drift_Continuation_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_overnight_drift_continuation_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name="odc_center"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_prior020"; PriorMove="0.20"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_prior040"; PriorMove="0.40"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_priorbody35"; PriorMove="0.30"; PriorBody="35.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_priorbody55"; PriorMove="0.30"; PriorBody="55.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_asian045"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.45"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_asian065"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.65"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_drift000"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="0.00"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_driftminus025"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.25"; EntryHour="7"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_entry6"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="6"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_entry8"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="8"; SignalBody="35.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_signal25"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="25.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_signal45"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="45.0"; TPR="1.50" },
   [pscustomobject]@{ Name="odc_tp125"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.25" },
   [pscustomobject]@{ Name="odc_tp175"; PriorMove="0.30"; PriorBody="45.0"; AsianMax="0.55"; DriftMin="-0.15"; EntryHour="7"; SignalBody="35.0"; TPR="1.75" }
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
$ordinal = 0
$candidateRank = 0
$stopRule = "Discovery only: require both disjoint eras positive, continuous PF at least 1.20, at least 60 continuous trades, DD at or below 3%, positive payoff and return/DD at least 1.0, with an adjacent one-factor shape before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpMinimumPriorDayMoveATR" -Value $variant.PriorMove
   Set-InputLine -Inputs $inputs -Name "InpMinimumPriorDayBodyPercent" -Value $variant.PriorBody
   Set-InputLine -Inputs $inputs -Name "InpMaximumAsianRangeATR" -Value $variant.AsianMax
   Set-InputLine -Inputs $inputs -Name "InpMinimumAsianDriftATR" -Value $variant.DriftMin
   Set-InputLine -Inputs $inputs -Name "InpEntryHour" -Value $variant.EntryHour
   Set-InputLine -Inputs $inputs -Name "InpMinimumSignalBodyPercent" -Value $variant.SignalBody
   Set-InputLine -Inputs $inputs -Name "InpTakeProfitR" -Value $variant.TPR
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_overnight_drift_continuation_discovery_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $ordinal++
      $pairIndex = [int][math]::Floor(($ordinal - 1) / 2)
      $queueRank = 3 * $pairIndex + $(if(($ordinal % 2) -eq 1) { 1 } else { 3 })
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $ordinal, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $queueRows.Add([pscustomobject]@{
         QueueRank = $queueRank; Candidate = $variant.Name; CandidateRank = $candidateRank
         SourceType = "independent_m15_overnight_drift_continuation"; SourceRank = 1; Phase = "discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; SignalTimeframe = "15"
         PriorDayMoveATR = $variant.PriorMove; PriorDayBodyPercent = $variant.PriorBody
         MaximumAsianRangeATR = $variant.AsianMax; MinimumAsianDriftATR = $variant.DriftMin
         EntryHour = $variant.EntryHour; SignalBodyPercent = $variant.SignalBody
         TakeProfitR = $variant.TPR; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $queueRank; Candidate = $variant.Name; Phase = "discovery_model1"
         PhaseLabel = "Independent M15 overnight-drift continuation discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Overnight-Drift Continuation Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent research family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$ordinal``")
$md.Add("")
$md.Add('Every profile uses only completed prior-day and M15 bars, one trade per day during a fixed morning window, a fixed intraday exit, an Asian-range stop capped at `$8`, broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, a `$10,000` initial-balance contract, a `1%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled. Queue ranks intentionally route only to healthy portable workers 1 and 3.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $ordinal; PackageDir = $PackageDir }
