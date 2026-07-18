param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Asian_Range_Sweep.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw
$expectedHash = 'C757E57C98EFABE7C9A84EEE912D181539AF346DCDCD0B6758F9F0AE22C71EFB'

$required = @(
   '#property description "Date-independent XAUUSD M15 Asian-range sweep and reclaim research EA"',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'InpMaximumTradesPerDay = 1;',
   'bool AsianRangeLevels(const datetime signalBarTime,',
   'CopyRates(_Symbol, InpSignalTimeframe, rangeStart, rangeEnd - 1, rates)',
   'rangeATR < InpMinimumAsianRangeATR || rangeATR > InpMaximumAsianRangeATR',
   'double minimumSweep = MathMax(InpMinimumSweepATR * atr, InpMinimumSweepPoints * _Point);',
   'close1 >= asianRangeLow + reclaimDistance',
   'close1 <= asianRangeHigh - reclaimDistance',
   'wick / MathMax(body1, _Point) >= InpMinimumWickToBodyRatio',
   'TickVolumeAllows(1)',
   'OpenSweepPosition(buy, atr, rawStop, asianRangeHigh, asianRangeLow,',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'InpAccountWideBlockUnprotectedExposure = true;'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Missing source contract token: $token"
   }
}

foreach($forbidden in @(
   'PreviousDayLevels',
   'TryPreviousDaySweepEntry',
   'martingale',
   'averaging down',
   'grid recovery'
)) {
   if($text.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden stale or unsafe source token: $forbidden"
   }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne $expectedHash) { throw "Unexpected Asian-range source hash: $sourceHash" }

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $sourceHash
   AsianRangeHours = '00:00-06:00'
   EntryHours = '06:00-12:00'
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   RealTradingDefault = $false
}
