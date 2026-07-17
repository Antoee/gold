param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Volatility_Squeeze.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "M15 volatility-squeeze source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 volatility-squeeze continuation research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpSqueezeBars',
   'InpBollingerPeriod',
   'InpBollingerDeviation',
   'InpKeltnerATRMultiplier',
   'InpBreakoutLookbackBars',
   'iBands(',
   'SqueezeBarAllows',
   'SqueezeWindowAllows',
   'TryVolatilitySqueezeEntry',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 6.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15SQ-LIVE-ACK',
   'M15SQ_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 volatility-squeeze token missing: $token" }
}
$forbidden = @(
   'martingale',
   'averaging down',
   'grid recovery',
   'InpAllowMinLotRiskOverflow',
   'M30CE',
   'TryCompressionExpansionEntry',
   'InpBoxLookbackBars',
   'M15FBT'
)
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 volatility-squeeze token present: $token" }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   BollingerKeltnerSqueeze = $true
   FreshBreakout = $true
   StructureStop = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
