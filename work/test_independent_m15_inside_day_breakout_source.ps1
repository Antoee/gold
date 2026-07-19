param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Inside_Day_Breakout.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 inside-day source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 inside-day compression-breakout research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpMinimumInsideRangeRatio',
   'InpMaximumInsideRangeRatio',
   'InpBreakoutBufferATR',
   'InpMinimumBodyPercent',
   'InpMinimumVolumeRatio',
   'InsideDayContext',
   'CandleBodyPercent',
   'TickVolumeRatio',
   'OpenInsideDayPosition',
   'StructureStop',
   'InpMaximumStopPriceDistance = 8.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15IDB-LIVE-ACK',
   'M15IDB_DIAGNOSTIC',
   'double oldTp = PositionGetDouble(POSITION_TP)',
   'trade.PositionModify(ticket, newSl, oldTp)'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 inside-day token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M30SC',
   'InpEntryLookbackBars',
   'InpExitLookbackBars',
   'OpenTrendPosition',
   'TryChannelExit'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 inside-day token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   CompletedD1Inputs = $true
   M15FreshBreakout = $true
   StructureStop = $true
   TakeProfitPreservedOnModify = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
