param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_ADR_Exhaustion_Reversion.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 ADR-exhaustion source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 ADR-exhaustion VWAP-reversion research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpADRLookbackDays',
   'InpMinimumDayRangeADR',
   'InpMaximumDayRangeADR',
   'InpMinimumDirectionalMoveADR',
   'InpMinimumVolumeRatio',
   'InpMinimumWickPercent',
   'InpMinimumVWAPDeviationATR',
   'InpUseRangePhaseFilter',
   'TickVolumeRatio',
   'DailyAnchoredVWAP',
   'ADRContext',
   'FreshExtremeAllows',
   'TryADRExhaustionEntry',
   'OpenExhaustionPosition',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 8.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15AER-LIVE-ACK',
   'M15AER_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 ADR-exhaustion token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M15VCR',
   'TryVolumeClimaxEntry',
   'OpenClimaxPosition',
   'volume climax VWAP reversal'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 ADR-exhaustion token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   PriorDayADR = $true
   DailyAnchoredVWAP = $true
   WickRejection = $true
   StructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
