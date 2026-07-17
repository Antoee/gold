param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_XAG_Lead_Lag_Pullback.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "Lead-lag pullback source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$expectedHash = "AC1B533EBCBBB42505589DEAD08A11143C88B3FB13A11C57AB4BB96F06F8F21F"
$required = @(
   '#property description "Date-independent XAUUSD M15 XAGUSD lead-lag pullback research EA"',
   'InpReferenceSymbol = "XAGUSD";',
   'InpSignalTimeframe = PERIOD_M15;',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'bool LoadAlignedRates(const int count, MqlRates &xauRates[], MqlRates &xagRates[])',
   'double PearsonCorrelation(',
   'double ExponentialMovingAverage(',
   'features.xagMoveAtr >= InpMinimumXAGImpulseATR',
   'features.xagMoveAtr - features.xauMoveAtr >= InpMinimumXAGLeadGapATR',
   'features.fastEma > features.slowEma',
   'features.fastEma > features.priorFastEma',
   'features.priorLow <= features.priorFastEma + pullbackTolerance',
   'features.signalClose > features.priorHigh',
   'features.signalClose < features.priorLow',
   'features.recentLow - InpStopBufferATR * features.xauAtr',
   'features.recentHigh + InpStopBufferATR * features.xauAtr',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'InpAccountWideBlockUnprotectedExposure = true;',
   'trade.PositionModify(ticket, newSl, oldTp);'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Missing lead-lag source contract token: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowRealAccountTrading = true;','features.divergenceAtr','synchronized channel breakout')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden source token: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($hash -ne $expectedHash) { throw "Unexpected lead-lag pullback source hash: $hash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$hash; Lines=(Get-Content -LiteralPath $full).Count
   TradeSymbol="XAUUSD"; ReferenceSymbol="XAGUSD"; Timeframe="M15"
   UsesClosedBarsOnly=$true; RequiresXAGLead=$true; RequiresXAUPullbackReclaim=$true
   RiskUsesOrderCalcProfit=$true; ForcesMinimumLot=$false
   PreservesTakeProfitOnStopUpdate=$true; RealTradingDefault=$false
}
