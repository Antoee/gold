param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_PrevDay_Sweep.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw

$required = @(
   '#property description "Date-independent XAUUSD M15 previous-day liquidity sweep research EA"',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'bool PreviousDayLevels(double &previousDayHigh, double &previousDayLow)',
   'previousDayHigh = iHigh(_Symbol, PERIOD_D1, 1);',
   'double minimumSweep = MathMax(InpMinimumSweepATR * atr, InpMinimumSweepPoints * _Point);',
   'close1 >= previousDayLow + reclaimDistance',
   'close1 <= previousDayHigh - reclaimDistance',
   'wick / MathMax(body1, _Point) >= InpMinimumWickToBodyRatio',
   'TickVolumeAllows(1)',
   'OpenSweepPosition(buy, atr, rawStop, previousDayHigh, previousDayLow)',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'InpAccountWideBlockUnprotectedExposure = true;'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Missing source contract token: $token" }
}

foreach($forbidden in @(
   'FvgSetup',
   'DetectNewFvgSetup',
   'TryFvgRetestEntry',
   'martingale',
   'averaging down',
   'grid recovery'
)) {
   if($text.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden stale or unsafe source token: $forbidden" }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne 'DE93CFC433C0F3A9B19A6F8D58AAF32894FC8FE6DC41F98A3745FD209C787E8E') { throw "Unexpected sweep source hash: $sourceHash" }

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $sourceHash
   PreviousDayShift = 1
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   RealTradingDefault = $false
}
