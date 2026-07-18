param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Trend_Liquidity_Reclaim.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw
$expectedHash = '67167ACC0BFEA04357EE17195C30320342DEE0D566F2C94E01CC1BF521F26002'

$required = @(
   '#property description "Date-independent XAUUSD M15 trend-aligned liquidity reclaim research EA"',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'InpMaximumTradesPerDay = 1;',
   'InpUseTrendEMAFilter = true;',
   'InpTrendEMAPeriod = 200;',
   'InpUseMinimumADXFilter = true;',
   'InpUsePostLossQuarantine = true;',
   'InpPostLossQuarantineDays = 14;',
   'ChannelBounds(2, InpLiquidityLookbackBars, liquidityHigh, liquidityLow)',
   'double minimumSweep = MathMax(InpMinimumSweepATR * atr, InpMinimumSweepPoints * _Point);',
   'close1 >= liquidityLow + reclaimDistance',
   'close1 <= liquidityHigh - reclaimDistance',
   'wick / MathMax(body1, _Point) >= InpMinimumWickToBodyRatio',
   'OpenReclaimPosition(buy, atr, rawStop, sweepDepth)',
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
   'AsianRangeLevels',
   'InpAsianRange',
   'InpUseAsianMidpointTarget',
   'martingale',
   'averaging down',
   'grid recovery'
)) {
   if($text.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden stale or unsafe source token: $forbidden"
   }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne $expectedHash) { throw "Unexpected trend-liquidity source hash: $sourceHash" }

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $sourceHash
   EntryHours = '09:00-11:00'
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   PostLossQuarantineDefaultDays = 14
   RealTradingDefault = $false
}
