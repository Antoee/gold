param(
   [string]$SourcePath = "work\Independent_XAUUSD_M30_Compression_Expansion.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M30 compression-expansion source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M30 compression-expansion continuation research EA"',
   'InpSignalTimeframe = PERIOD_M30',
   'InpBoxLookbackBars',
   'InpMaximumAverageBoxBarRangeATR',
   'InpMinimumExpansionRatio',
   'InpMinimumBreakBodyPercent',
   'InpMinimumBreakCloseLocation',
   'InpUseBreakoutTickVolumeFilter',
   'AverageBarRange',
   'TryCompressionExpansionEntry',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 8.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M30CE-LIVE-ACK',
   'M30CE_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M30 compression-expansion token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M15FBT',
   'TryFailedBreakoutTrapEntry',
   'OpenTrapPosition',
   'InpUseBoxOppositeTarget'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M30 compression-expansion token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   StructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
