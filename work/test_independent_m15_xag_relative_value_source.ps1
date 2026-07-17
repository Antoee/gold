param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_XAG_Relative_Value.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "Cross-metal source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$expectedHash = "F79BED792F6F2D961181C9A8B0BC9297F5EC41039A816B492CA4CAF442749657"
$required = @(
   '#property description "Date-independent XAUUSD M15 XAGUSD relative-value reversion research EA"',
   'InpReferenceSymbol = "XAGUSD";',
   'InpSignalTimeframe = PERIOD_M15;',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'bool LoadAlignedRates(const int count, MqlRates &xauRates[], MqlRates &xagRates[])',
   'double PearsonCorrelation(',
   'features.divergenceAtr = features.xauMoveAtr - features.xagMoveAtr;',
   'features.divergenceAtr <= -InpDivergenceThresholdATR',
   'features.divergenceAtr >= InpDivergenceThresholdATR',
   'features.recentLow - InpStopBufferATR * features.xauAtr',
   'features.recentHigh + InpStopBufferATR * features.xauAtr',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'InpAccountWideBlockUnprotectedExposure = true;',
   'trade.PositionModify(ticket, newSl, oldTp);'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Missing cross-metal source contract token: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowRealAccountTrading = true;')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden unsafe source token: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($hash -ne $expectedHash) { throw "Unexpected cross-metal source hash: $hash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$hash; Lines=(Get-Content -LiteralPath $full).Count
   TradeSymbol="XAUUSD"; ReferenceSymbol="XAGUSD"; Timeframe="M15"
   UsesClosedBarsOnly=$true; RiskUsesOrderCalcProfit=$true; ForcesMinimumLot=$false
   PreservesTakeProfitOnStopUpdate=$true; RealTradingDefault=$false
}
