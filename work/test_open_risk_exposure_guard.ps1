param(
   [string]$EaPath = "outputs\Professional_XAUUSD_EA.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if(!(Test-Path -LiteralPath $EaPath)) {
   throw "EA source missing: $EaPath"
}

$source = Get-Content -LiteralPath $EaPath -Raw

$requiredPatterns = @(
   'input double\s+InpMaxOpenRiskPercent\s*=\s*0\.00;',
   'input bool\s+InpBlockUnprotectedExposure\s*=\s*true;',
   'double RiskMoneyForOrder\(const ENUM_ORDER_TYPE orderType,',
   'if\(!OrderCalcProfit\(orderType,',
   'double PositionRiskMoney\(const ulong ticket, bool &unprotected\)',
   'double OpenRiskPercent\(bool &hasUnprotectedPosition\)',
   'bool ExposureAllows\(const ENUM_TRADE_BIAS bias,',
   'double addedRiskMoney = RiskMoneyForOrder\(orderType, entryPrice, stopPrice, lots\);',
   'if\(openRiskPercent \+ addedRiskPercent > maxOpenRiskPercent\)',
   'riskManager\.ExposureAllows\(signal\.bias, entry, stopDistance, lots, exposureReason\)',
   'g_lastBlockReason = exposureReason;',
   'reason = "open risk limit";',
   'reason = "unprotected open exposure";'
)

foreach($pattern in $requiredPatterns) {
   if($source -notmatch $pattern) {
      throw "Missing expected open-risk guard pattern: $pattern"
   }
}

$lotsIndex = $source.IndexOf('double lots = riskManager.LotsForRisk(signal.bias, entry, stopDistance, riskMultiplier);')
$exposureIndex = $source.IndexOf('riskManager.ExposureAllows(signal.bias, entry, stopDistance, lots, exposureReason)')
$buyIndex = $source.IndexOf('trade.Buy(lots, _Symbol, 0, sl, tp, tradeComment)')
$sellIndex = $source.IndexOf('trade.Sell(lots, _Symbol, 0, sl, tp, tradeComment)')

if($lotsIndex -lt 0 -or $exposureIndex -lt 0 -or $buyIndex -lt 0 -or $sellIndex -lt 0) {
   throw "Could not locate lot sizing, exposure guard, or order placement in EA source."
}
if(!($lotsIndex -lt $exposureIndex -and $exposureIndex -lt $buyIndex -and $exposureIndex -lt $sellIndex)) {
   throw "Open-risk guard must run after lot sizing and before order placement."
}

"OPEN_RISK_EXPOSURE_GUARD_SMOKE_PASS"
