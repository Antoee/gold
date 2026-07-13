param(
   [string]$BaseSetPath = "outputs\CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set",
   [string]$OutSetPath = "outputs\CANDIDATE_TRADE_READINESS_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$inputs = Import-SetInputs $BaseSetPath

$overrides = [ordered]@{
   InpRiskPercent = "0.50"
   InpMaxEffectiveRiskPercent = "0.50"
   InpMaxOpenRiskPercent = "0.75"
   InpMaxPositionLots = "0.05"
   InpMaxSimultaneousPositions = "1"
   InpAllowMinLotRiskOverflow = "false"
   InpBlockUnprotectedExposure = "true"

   InpMaxDailyLossPercent = "0.75"
   InpMaxWeeklyLossPercent = "2.00"
   InpMaxMonthlyLossPercent = "4.00"
   InpMaxEquityDrawdownPercent = "10.00"
   InpClosePositionsOnRiskLimit = "true"
   InpMaxDailyLossCount = "1"
   InpMaxWeeklyLossCount = "3"
   InpMaxMonthlyLossCount = "5"
   InpMaxConsecutiveLosses = "2"
   InpCooldownMinutesAfterLoss = "240"

   InpUseLossStreakRiskReduction = "true"
   InpLossStreakRiskReductionStart = "1"
   InpLossStreakRiskReductionFactor = "0.50"
   InpMinReducedRiskPercent = "0.10"
   InpUseDrawdownRiskReduction = "true"
   InpDrawdownRiskReductionStartPercent = "1.50"
   InpDrawdownRiskReductionFullPercent = "6.00"
   InpDrawdownRiskReductionMaxFactor = "0.35"
   InpUseDrawdownQualityGate = "true"
   InpDrawdownQualityStartPercent = "1.50"
   InpDrawdownQualityFullPercent = "6.00"
   InpDrawdownQualityMinScore = "8"
   InpDrawdownQualityMaxScore = "13"
   InpUseDailyLossRiskScaling = "true"
   InpDailyLossRiskStartFraction = "0.25"
   InpMinDailyLossRiskMultiplier = "0.35"
   InpUseWeeklyLossRiskScaling = "true"
   InpWeeklyLossRiskStartFraction = "0.25"
   InpMinWeeklyLossRiskMultiplier = "0.35"
   InpUseMonthlyLossRiskScaling = "true"
   InpMonthlyLossRiskStartFraction = "0.25"
   InpMinMonthlyLossRiskMultiplier = "0.35"

   InpUseDailyProfitLock = "true"
   InpDailyProfitLockPercent = "1.00"
   InpUseWeeklyProfitLock = "true"
   InpWeeklyProfitLockPercent = "2.00"
   InpUseMonthlyProfitLock = "true"
   InpMonthlyProfitLockPercent = "4.00"
   InpUseProfitGivebackGuard = "true"
   InpDailyProfitGivebackPercent = "25.0"
   InpWeeklyProfitGivebackPercent = "30.0"
   InpMonthlyProfitGivebackPercent = "30.0"
   InpUseDailyEquityTrailGuard = "true"
   InpDailyEquityTrailGivebackPercent = "30.0"
   InpDailyEquityTrailMinProfitPercent = "0.35"
   InpUseEquityProfitPeakTrail = "true"
   InpEquityProfitPeakTrailMinProfitPercent = "3.00"
   InpEquityProfitPeakTrailGivebackPercent = "30.0"

   InpMaxSpreadPoints = "220"
   InpMaxSpreadATRPercent = "12.0"
   InpUseSpreadAdjustedRRFilter = "true"
   InpMinSpreadAdjustedRR = "1.30"
   InpMaxTradingCostRiskPercent = "8.0"
   InpUseSpreadRegimeGuard = "true"
   InpSpreadRegimeLookbackBars = "24"
   InpMaxSpreadRegimeRatio = "1.25"
   InpMinSpreadRegimePoints = "30.0"
   InpUseM1SpreadShockGuard = "true"
   InpM1SpreadShockLookbackBars = "30"
   InpM1SpreadShockMaxRatio = "1.60"
   InpM1SpreadShockMinPoints = "35.0"
   InpUseSpreadRiskScaling = "true"
   InpSpreadRiskStartPoints = "100.0"
   InpMinSpreadRiskMultiplier = "0.50"
   InpDeviationPoints = "25"

   InpUseMarginGuard = "true"
   InpMinMarginLevelPercent = "500.0"
   InpMaxTradeMarginFreePercent = "10.0"
   InpUseMarginAwareLotCap = "true"
   InpUseMarginPressureRiskScaling = "true"
   InpMarginPressureStartLevelPercent = "700.0"
   InpMinMarginPressureRiskMultiplier = "0.50"
   InpUseTradeMarginRiskScaling = "true"
   InpTradeMarginRiskStartFraction = "0.35"
   InpMinTradeMarginRiskMultiplier = "0.50"

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
   InpUseProtectedCushionUnlimitedRunner = "false"
   InpUseEliteContinuationUnlimitedRunner = "false"
   InpUseQualityTakeProfitScaling = "false"
   InpUseRunnerTakeProfitExpansion = "false"
   InpUseProtectedCushionTakeProfitExpansion = "false"
   InpUseClosedProfitTakeProfitExpansion = "false"
   InpUseEliteConfluenceTakeProfitExpansion = "false"

   InpUseFlatMonthLiquidityReclaimLane = "false"
   InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter = "false"
   InpUseFlatMonthCatchUpRiskRamp = "false"
   InpUseFlatMonthLateCatchUp = "false"
   InpUseFlatMonthMissedMoveTPExpansion = "false"
   InpUseFlatMonthCatchUpTakeProfitExpansion = "false"
   InpUseTickSpeedImpulse = "false"
}

foreach($entry in $overrides.GetEnumerator()) {
   Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
}

$outDir = Split-Path -Parent $OutSetPath
if($outDir -and !(Test-Path -LiteralPath $outDir)) {
   New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] } | Set-Content -LiteralPath $OutSetPath -Encoding ASCII
Get-FileHash -Algorithm SHA256 $OutSetPath
