param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_XAG_Synchronized_Continuation.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "Synchronized-continuation source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$expectedHash = "53D4864FDBA2365193AA9D7AC1185B1B9CD2BFA3CC34453D18AF3A8DD8552D88"
$required = @(
   '#property description "Date-independent XAUUSD M15 XAGUSD synchronized-continuation research EA"',
   'InpReferenceSymbol = "XAGUSD";',
   'InpSignalTimeframe = PERIOD_M15;',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'bool LoadAlignedRates(const int count, MqlRates &xauRates[], MqlRates &xagRates[])',
   'double PearsonCorrelation(',
   'features.xauMoveAtr >= InpMinimumXAUMoveATR',
   'features.xagMoveAtr >= InpMinimumXAGMoveATR',
   'features.signalClose > features.breakoutHigh + breakoutBuffer',
   'features.signalClose < features.breakoutLow - breakoutBuffer',
   'features.priorClose <= features.priorBreakoutHigh + breakoutBuffer',
   'features.priorClose >= features.priorBreakoutLow - breakoutBuffer',
   'features.recentLow - InpStopBufferATR * features.xauAtr',
   'features.recentHigh + InpStopBufferATR * features.xauAtr',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'InpAccountWideBlockUnprotectedExposure = true;',
   'trade.PositionModify(ticket, newSl, oldTp);'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Missing synchronized-continuation contract token: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowRealAccountTrading = true;','relative-value reversal','features.divergenceAtr')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden source token: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($hash -ne $expectedHash) { throw "Unexpected synchronized-continuation source hash: $hash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$hash; Lines=(Get-Content -LiteralPath $full).Count
   TradeSymbol="XAUUSD"; ReferenceSymbol="XAGUSD"; Timeframe="M15"
   UsesClosedBarsOnly=$true; RequiresSameDirectionMoves=$true; RequiresFreshBreakout=$true
   RiskUsesOrderCalcProfit=$true; ForcesMinimumLot=$false
   PreservesTakeProfitOnStopUpdate=$true; RealTradingDefault=$false
}
