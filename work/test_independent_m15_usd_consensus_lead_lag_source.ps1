param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_USD_Consensus_Lead_Lag.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 USD-consensus lead-lag source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 EURUSD/USDJPY consensus lead-lag research EA"',
   'InpEURUSDSymbol = "EURUSD"',
   'InpUSDJPYSymbol = "USDJPY"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpProxyTimeframe = PERIOD_H1',
   'InpMaximumAlignmentSeconds = 3600',
   'alignedOpen + timeframeSeconds > completedAt',
   'NormalizedAlignedMove',
   'BuildConsensus',
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
   'M15USDCLL-LIVE-ACK',
   'M15USDCLL_DIAGNOSTIC',
   'double takeProfit = PositionGetDouble(POSITION_TP)',
   'trade.PositionModify(ticket, newStop, takeProfit)'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 USD-consensus lead-lag token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M15WGF',
   'M15ODC',
   'M15ODS2',
   'OpenGapFadePosition',
   'TryWeekendGapEntry',
   'PriorDayBar',
   'SessionRange'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 USD-consensus lead-lag token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   CrossMarketConsensus = $true
   CompletedBarAlignment = $true
   M15BreakoutConfirmation = $true
   LocalStructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   InitialBalanceContract = $true
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
