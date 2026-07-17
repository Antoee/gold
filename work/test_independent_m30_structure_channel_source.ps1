param(
   [string]$SourcePath = "work\Independent_XAUUSD_M30_Structure_Channel.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "M30 structure-channel source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD M30 structure-stop channel research EA"',
   'InpSignalTimeframe = PERIOD_M30',
   'InpRiskPercent = 0.10',
   'InpMaximumStopPriceDistance = 10.00',
   'InpAllowRealAccountTrading = false',
   'InpUseRealAccountSafetyLock = true',
   'InpUseAccountWideExposureGuard = true',
   'OrderCalcProfit',
   'StructureStop',
   'SYMBOL_VOLUME_MIN',
   'if(volume < minimum)',
   'M30SC-LIVE-ACK',
   'M30SC_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required M30 contract token missing: $token" }
}
$forbidden = @('martingale', 'averaging down', 'grid recovery', 'InpAllowMinLotRiskOverflow')
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden M30 contract token present: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $hash
   Lines = (Get-Content -LiteralPath $full).Count
   BrokerAccurateSizing = $true
   StructureStop = $true
   MinimumLotOverflow = $false
   RealTradingDefault = $false
}

