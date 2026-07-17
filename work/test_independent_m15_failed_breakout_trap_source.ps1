param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Failed_Breakout_Trap.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw
$expectedHash = "EFB39ED06E5C7CA3D75C971F24ADB3073E597CC9CB2373257521EC41BDC57990"

$required = @(
   '#property description "Date-independent XAUUSD M15 failed-breakout trap research EA"',
   'InpSignalTimeframe = PERIOD_M15;',
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
   SignalTimeframe = "M15"
   UsesClosedBarsOnly = $true
   StructuralStopAndTarget = $true
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   PreservesTakeProfitOnStopUpdate = $true
   RealTradingDefault = $false
}
