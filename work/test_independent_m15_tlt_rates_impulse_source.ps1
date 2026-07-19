param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_TLT_Rates_Impulse.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 TLT rates-impulse source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 TLT rates-impulse research EA"',
   'InpTLTSymbol = "TLT"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpReferenceTimeframe = PERIOD_D1',
   'InpMaximumAlignmentSeconds = 259200',
   'referenceOpen + timeframeSeconds > decisionTime',
   'referenceClose > decisionTime',
   'CopyRates(InpTLTSymbol, InpReferenceTimeframe, shift, required, rates)',
   'BuildReferenceDirection',
   'InpRequireReferenceTrend',
   'BreakoutAllows',
   'LocalStructureStop',
   'EntriesSince(g_dayStart) >= 1',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpEnforceInitialBalanceContract = true',
   'InpEnforceAccountCurrency && !MQLInfoInteger(MQL_TESTER)',
   'InpRequireEmptyAccountAtEntry = true',
   'InpAccountWideMaxOpenRiskPercent = 1.00',
   'InpAccountWideBlockUnprotectedExposure = true',
   'InpAllowRealAccountTrading = false',
   'M15TLTRI-LIVE-ACK',
   'M15TLTRI_DIAGNOSTIC',
   'double takeProfit = PositionGetDouble(POSITION_TP)',
   'trade.PositionModify(ticket, newStop, takeProfit)'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 TLT rates-impulse token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'InpEURUSDSymbol',
   'InpUSDJPYSymbol',
   'M15USDCLL',
   'BuildConsensus',
   'NormalizedAlignedMove',
   'CopyRates(_Symbol, InpSignalTimeframe, 0,'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 TLT rates-impulse token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   TLTCompletedD1Context = $true
   LookaheadGuard = $true
   M15BreakoutConfirmation = $true
   LocalStructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   InitialBalanceContract = $true
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
