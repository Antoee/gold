param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_PrevDay_Sweep.mq5",
   [string]$PackageDir = "outputs\independent_m15_prevday_sweep_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_PACKAGE.md"
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
      if(!$resolved.StartsWith($outputsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071721"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpMinimumSweepATR = "0.05"; InpMinimumSweepPoints = "10.0"
      InpMaximumSweepATR = "1.25"; InpMinimumReclaimATR = "0.00"; InpMinimumWickToBodyRatio = "1.00"
      InpMinimumBodyPercent = "10.0"; InpMinimumCloseLocation = "0.60"; InpRequireDirectionCandle = "true"
      InpRequireFreshSweep = "true"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpUseTickVolumeFilter = "false"; InpVolumeLookbackBars = "20"; InpMinimumVolumeRatio = "1.10"
      InpUseTrendEMAFilter = "false"; InpTrendTimeframe = "16385"; InpTrendEMAPeriod = "100"
      InpTrendEMASlopeBars = "3"; InpRequireTrendAlignment = "true"; InpUseMaximumADXFilter = "false"
      InpADXPeriod = "14"; InpMaximumADX = "28.0"; InpUseVolatilityFilter = "true"
      InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"; InpATRPeriod = "20"
      InpStopBufferATR = "0.10"; InpMinimumStopATR = "0.25"; InpMaximumStopATR = "2.00"
      InpMaximumStopPriceDistance = "10.00"; InpUseFixedTakeProfit = "true"; InpTakeProfitR = "1.50"
      InpUsePreviousDayMidpointTarget = "false"; InpMinimumMidpointTargetR = "1.00"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "0.80"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"; InpUseTrendFailureExit = "false"
      InpMaximumHoldBars = "32"; InpUseSessionFilter = "true"; InpSessionStartHour = "6"
      InpSessionEndHour = "18"; InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"
      InpDeviationPoints = "20"; InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_PrevDay_Sweep_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_prevday_sweep_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name = "pds_base"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_wick15"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.50"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_sweep10"; Sweep = "0.10"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_reclaim05"; Sweep = "0.05"; Reclaim = "0.05"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_volume105"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "true"; VolumeRatio = "1.05"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_trend"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "true"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_adx24"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "true"; MaxAdx = "24.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_rr20"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "2.00"; Midpoint = "false"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_midpoint"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "true"; SessionStart = "6"; SessionEnd = "18" },
   [pscustomobject]@{ Name = "pds_session12_22"; Sweep = "0.05"; Reclaim = "0.00"; Wick = "1.00"; Volume = "false"; VolumeRatio = "1.10"; Trend = "false"; MaxAdxFilter = "false"; MaxAdx = "28.0"; TPR = "1.50"; Midpoint = "false"; SessionStart = "12"; SessionEnd = "22" }
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
$stopRule = "Discovery only through 2020: require both disjoint eras positive, continuous PF at least 1.20, at least 60 continuous trades, DD at or below 5%, and support from neighboring sweep/rejection/payoff shapes before opening 2021-2026."

foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpMinimumSweepATR" -Value $variant.Sweep
   Set-InputLine -Inputs $inputs -Name "InpMinimumReclaimATR" -Value $variant.Reclaim
   Set-InputLine -Inputs $inputs -Name "InpMinimumWickToBodyRatio" -Value $variant.Wick
   Set-InputLine -Inputs $inputs -Name "InpUseTickVolumeFilter" -Value $variant.Volume
   Set-InputLine -Inputs $inputs -Name "InpMinimumVolumeRatio" -Value $variant.VolumeRatio
   Set-InputLine -Inputs $inputs -Name "InpUseTrendEMAFilter" -Value $variant.Trend
   Set-InputLine -Inputs $inputs -Name "InpUseMaximumADXFilter" -Value $variant.MaxAdxFilter
   Set-InputLine -Inputs $inputs -Name "InpMaximumADX" -Value $variant.MaxAdx
   Set-InputLine -Inputs $inputs -Name "InpTakeProfitR" -Value $variant.TPR
   Set-InputLine -Inputs $inputs -Name "InpUsePreviousDayMidpointTarget" -Value $variant.Midpoint
   Set-InputLine -Inputs $inputs -Name "InpSessionStartHour" -Value $variant.SessionStart
   Set-InputLine -Inputs $inputs -Name "InpSessionEndHour" -Value $variant.SessionEnd
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_prevday_sweep_discovery_model1"
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
         SourceType = "independent_m15_prevday_sweep"; SourceRank = 1; Phase = "discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; SignalTimeframe = "15"
         MinimumSweepATR = $variant.Sweep; MinimumReclaimATR = $variant.Reclaim; WickToBodyRatio = $variant.Wick
         UseTickVolumeFilter = $variant.Volume; MinimumVolumeRatio = $variant.VolumeRatio
         UseTrendEMAFilter = $variant.Trend; UseMaximumADXFilter = $variant.MaxAdxFilter; MaximumADX = $variant.MaxAdx
         TakeProfitR = $variant.TPR; UsePreviousDayMidpointTarget = $variant.Midpoint
         SessionStartHour = $variant.SessionStart; SessionEndHour = $variant.SessionEnd; StopRule = $stopRule
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "discovery_model1"
         PhaseLabel = "Independent M15 previous-day sweep discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M15 Previous-Day Liquidity Sweep Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent research family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Every profile requires a fresh M15 sweep and reclaim of the previous D1 high or low, uses a structure stop beyond the sweep wick, rejects stop distances above `$10`, sizes with broker-accurate `OrderCalcProfit` at `0.10%` risk, and keeps real-account trading disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status = "READY"
   SourceHash = $sourceHash
   Variants = $variants.Count
   Windows = $windows.Count
   Configurations = $rank
   PackageDir = $PackageDir
}
