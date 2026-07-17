param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Volume_Climax_Reversal.mq5",
   [string]$PackageDir = "outputs\independent_m15_volume_climax_reversal_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071773"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpVolumeLookbackBars = "24"; InpMinimumVolumeRatio = "1.50"
      InpExtremeLookbackBars = "8"; InpMinimumRangeATR = "1.10"; InpMaximumRangeATR = "3.00"
      InpMinimumWickPercent = "45.0"; InpMaximumBodyPercent = "55.0"; InpMinimumCloseLocation = "0.55"
      InpMinimumVWAPDeviationATR = "0.45"; InpMaximumVWAPDeviationATR = "2.50"
      InpMinimumRiskReward = "1.10"; InpMaximumTargetR = "1.75"
      InpAllowBuy = "true"; InpAllowSell = "true"; InpRequireFreshExtreme = "true"
      InpTrendTimeframe = "16385"; InpTrendEMAPeriod = "100"; InpADXPeriod = "14"
      InpUseRangePhaseFilter = "true"; InpMaximumADX = "28.0"; InpMaximumTrendDistanceATR = "2.50"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopBufferATR = "0.08"; InpMinimumStopATR = "0.20"
      InpMaximumStopATR = "1.50"; InpMaximumStopPriceDistance = "6.00"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "0.90"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"; InpUseVWAPCrossExit = "true"; InpMaximumHoldBars = "24"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "20"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Volume_Climax_Reversal_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_volume_climax_reversal_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="m15vcr_center"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_vol130"; Vol="1.30"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_vol170"; Vol="1.70"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_range090"; Vol="1.50"; Range="0.90"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_range130"; Vol="1.50"; Range="1.30"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_wick35"; Vol="1.50"; Range="1.10"; Wick="35.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_wick55"; Vol="1.50"; Range="1.10"; Wick="55.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_dev030"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.30"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_dev060"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.60"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_adx22"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="22.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_adx34"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="34.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_ext4"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="4"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_ext12"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="12"; MinRR="1.10"; MaxR="1.75"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_rr125"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.25"; MaxR="2.00"; Phase="true" },
   [pscustomobject]@{ Name="m15vcr_nophase"; Vol="1.50"; Range="1.10"; Wick="45.0"; Dev="0.45"; ADX="28.0"; Extreme="8"; MinRR="1.10"; MaxR="1.75"; Phase="false" }
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
$stopRule = "Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and an adjacent volume/wick/VWAP/phase shape must pass before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++; $inputs = New-BaseInputs
   foreach($pair in @(
      @("InpMinimumVolumeRatio",$variant.Vol), @("InpMinimumRangeATR",$variant.Range),
      @("InpMinimumWickPercent",$variant.Wick), @("InpMinimumVWAPDeviationATR",$variant.Dev),
      @("InpMaximumADX",$variant.ADX), @("InpExtremeLookbackBars",$variant.Extreme),
      @("InpMinimumRiskReward",$variant.MinRR), @("InpMaximumTargetR",$variant.MaxR),
      @("InpUseRangePhaseFilter",$variant.Phase),
      @("InpEvidenceProfileId",$variant.Name),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","independent_m15_volume_climax_reversal_discovery_model1"),
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
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_volume_climax_reversal"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"
         MinimumVolumeRatio=$variant.Vol; MinimumRangeATR=$variant.Range; MinimumWickPercent=$variant.Wick
         MinimumVWAPDeviationATR=$variant.Dev; MaximumADX=$variant.ADX; ExtremeLookbackBars=$variant.Extreme
         MinimumRiskReward=$variant.MinRR; MaximumTargetR=$variant.MaxR; UseRangePhaseFilter=$variant.Phase; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 volume-climax reversal discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 Volume-Climax Reversal Discovery Package", "",
   "Standalone, date-independent exhaustion-reversion family. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$rank``", "",
   'Every profile requires an M15 tick-volume climax, ATR-sized range, rejection wick, fresh local extreme, and meaningful deviation from the day anchored VWAP. The center profile also avoids strongly trending H1 ADX/EMA-distance phases. The target is the pre-signal daily VWAP capped by R and is rejected below the minimum RR. The stop sits beyond the climax wick, rejects distances above `$6`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.', "",
   "Frozen gate: $stopRule"
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
