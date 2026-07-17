param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_FVG_Retest.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "M15 FVG source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M15 displacement FVG retest research EA"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpBreakLookbackBars',
   'InpMinimumGapATR',
   'InpMinimumImpulseRangeATR',
   'InpRetestHoldFraction',
   'DetectNewFvgSetup',
   'TryFvgRetestEntry',
   'FinalizeStructureStop',
   'InpMaximumStopPriceDistance = 10.00',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15FVG-LIVE-ACK',
   'M15FVG_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M15 FVG token missing: $token" }
}
$forbidden = @('martingale', 'averaging down', 'grid recovery', 'InpAllowMinLotRiskOverflow', 'M30SC', 'InpEntryLookbackBars')
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden/stale M15 FVG token present: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $hash
   Lines = (Get-Content -LiteralPath $full).Count
   DeferredRetest = $true
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   RealTradingDefault = $false
}

