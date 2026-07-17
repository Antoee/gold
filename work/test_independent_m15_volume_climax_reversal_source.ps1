param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Volume_Climax_Reversal.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 volume-climax source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 volume-climax VWAP-reversion research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpMinimumVolumeRatio',
   'InpMinimumWickPercent',
   'InpMinimumVWAPDeviationATR',
   'InpUseRangePhaseFilter',
   'TickVolumeRatio',
   'DailyAnchoredVWAP',
   'FreshExtremeAllows',
   'TryVolumeClimaxEntry',
   'OpenClimaxPosition',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 6.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15VCR-LIVE-ACK',
   'M15VCR_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 volume-climax token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M15SQ',
   'TryVolatilitySqueezeEntry',
   'InpBollingerPeriod',
   'InpKeltnerATRMultiplier',
   'M15FBT'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 volume-climax token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   TickVolumeClimax = $true
   DailyAnchoredVWAP = $true
   WickRejection = $true
   StructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
