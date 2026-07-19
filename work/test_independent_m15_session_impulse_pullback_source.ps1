param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Session_Impulse_Pullback.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 session impulse-pullback source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 fixed-session impulse-pullback research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpObservationStartHour = 6',
   'InpObservationEndHour = 9',
   'InpEntryEndHour = 14',
   'InpMinimumImpulseATR = 0.60',
   'InpMinimumEfficiency = 0.45',
   'InpMinimumDirectionalBarsPercent = 55.0',
   'InpMinimumPullbackRetracement = 0.20',
   'InpMaximumPullbackRetracement = 0.60',
   'BuildImpulseContext',
   'CopyRates(_Symbol, InpSignalTimeframe, observationStart, observationEnd - 1, bars)',
   'if(copied != expectedBars)',
   'double efficiency = MathAbs(netMove) / path',
   'PullbackReclaimAllows',
   'CopyRates(_Symbol, InpSignalTimeframe, 1, required, rates)',
   'signal.time < observationEnd',
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
   'M15SIP-LIVE-ACK',
   'M15SIP_DIAGNOSTIC',
   'double takeProfit = PositionGetDouble(POSITION_TP)',
   'trade.PositionModify(ticket, newStop, takeProfit)'
)
foreach($token in $required) {
   if($text.IndexOf($token,[StringComparison]::Ordinal) -lt 0) { throw "Required M15 session impulse-pullback token missing: $token" }
}
$forbidden = @(
   'martingale','averaging down','grid recovery','InpAllowMinLotRiskOverflow',
   'M15USDCLL','M15ODS2','M15ODC','InpEURUSDSymbol','InpUSDJPYSymbol',
   'BuildConsensus','NormalizedAlignedMove','PriorDayBar','SessionRange',
   'CopyRates(_Symbol, InpSignalTimeframe, 0,'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token,[StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 session impulse-pullback token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   CompletedObservationWindow = $true
   AuctionEfficiency = $true
   BoundedPullback = $true
   CompletedSignalBar = $true
   LocalStructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   InitialBalanceContract = $true
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
