param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Overnight_Drift_Structure_V2.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 overnight-drift structure-v2 source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 overnight-drift local-structure research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpEntryHour = 7',
   'InpExitHour = 17',
   'InpMinimumPriorDayMoveATR',
   'InpMinimumPriorDayBodyPercent',
   'InpMinimumAsianRangeATR',
   'InpMaximumAsianDriftATR',
   'PriorDayBar',
   'SessionRange',
   'LocalStructureStop',
   'InpStopLookbackBars = 4',
   'CopyRates(_Symbol, InpSignalTimeframe, 1, InpStopLookbackBars, rates)',
   'InpMinimumStopATR = 0.05',
   'InpMaximumStopATR = 0.35',
   'InpMaximumStopPriceDistance = 8.00',
   'DateKey(TimeCurrent()) > DateKey(openTime)',
   'nowParts.hour >= InpExitHour',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpEnforceInitialBalanceContract = true',
   'InpEnforceAccountCurrency && !MQLInfoInteger(MQL_TESTER)',
   'InpRequireEmptyAccountAtEntry = true',
   'InpAccountWideBlockUnprotectedExposure = true',
   'InpAllowRealAccountTrading = false',
   'M15ODS2-LIVE-ACK',
   'M15ODS2_DIAGNOSTIC',
   'double takeProfit = PositionGetDouble(POSITION_TP)',
   'trade.PositionModify(ticket, newStop, takeProfit)'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 overnight-drift structure-v2 token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M15WGF',
   'M15ODC',
   'OpenGapFadePosition',
   'TryWeekendGapEntry',
   'asianLow - InpStopBufferATR',
   'asianHigh + InpStopBufferATR'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 overnight-drift structure-v2 token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   PriorDayContext = $true
   AsianSessionContext = $true
   LocalStructureStop = $true
   FixedIntradayExit = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   InitialBalanceContract = $true
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
