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
   'input bool\s+InpAllowMinLotRiskOverflow\s*=\s*false;',
   'double NormalizeLots\(const double lots\)',
   'double minLot = SymbolInfoDouble\(_Symbol, SYMBOL_VOLUME_MIN\);',
   'if\(lots < minLot && !InpAllowMinLotRiskOverflow\)\s*\r?\n\s*return 0\.0;',
   'double LotsForRisk\(const ENUM_TRADE_BIAS bias,',
   'double riskMoney = equity \* effectiveRiskPercent / 100\.0;',
   'double moneyPerLot = RiskMoneyForOrder\(orderType, entryPrice, stopPrice, 1\.0\);',
   'return NormalizeLots\(riskMoney / moneyPerLot\);',
   'AppendTradeReadinessViolation\(InpAllowMinLotRiskOverflow,',
   '"min-lot risk overflow enabled"'
)

foreach($pattern in $requiredPatterns) {
   if($source -notmatch $pattern) {
      throw "Missing expected lot-sizing guard pattern: $pattern"
   }
}

$lotsIndex = $source.IndexOf('double lots = riskManager.LotsForRisk(signal.bias, entry, stopDistance, riskMultiplier);')
$lotRejectIndex = $source.IndexOf('g_lastBlockReason = "lot sizing";', $lotsIndex)
$exposureIndex = $source.IndexOf('riskManager.ExposureAllows(signal.bias, entry, stopDistance, lots, exposureReason)', $lotsIndex)
$buyIndex = $source.IndexOf('trade.Buy(lots, _Symbol, 0, sl, tp, tradeComment)', $lotsIndex)
$sellIndex = $source.IndexOf('trade.Sell(lots, _Symbol, 0, sl, tp, tradeComment)', $lotsIndex)

if($lotsIndex -lt 0 -or $lotRejectIndex -lt 0 -or $exposureIndex -lt 0 -or $buyIndex -lt 0 -or $sellIndex -lt 0) {
   throw "Could not locate lot sizing, zero-lot rejection, exposure guard, or order placement."
}
if(!($lotsIndex -lt $lotRejectIndex -and $lotRejectIndex -lt $exposureIndex -and
   $exposureIndex -lt $buyIndex -and $exposureIndex -lt $sellIndex)) {
   throw "Risk lot sizing and zero-lot rejection must run before exposure checks and order placement."
}

"RISK_LOT_SIZING_GUARD_SMOKE_PASS"
