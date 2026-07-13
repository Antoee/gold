$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path $repo ("work\trade_readiness_profile_test_{0}" -f $PID)
$outSet = Join-Path $tempRoot "CANDIDATE_TRADE_READINESS_PROFILE.set"

function Assert-True {
   param([bool]$Condition, [string]$Message)
   if(!$Condition) { throw $Message }
}

try {
   New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\write_trade_readiness_profile.ps1") `
      -OutSetPath $outSet | Out-Null

   Assert-True (Test-Path -LiteralPath $outSet) "Trade-readiness profile was not written"
   $text = Get-Content -LiteralPath $outSet -Raw

   foreach($needle in @(
      "InpRiskPercent=0.50||0.50||0||0||N",
      "InpMaxEffectiveRiskPercent=0.50||0.50||0||0||N",
      "InpMaxOpenRiskPercent=0.75||0.75||0||0||N",
      "InpMaxPositionLots=0.05||0.05||0||0||N",
      "InpMaxSimultaneousPositions=1||1||0||0||N",
      "InpMaxDailyLossPercent=0.75||0.75||0||0||N",
      "InpMaxWeeklyLossPercent=2.00||2.00||0||0||N",
      "InpMaxMonthlyLossPercent=4.00||4.00||0||0||N",
      "InpMaxEquityDrawdownPercent=10.00||10.00||0||0||N",
      "InpClosePositionsOnRiskLimit=true||true||0||0||N",
      "InpMaxDailyLossCount=1||1||0||0||N",
      "InpMaxConsecutiveLosses=2||2||0||0||N",
      "InpCooldownMinutesAfterLoss=240||240||0||0||N",
      "InpUseDailyLossRiskScaling=true||true||0||0||N",
      "InpUseWeeklyLossRiskScaling=true||true||0||0||N",
      "InpUseMonthlyLossRiskScaling=true||true||0||0||N",
      "InpUseDrawdownRiskReduction=true||true||0||0||N",
      "InpUseDrawdownQualityGate=true||true||0||0||N",
      "InpUseDailyProfitLock=true||true||0||0||N",
      "InpUseWeeklyProfitLock=true||true||0||0||N",
      "InpUseMonthlyProfitLock=true||true||0||0||N",
      "InpUseProfitGivebackGuard=true||true||0||0||N",
      "InpUseSpreadAdjustedRRFilter=true||true||0||0||N",
      "InpMaxSpreadPoints=220||220||0||0||N",
      "InpUseSpreadRegimeGuard=true||true||0||0||N",
      "InpUseM1SpreadShockGuard=true||true||0||0||N",
      "InpDeviationPoints=25||25||0||0||N",
      "InpUseMarginGuard=true||true||0||0||N",
      "InpMinMarginLevelPercent=500.0||500.0||0||0||N",
      "InpUseAdaptiveReverse=false||false||0||0||N",
      "InpUseWinnerScaleIn=false||false||0||0||N",
      "InpUseProtectedCushionUnlimitedRunner=false||false||0||0||N",
      "InpUseEliteContinuationUnlimitedRunner=false||false||0||0||N",
      "InpUseFlatMonthLiquidityReclaimLane=false||false||0||0||N",
      "InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter=false||false||0||0||N",
      "InpUseTickSpeedImpulse=false||false||0||0||N"
   )) {
      Assert-True ($text.Contains($needle)) "Missing trade-readiness override: $needle"
   }

   "TRADE_READINESS_PROFILE_SMOKE_PASS"
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
