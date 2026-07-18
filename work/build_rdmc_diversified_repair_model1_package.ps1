param(
   [string]$SourcePath = "outputs\rdmc_diversified_repair_model1_package\source\Professional_XAUUSD_EA.mq5",
   [string]$R20SourcePath = "outputs\peak_r20_regime_combo_model4_yearly_package\source\Professional_XAUUSD_EA.mq5",
   [string]$R20ProfilePath = "outputs\peak_r20_regime_combo_model4_yearly_package\profiles\r10_pg40_atr085_adapt7.set",
   [string]$ThreeLaneSourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5",
   [string]$ThreeLaneProfilePath = "outputs\three_lane_ddb045_model4_validation_package\profiles\three_lane_ddb045.set",
   [string]$OutputDirectory = "outputs\rdmc_diversified_repair_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$source = Resolve-RepoPath $SourcePath
$r20Source = Resolve-RepoPath $R20SourcePath
$r20Profile = Resolve-RepoPath $R20ProfilePath
$threeLaneSource = Resolve-RepoPath $ThreeLaneSourcePath
$threeLaneProfile = Resolve-RepoPath $ThreeLaneProfilePath
$out = Resolve-RepoPath $OutputDirectory
foreach($required in @($source, $r20Source, $r20Profile, $threeLaneSource, $threeLaneProfile)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) {
      throw "Required package input is missing: $required"
   }
}

$expectedThreeLaneSourceHash = "45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90"
$expectedR20SourceHash = "2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D"
$expectedR20ProfileHash = "3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC"
$expectedThreeLaneProfileHash = "2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312"

if((Get-FileHash -LiteralPath $r20Source -Algorithm SHA256).Hash -ne $expectedR20SourceHash) {
   throw "Frozen R20 evidence source identity changed."
}
if((Get-FileHash -LiteralPath $r20Profile -Algorithm SHA256).Hash -ne $expectedR20ProfileHash) {
   throw "Frozen R20 profile identity changed."
}
if((Get-FileHash -LiteralPath $threeLaneSource -Algorithm SHA256).Hash -ne $expectedThreeLaneSourceHash) {
   throw "Frozen three-lane base source identity changed."
}
if((Get-FileHash -LiteralPath $threeLaneProfile -Algorithm SHA256).Hash -ne $expectedThreeLaneProfileHash) {
   throw "Frozen three-lane profile identity changed."
}

$sourceText = Get-Content -LiteralPath $source -Raw
$sourceInputs = @{}
foreach($match in [regex]::Matches($sourceText, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=')) {
   $sourceInputs[$match.Groups[1].Value] = $true
}
if($sourceInputs.Count -lt 550) {
   throw "Unexpected diversified source input count: $($sourceInputs.Count)"
}

function Read-SetProfile([string]$Path) {
   $values = [ordered]@{}
   $suffixes = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^([^;=]+)=([^|]*)(.*)$') { continue }
      $key = $matches[1]
      if(!$sourceInputs.ContainsKey($key)) { continue }
      $values[$key] = $matches[2]
      $suffixes[$key] = $matches[3]
   }
   return [pscustomobject]@{ Values = $values; Suffixes = $suffixes }
}

$three = Read-SetProfile $threeLaneProfile
$r20 = Read-SetProfile $r20Profile
$profileValues = [ordered]@{}
$profileSuffixes = @{}
foreach($key in $three.Values.Keys) {
   $profileValues[$key] = $three.Values[$key]
   $profileSuffixes[$key] = $three.Suffixes[$key]
}
foreach($key in $r20.Values.Keys) {
   if(!$profileValues.Contains($key)) { $profileValues[$key] = $r20.Values[$key] }
   else { $profileValues[$key] = $r20.Values[$key] }
   $profileSuffixes[$key] = $r20.Suffixes[$key]
}

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$overrides = [ordered]@{
   InpAllowedSymbol = "XAUUSD"
   InpUseSymbolSafetyLock = "true"
   InpUseResearchTesterOnlyLock = "true"
   InpUseInitialBalanceContract = "true"
   InpExpectedInitialBalance = "10000.0"
   InpInitialBalanceTolerancePercent = "1.0"
   InpUseAccountCurrencyLock = "true"
   InpRequiredAccountCurrency = "USD"
   InpMagicNumber = "26071830"
   InpUseRealAccountSafetyLock = "true"
   InpAllowRealAccountTrading = "false"
   InpRealAccountApprovalCode = ""
   InpRealAccountApprovalProfileId = ""
   InpRealAccountApprovalSourceHash = ""
   InpUseTradeReadinessSafetyGate = "false"
   InpUseTradeEnvironmentGuard = "true"
   InpRiskPercent = "0.50"
   InpPrimaryLaneRiskMultiplier = "0.20"
   InpMaxEffectiveRiskPercent = "0.50"
   InpMaxPositionLots = "0.10"
   InpAllowMinLotRiskOverflow = "false"
   InpMaxOpenRiskPercent = "0.75"
   InpBlockUnprotectedExposure = "true"
   InpUseAccountWideExposureGuard = "true"
   InpAccountWideMaxOpenRiskPercent = "0.75"
   InpAccountWideMaxPositions = "1"
   InpAccountWideBlockUnprotectedExposure = "true"
   InpMaxSimultaneousPositions = "1"
   InpMaxTradesPerDay = "4"
   InpMinMinutesBetweenTrades = "30"
   InpMaxDailyLossPercent = "0.75"
   InpMaxWeeklyLossPercent = "1.25"
   InpMaxMonthlyLossPercent = "1.50"
   InpMaxEquityDrawdownPercent = "5.00"
   InpClosePositionsOnRiskLimit = "true"
   InpMaxConsecutiveLosses = "4"
   InpUseDrawdownRiskReduction = "true"
   InpDrawdownRiskReductionStartPercent = "1.50"
   InpDrawdownRiskReductionFullPercent = "5.00"
   InpDrawdownRiskReductionMaxFactor = "0.50"
   InpUseDailyLossRiskScaling = "true"
   InpUseWeeklyLossRiskScaling = "true"
   InpUseMonthlyLossRiskScaling = "true"
   InpMaxSpreadPoints = "220"
   InpMaxSpreadATRPercent = "12.0"
   InpUseSpreadRegimeGuard = "true"
   InpUseM1SpreadShockGuard = "true"
   InpUseSpreadRiskScaling = "true"
   InpDeviationPoints = "25"
   InpUseTradingCostGuard = "true"
   InpUseMarginGuard = "true"
   InpUseMarginAwareLotCap = "true"
   InpUseMarginPressureRiskScaling = "true"
   InpUseTradeMarginRiskScaling = "true"
   InpUseAdaptiveReverse = "false"
   InpUseWinnerScaleIn = "false"
   InpUseHouseMoneyScaleInRiskRamp = "false"
   InpUseProfitOnlyRiskBoost = "false"
   InpUseClosedProfitOpportunityRiskBoost = "false"
   InpUseHouseMoneyAccelerationGate = "false"
   InpUseHouseMoneyOpenRiskExpansion = "false"
   InpUseHotStreakRiskBoost = "false"
   InpUseRecentProfitFactorRiskBoost = "false"
   InpUseProtectedCushionRiskBoost = "false"
   InpUseBandVWAPReversionLane = "true"
   InpBandVWAPReversionBypassPrimarySession = "true"
   InpBandVWAPReversionUseIsolatedExecution = "true"
   InpBandVWAPReversionTimeframe = "16385"
   InpBandVWAPReversionATRPeriod = "14"
   InpBandVWAPReversionADXPeriod = "14"
   InpBandVWAPReversionRSIPeriod = "14"
   InpBandVWAPReversionBollingerPeriod = "20"
   InpBandVWAPReversionBollingerDeviation = "2.0"
   InpBandVWAPReversionVWAPLookbackBars = "48"
   InpBandVWAPReversionRiskMultiplier = "0.90"
   InpBandVWAPReversionMaxMonthlyEntries = "16"
   InpBandVWAPReversionSpacingMinutes = "240"
   InpBandVWAPReversionMaxADX = "22.0"
   InpBandVWAPReversionBuyMaxRSI = "40.0"
   InpBandVWAPReversionSellMinRSI = "60.0"
   InpBandVWAPReversionMinBandPenetrationATR = "0.0"
   InpBandVWAPReversionMinBandWidthATR = "1.0"
   InpBandVWAPReversionMaxBandWidthATR = "4.5"
   InpBandVWAPReversionMinWickPercent = "15.0"
   InpBandVWAPReversionMinCloseLocation = "0.55"
   InpBandVWAPReversionRequireVWAP = "true"
   InpBandVWAPReversionStopLookbackBars = "5"
   InpBandVWAPReversionStopBufferATR = "0.10"
   InpBandVWAPReversionStopBufferPoints = "20.0"
   InpBandVWAPReversionMaxStopATR = "2.20"
   InpBandVWAPReversionMinTargetATR = "0.40"
   InpBandVWAPReversionMinRR = "1.20"
   InpBandVWAPReversionMaxSpreadATRPercent = "18.0"
   InpBandVWAPReversionUseDIEdgeGate = "true"
   InpBandVWAPReversionMinDIEdge = "-12.0"
   InpBandVWAPReversionUseD1MomentumCap = "true"
   InpBandVWAPReversionD1MomentumLookbackBars = "126"
   InpBandVWAPReversionMaxAbsoluteD1MomentumPercent = "12.0"
   InpUseDailyDonchianBreakoutLane = "true"
   InpDailyDonchianStandaloneMode = "false"
   InpDailyDonchianBypassPrimarySession = "true"
   InpDailyDonchianUseIsolatedExecution = "true"
   InpDailyDonchianUseTakeProfit = "false"
   InpDailyDonchianLookbackBars = "20"
   InpDailyDonchianTrendEMAPeriod = "150"
   InpDailyDonchianTrendSlopeLookback = "5"
   InpDailyDonchianMinTrendSlopeATR = "0.03"
   InpDailyDonchianMinADX = "15.0"
   InpDailyDonchianBreakBufferATR = "0.02"
   InpDailyDonchianMaxRetraceATR = "0.25"
   InpDailyDonchianMaxExtensionATR = "0.80"
   InpDailyDonchianStopATRMultiplier = "1.50"
   InpDailyDonchianMinRR = "1.50"
   InpDailyDonchianUseChannelExit = "true"
   InpDailyDonchianExitLookbackBars = "5"
   InpDailyDonchianRiskMultiplier = "0.45"
   InpDailyDonchianMaxMonthlyEntries = "4"
   InpDailyDonchianSpacingMinutes = "1440"
   InpMOEnabled = "true"
   InpMOMagicNumber = "26071761"
   InpMORiskPercent = "0.15"
   InpMOSignalTimeframe = "16385"
   InpMOMomentumTimeframe = "16408"
   InpMOMomentumLookbackBars = "126"
   InpMOEntryLookbackBars = "20"
   InpMOBreakoutBufferATR = "0.05"
   InpMOAllowBuy = "true"
   InpMOAllowSell = "true"
   InpMORequireFreshBreakout = "true"
   InpMOUseVolatilityFilter = "true"
   InpMOMinimumATRPercent = "0.03"
   InpMOMaximumATRPercent = "2.50"
   InpMOATRPeriod = "20"
   InpMOStopLookbackBars = "5"
   InpMOStopBufferATR = "0.10"
   InpMOMinimumStopATR = "0.40"
   InpMOMaximumStopATR = "2.50"
   InpMOMaximumStopPriceDistance = "10.00"
   InpMOTakeProfitR = "2.00"
   InpMOUseBreakEven = "true"
   InpMOBreakEvenTriggerR = "1.00"
   InpMOBreakEvenLockR = "0.10"
   InpMOUseChannelExit = "true"
   InpMOExitLookbackBars = "5"
   InpMOUseMomentumFailureExit = "true"
   InpMOMaximumHoldBars = "120"
   InpMOUseSessionFilter = "true"
   InpMOSessionStartHour = "6"
   InpMOSessionEndHour = "20"
   InpMODisableFridayAfterHour = "true"
   InpMOFridayCutoffHour = "18"
   InpMOMaximumPositionLots = "0.10"
   InpMOMaximumTradesPerDay = "2"
   InpMOMaximumDailyLossPercent = "0.75"
   InpMOMaximumConsecutiveLosses = "4"
   InpMOLossCooldownHours = "24"
   InpMOMaximumSpreadPoints = "50.0"
   InpMODeviationPoints = "20"
   InpNewYorkStartHour = "13"
   InpNewYorkEndHour = "17"
   InpCustomStartHour = "0"
   InpCustomEndHour = "23"
   InpDiagnosticFallbackPerformanceLookbackTrades = "4"
   InpDiagnosticFallbackPerformanceMinTrades = "2"
   InpDiagnosticFallbackWeakAverageR = "-0.10"
   InpDiagnosticFallbackStrongAverageR = "0.25"
   InpMinDiagnosticFallbackPerformanceRiskMultiplier = "0.50"
   InpDiagnosticFallbackBlockLiquiditySweep = "false"
   InpDiagnosticFallbackRejectLiquiditySweepSignal = "false"
   InpDiagnosticFallbackLiquidityRejectMaxConfirmations = "1"
   InpUseDiagnosticFallbackLateSessionGuard = "false"
   InpDiagnosticFallbackLateSessionStartHour = "16"
   InpDiagnosticFallbackLateSessionPureOnly = "true"
   InpUseDiagnosticFallbackCushionRiskThrottle = "false"
   InpDiagnosticFallbackCushionProfitPercent = "5.00"
   InpDiagnosticFallbackNoCushionRiskMultiplier = "0.50"
   InpHighEfficiencyTrendMode = "0"
   InpHighEfficiencyTrendMinScore = "6"
   InpHighEfficiencyTrendRiskMultiplier = "0.65"
   InpHighEfficiencyTrendMaxMonthlyEntries = "6"
   InpHighEfficiencyTrendSpacingMinutes = "180"
   InpHighEfficiencyTrendStopATRMultiplier = "1.25"
   InpHighEfficiencyTrendTakeProfitATRMultiplier = "2.40"
   InpHighEfficiencyTrendMinRR = "1.25"
   InpEvidenceProfileId = "rdmc_diversified_repair_v1"
   InpEvidenceSourceHash = $sourceHash
   InpEvidenceRunLabel = "rdmc_diversified_repair_model1_static_locked"
   InpLogFileName = "RDMC_DIVERSIFIED_REPAIR_TRADES.csv"
   InpShowDashboard = "false"
   InpDashboardInTester = "false"
}

foreach($key in $overrides.Keys) {
   if(!$sourceInputs.ContainsKey($key)) { throw "Override is not a source input: $key" }
   if(!$profileValues.Contains($key)) { $profileValues[$key] = $overrides[$key] }
   else { $profileValues[$key] = $overrides[$key] }
   if(!$profileSuffixes.ContainsKey($key)) { $profileSuffixes[$key] = "" }
}

$profilesDir = Join-Path $out "profiles"
$configsDir = Join-Path $out "configs"
$reportsDir = Join-Path $out "reports"
New-Item -ItemType Directory -Path $profilesDir, $configsDir, $reportsDir -Force | Out-Null
$profilePath = Join-Path $profilesDir "rdmc_diversified_repair_v1.set"
$profileLines = foreach($key in $profileValues.Keys) {
   "$key=$($profileValues[$key])$($profileSuffixes[$key])"
}
[IO.File]::WriteAllLines($profilePath, [string[]]$profileLines, [Text.Encoding]::ASCII)
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$windows = @()
for($year = 2015; $year -le 2025; $year++) {
   $windows += [pscustomobject]@{ Year = $year; From = "$year.01.01"; To = "$year.12.31" }
}
$windows += [pscustomobject]@{ Year = 2026; From = "2026.01.01"; To = "2026.07.12" }

Get-ChildItem -LiteralPath $configsDir -Filter "*.ini" -File -ErrorAction SilentlyContinue | Remove-Item -Force
$queue = [System.Collections.Generic.List[object]]::new()
$index = 0
foreach($window in $windows) {
   $index++
   $name = "rdmc_diversified_repair_v1_$($window.Year)_m1"
   $configName = "{0:D3}_{1}.ini" -f $index, $name
   $configPath = Join-Path $configsDir $configName
   $configLines = [System.Collections.Generic.List[string]]::new()
   foreach($line in @(
      "[Tester]", "Expert=Professional_XAUUSD_EA.ex5", "Symbol=XAUUSD", "Period=15",
      "Optimization=0", "Model=1", "FromDate=$($window.From)", "ToDate=$($window.To)",
      "ForwardMode=0", "Deposit=10000", "Currency=USD", "ProfitInPips=0", "Leverage=100",
      "ExecutionMode=0", "OptimizationCriterion=6", "Visual=0", "Report=$name",
      "ReplaceReport=1", "ShutdownTerminal=1", "[TesterInputs]"
   )) { $configLines.Add($line) }
   foreach($line in $profileLines) { $configLines.Add($line) }
   [IO.File]::WriteAllLines($configPath, $configLines.ToArray(), [Text.Encoding]::ASCII)
   $queue.Add([pscustomobject]@{
      QueueIndex = $index
      Candidate = "rdmc_diversified_repair_v1"
      Window = [string]$window.Year
      FromDate = $window.From
      ToDate = $window.To
      Model = 1
      Deposit = 10000
      ProfileSha256 = $profileHash
      SourceSha256 = $sourceHash
      Config = "outputs/rdmc_diversified_repair_model1_package/configs/$configName"
      Status = "LOCKED_LOCAL_LAUNCH_DISABLED"
   })
}

$queuePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_MODEL1_QUEUE.csv"
$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
$manifest = [pscustomobject]@{
   Candidate = "rdmc_diversified_repair_v1"
   Status = "STATIC_ONLY_LOCKED"
   PromotionStatus = "NOT_PROMOTED"
   ForwardCandidateChanged = "NO"
   StartingCapital = 10000
   Currency = "USD"
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
   ThreeLaneBaseSourceSha256 = $expectedThreeLaneSourceHash
   R20EvidenceSourceSha256 = $expectedR20SourceHash
   R20ProfileSha256 = $expectedR20ProfileHash
   ThreeLaneProfileSha256 = $expectedThreeLaneProfileHash
   ConfigCount = $queue.Count
   CompileStatus = "NOT_RUN_LOCAL_LOCK_ACTIVE"
   BacktestStatus = "NOT_RUN_LOCAL_LOCK_ACTIVE"
   HistoricalBestChanged = "NO"
}
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_MODEL1_MANIFEST.csv"
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

$packagePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_MODEL1_PACKAGE.md"
$packageLines = @(
   "# RDMC Diversified Repair Model1 Package",
   "",
   "Status: **STATIC ONLY / LOCKED / NOT PROMOTED**",
   "",
   'This package converts the favorable offline four-component screen into one executable research source and one $10,000 USD profile. It does not establish a new best. Compilation and MT5 testing remain intentionally unrun while the local launch lock is active.',
   "",
   "## Frozen architecture",
   "",
   "| Lane | Effective requested risk | Implementation |",
   "|---|---:|---|",
   "| R20 primary DGF | 0.10% | Base risk 0.50% x primary multiplier 0.20 |",
   "| DI -12 Band/VWAP reversion plus completed-D1 cap | 0.45% | Base risk 0.50% x lane multiplier 0.90 |",
   "| Daily Donchian DDB045 | 0.225% | Base risk 0.50% x lane multiplier 0.45 |",
   "| M126/E20 multiscale momentum | 0.15% | Explicit requested risk normalized through the shared risk manager |",
   "",
   "Only one account position is allowed. Account-wide requested open risk is capped at 0.75%; unprotected exposure is blocked. Daily, weekly, monthly, and peak-equity loss limits are enabled. Real-account trading remains locked, and this research source refuses non-tester attachment by default.",
   "",
   "## Identity",
   "",
   "- Source SHA-256: $sourceHash",
   "- Profile SHA-256: $profileHash",
   "- R20 evidence source SHA-256: $expectedR20SourceHash",
   "- R20 evidence profile SHA-256: $expectedR20ProfileHash",
   "- Three-lane base source SHA-256: $expectedThreeLaneSourceHash",
   "- Queue: outputs/RDMC_DIVERSIFIED_REPAIR_MODEL1_QUEUE.csv",
   "",
   "## Required gates",
   "",
   "The 12 annual Model1 windows are a first implementation gate only. A candidate must compile cleanly, keep every broad era profitable, avoid losing repair years, survive continuous Model1 and real-tick Model4 testing, and pass cost and Monte Carlo stress before promotion. The current forward candidate, profile, binary, run label, registration, evidence, and real-account lock are unchanged."
)
[IO.File]::WriteAllLines($packagePath, $packageLines, [Text.Encoding]::ASCII)

$manifest
