param(
   [string]$SourcePath = "work\Independent_XAUUSD_H4_Channel_Trend.mq5",
   [string]$PackageDir = "outputs\independent_h4_channel_trend_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071651"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "16388"; InpEntryLookbackBars = "55"; InpExitLookbackBars = "20"
      InpBreakoutBufferATR = "0.00"; InpAllowBuy = "true"; InpAllowSell = "true"; InpRequireFreshBreakout = "true"
      InpUseTrendEMAFilter = "false"; InpTrendTimeframe = "16408"; InpTrendEMAPeriod = "100"; InpTrendEMASlopeBars = "5"
      InpUseADXFilter = "false"; InpADXPeriod = "14"; InpMinimumADX = "16.0"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.20"; InpMaximumATRPercent = "5.00"
      InpATRPeriod = "20"; InpInitialStopATR = "2.00"; InpUseBreakEven = "false"
      InpBreakEvenTriggerR = "1.50"; InpBreakEvenLockR = "0.00"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "20"; InpChandelierATR = "3.00"; InpMaximumHoldBars = "0"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_H4_Channel_Trend_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_h4_channel_trend_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name = "h4ct_20_10_raw"; Timeframe = "16388"; Entry = "20"; Exit = "10"; EMA = "false"; ADX = "false"; Trail = "false" },
   [pscustomobject]@{ Name = "h4ct_40_20_raw"; Timeframe = "16388"; Entry = "40"; Exit = "20"; EMA = "false"; ADX = "false"; Trail = "false" },
   [pscustomobject]@{ Name = "h4ct_55_20_raw"; Timeframe = "16388"; Entry = "55"; Exit = "20"; EMA = "false"; ADX = "false"; Trail = "false" },
   [pscustomobject]@{ Name = "h4ct_80_40_raw"; Timeframe = "16388"; Entry = "80"; Exit = "40"; EMA = "false"; ADX = "false"; Trail = "false" },
   [pscustomobject]@{ Name = "h4ct_55_20_d1ema100"; Timeframe = "16388"; Entry = "55"; Exit = "20"; EMA = "true"; ADX = "false"; Trail = "false" },
   [pscustomobject]@{ Name = "h4ct_55_20_adx16"; Timeframe = "16388"; Entry = "55"; Exit = "20"; EMA = "false"; ADX = "true"; Trail = "false" },
   [pscustomobject]@{ Name = "h4ct_55_20_chandelier"; Timeframe = "16388"; Entry = "55"; Exit = "20"; EMA = "false"; ADX = "false"; Trail = "true" },
   [pscustomobject]@{ Name = "h1ct_80_40_raw"; Timeframe = "16385"; Entry = "80"; Exit = "40"; EMA = "false"; ADX = "false"; Trail = "false" }
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
$stopRule = "Discovery only: require both disjoint eras positive, continuous PF at least 1.20, at least 40 continuous trades, DD at or below 5%, and support from a neighboring channel shape before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value $variant.Timeframe
   Set-InputLine -Inputs $inputs -Name "InpEntryLookbackBars" -Value $variant.Entry
   Set-InputLine -Inputs $inputs -Name "InpExitLookbackBars" -Value $variant.Exit
   Set-InputLine -Inputs $inputs -Name "InpUseTrendEMAFilter" -Value $variant.EMA
   Set-InputLine -Inputs $inputs -Name "InpUseADXFilter" -Value $variant.ADX
   Set-InputLine -Inputs $inputs -Name "InpUseChandelierTrail" -Value $variant.Trail
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_h4_channel_trend_discovery_model1"
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
         SourceType = "independent_h4_channel_trend"; SourceRank = 1; Phase = "discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; SignalTimeframe = $variant.Timeframe
         EntryLookback = $variant.Entry; ExitLookback = $variant.Exit; EMAFilter = $variant.EMA
         ADXFilter = $variant.ADX; ChandelierTrail = $variant.Trail; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "discovery_model1"
         PhaseLabel = "Independent H4 channel trend discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent H4 Channel-Trend Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent research family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Every profile uses broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, one strategy position, a `3%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir }
