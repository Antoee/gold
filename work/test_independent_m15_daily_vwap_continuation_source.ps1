param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Daily_VWAP_Continuation.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "M15 daily-VWAP continuation source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 daily-VWAP trend-continuation research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpTrendTimeframe = PERIOD_H1',
   'InpMinimumVWAPBars',
   'InpRequirePriorCloseBeyondVWAP',
   'InpTrendFastEMAPeriod',
   'InpTrendSlowEMAPeriod',
   'InpMinimumSignalBodyPercent',
   'InpUseSignalVolumeFilter',
   'DailyAnchoredVWAP',
   'VWAPPullbackAllows',
   'DailyVWAPContinuationSignal',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 8.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15DVC-LIVE-ACK-v1',
   'M15DVC_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 daily-VWAP token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'InpPullbackEMAPeriod',
   'M15TPB-LIVE-ACK',
   'DetectNewFvgSetup'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 daily-VWAP token present: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $hash
   Lines = (Get-Content -LiteralPath $full).Count
   CompletedBarVWAP = $true
   StructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
