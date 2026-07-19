param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Inside_Day_Breakout.mq5",
   [string]$PackageDir = "outputs\independent_m15_inside_day_breakout_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071982"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpMinimumInsideRangeRatio = "0.25"; InpMaximumInsideRangeRatio = "0.75"
      InpBreakoutBufferATR = "0.05"; InpMinimumBodyPercent = "40.0"
      InpVolumeLookbackBars = "24"; InpMinimumVolumeRatio = "1.00"
      InpAllowBuy = "true"; InpAllowSell = "true"; InpRequireFreshBreakout = "true"
      InpUseTrendEMAFilter = "true"; InpTrendTimeframe = "16388"; InpTrendEMAPeriod = "100"; InpTrendEMASlopeBars = "3"
      InpUseADXFilter = "false"; InpADXTimeframe = "16385"; InpADXPeriod = "14"; InpMinimumADX = "16.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopLookbackBars = "3"; InpStopBufferATR = "0.10"
      InpMinimumStopATR = "0.35"; InpMaximumStopATR = "2.00"; InpMaximumStopPriceDistance = "8.00"
      InpUseFixedTakeProfit = "true"; InpTakeProfitR = "2.00"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "1.00"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "12"; InpChandelierATR = "2.50"; InpMaximumHoldBars = "64"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "18"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "1"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Inside_Day_Breakout_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_inside_day_breakout_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name="idb_center"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_ratio065"; MinRatio="0.25"; MaxRatio="0.65"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_ratio085"; MinRatio="0.25"; MaxRatio="0.85"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_minratio015"; MinRatio="0.15"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_buffer000"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.00"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_buffer010"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.10"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_body30"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="30.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_body50"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="50.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_vol000"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="0.00"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_vol115"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.15"; EMA="true"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_noema"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="false"; ADX="false"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_adx16"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="true"; TPR="2.00" },
   [pscustomobject]@{ Name="idb_tp150"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="1.50" },
   [pscustomobject]@{ Name="idb_tp250"; MinRatio="0.25"; MaxRatio="0.75"; Buffer="0.05"; Body="40.0"; Vol="1.00"; EMA="true"; ADX="false"; TPR="2.50" }
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
   Set-InputLine -Inputs $inputs -Name "InpMinimumInsideRangeRatio" -Value $variant.MinRatio
   Set-InputLine -Inputs $inputs -Name "InpMaximumInsideRangeRatio" -Value $variant.MaxRatio
   Set-InputLine -Inputs $inputs -Name "InpBreakoutBufferATR" -Value $variant.Buffer
   Set-InputLine -Inputs $inputs -Name "InpMinimumBodyPercent" -Value $variant.Body
   Set-InputLine -Inputs $inputs -Name "InpMinimumVolumeRatio" -Value $variant.Vol
   Set-InputLine -Inputs $inputs -Name "InpUseTrendEMAFilter" -Value $variant.EMA
   Set-InputLine -Inputs $inputs -Name "InpUseADXFilter" -Value $variant.ADX
   Set-InputLine -Inputs $inputs -Name "InpTakeProfitR" -Value $variant.TPR
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_inside_day_breakout_discovery_model1"
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
         SourceType = "independent_m15_inside_day_breakout"; SourceRank = 1; Phase = "discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; SignalTimeframe = "15"
         MinimumInsideRangeRatio = $variant.MinRatio; MaximumInsideRangeRatio = $variant.MaxRatio
         BreakoutBufferATR = $variant.Buffer; MinimumBodyPercent = $variant.Body
         MinimumVolumeRatio = $variant.Vol; EMAFilter = $variant.EMA; ADXFilter = $variant.ADX
         TakeProfitR = $variant.TPR; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $queueRank; Candidate = $variant.Name; Phase = "discovery_model1"
         PhaseLabel = "Independent M15 inside-day breakout discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Inside-Day Breakout Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent research family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$ordinal``")
$md.Add("")
$md.Add('Every profile reads only completed D1 compression bars, requires a fresh M15 break, uses a recent-M15 structure stop capped at `$8`, broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, one strategy position, a `3%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled. Queue ranks intentionally route only to the healthy portable workers 1 and 3.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $ordinal; PackageDir = $PackageDir }
