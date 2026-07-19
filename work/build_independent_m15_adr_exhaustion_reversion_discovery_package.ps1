param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_ADR_Exhaustion_Reversion.mq5",
   [string]$PackageDir = "outputs\independent_m15_adr_exhaustion_reversion_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071981"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "15"; InpADRLookbackDays = "20"; InpMinimumDayRangeADR = "0.85"
      InpMaximumDayRangeADR = "1.75"; InpMinimumDirectionalMoveADR = "0.55"
      InpVolumeLookbackBars = "24"; InpMinimumVolumeRatio = "0.90"
      InpExtremeLookbackBars = "8"; InpMinimumRangeATR = "0.45"; InpMaximumRangeATR = "2.50"
      InpMinimumWickPercent = "40.0"; InpMaximumBodyPercent = "60.0"; InpMinimumCloseLocation = "0.60"
      InpMinimumVWAPDeviationATR = "0.55"; InpMaximumVWAPDeviationATR = "3.00"
      InpMinimumRiskReward = "1.15"; InpMaximumTargetR = "1.80"
      InpAllowBuy = "true"; InpAllowSell = "true"; InpRequireFreshExtreme = "true"
      InpTrendTimeframe = "16385"; InpTrendEMAPeriod = "100"; InpADXPeriod = "14"
      InpUseRangePhaseFilter = "true"; InpMaximumADX = "32.0"; InpMaximumTrendDistanceATR = "3.00"
      InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"; InpMaximumATRPercent = "2.50"
      InpATRPeriod = "20"; InpStopBufferATR = "0.08"; InpMinimumStopATR = "0.20"
      InpMaximumStopATR = "1.50"; InpMaximumStopPriceDistance = "8.00"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "0.90"; InpBreakEvenLockR = "0.10"; InpUseChandelierTrail = "false"
      InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"; InpUseVWAPCrossExit = "true"; InpMaximumHoldBars = "24"
      InpUseSessionFilter = "true"; InpSessionStartHour = "6"; InpSessionEndHour = "20"
      InpDisableFridayAfterHour = "true"; InpFridayCutoffHour = "18"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "1"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpUseAccountWideExposureGuard = "true"; InpAccountWideMaxOpenRiskPercent = "3.00"
      InpAccountWideMaxPositions = "3"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_ADR_Exhaustion_Reversion_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_adr_exhaustion_reversion_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="aer_center"; ADR="0.85"; Move="0.55"; Vol="0.90"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_adr075"; ADR="0.75"; Move="0.55"; Vol="0.90"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_adr095"; ADR="0.95"; Move="0.55"; Vol="0.90"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_move045"; ADR="0.85"; Move="0.45"; Vol="0.90"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_move065"; ADR="0.85"; Move="0.65"; Vol="0.90"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_vol000"; ADR="0.85"; Move="0.55"; Vol="0.00"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_vol110"; ADR="0.85"; Move="0.55"; Vol="1.10"; ADX="32.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_adx28"; ADR="0.85"; Move="0.55"; Vol="0.90"; ADX="28.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_adx36"; ADR="0.85"; Move="0.55"; Vol="0.90"; ADX="36.0"; Wick="40.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_wick50"; ADR="0.85"; Move="0.55"; Vol="0.90"; ADX="32.0"; Wick="50.0"; RR="1.15" },
   [pscustomobject]@{ Name="aer_rr135"; ADR="0.85"; Move="0.55"; Vol="0.90"; ADX="32.0"; Wick="40.0"; RR="1.35" }
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
$stopRule = "Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 80, DD <= 3%, positive payoff and return/DD >= 1.0, with an adjacent one-factor shape passing before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++; $inputs = New-BaseInputs
   foreach($pair in @(
      @("InpMinimumDayRangeADR",$variant.ADR), @("InpMinimumDirectionalMoveADR",$variant.Move),
      @("InpMinimumVolumeRatio",$variant.Vol), @("InpMaximumADX",$variant.ADX),
      @("InpMinimumWickPercent",$variant.Wick), @("InpMinimumRiskReward",$variant.RR),
      @("InpEvidenceProfileId",$variant.Name),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","independent_m15_adr_exhaustion_reversion_discovery_model1"),
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
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_adr_exhaustion_reversion"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"
         MinimumDayRangeADR=$variant.ADR; MinimumDirectionalMoveADR=$variant.Move
         MinimumVolumeRatio=$variant.Vol; MaximumADX=$variant.ADX
         MinimumWickPercent=$variant.Wick; MinimumRiskReward=$variant.RR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 ADR-exhaustion reversion discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 ADR-Exhaustion Reversion Discovery Package", "",
   "Frozen pre-2021 screen of an intraday ADR-exhaustion and daily-VWAP reversion hypothesis. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$rank``", "",
   'The matrix changes one factor at a time around the center: day-range exhaustion, directional extension, volume confirmation, ADX ceiling, wick shape, or minimum payoff. The target is the pre-signal daily VWAP capped by R. Stops remain beyond the rejection wick, capped at `$8`, broker-sized at `0.10%` risk, with minimum-lot overflow refused and real-account trading disabled.', "",
   "Frozen gate: $stopRule"
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
