param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Trend_Pullback.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "M15 trend-pullback source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 trend-pullback continuation research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpTrendTimeframe = PERIOD_H1',
   'InpPullbackEMAPeriod',
   'InpTrendFastEMAPeriod',
   'InpTrendSlowEMAPeriod',
   'InpMinimumSignalBodyPercent',
   'InpMinimumRejectionWickPercent',
   'InpUseSignalVolumeFilter',
   'PriorImpulseAllows',
   'PullbackTouched',
   'TrendPullbackSignal',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 8.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15TPB-LIVE-ACK',
   'M15TPB_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 trend-pullback token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M15FVG',
   'DetectNewFvgSetup',
   'TryFvgRetestEntry'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 trend-pullback token present: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $hash
   Lines = (Get-Content -LiteralPath $full).Count
   StructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
