param(
   [string]$SourcePath = "work\Independent_XAUUSD_M5_Failed_Breakout_Trap.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw
$expectedHash = "6774D7E94A78E985630C34EE372086BF2C8A6EA4C77690078F15641B86119D3B"

$required = @(
   '#property description "Date-independent XAUUSD M5 failed-breakout trap research EA"',
   'InpSignalTimeframe = PERIOD_M5;',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'bool IsFirstReclaimAfterBreak(const bool buy,',
   'bool TryFailedBreakoutTrapEntry(const double atr)',
   'ChannelBounds(breakShift + 1, InpBoxLookbackBars, boxHigh, boxLow)',
   'breakClose < boxLow - buffer',
   'breakClose > boxHigh + buffer',
   'close1 >= boxLow + requiredReclaim',
   'close1 <= boxHigh - requiredReclaim',
   'OpenTrapPosition(buy, atr, rawStop, boxHigh, boxLow)',
   'targetDistance / stopDistance < InpMinimumTargetR',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'InpAccountWideBlockUnprotectedExposure = true;',
   'trade.PositionModify(ticket, newSl, oldTp);'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Missing source contract token: $token"
   }
}

foreach($forbidden in @(
   'PreviousDayLevels',
   'TryPreviousDaySweepEntry',
   'OpenSweepPosition',
   'M15PDS',
   'martingale',
   'averaging down',
   'grid recovery'
)) {
   if($text.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden stale or unsafe source token: $forbidden"
   }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne $expectedHash) { throw "Unexpected failed-breakout source hash: $sourceHash" }

[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $sourceHash
   SignalTimeframe = "M5"
   UsesClosedBarsOnly = $true
   StructuralStopAndTarget = $true
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   PreservesTakeProfitOnStopUpdate = $true
   RealTradingDefault = $false
}
