param(
   [string]$SourcePath = "work\Independent_XAUUSD_H1_PrevWeek_Break_Retest.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw
$expectedHash = "1A5799C5829D0E7108F60CBB331EB98BE39DACD0422C592020B6973C17147F26"

$required = @(
   '#property description "Date-independent XAUUSD H1 previous-week break-and-retest research EA"',
   'InpSignalTimeframe = PERIOD_H1;',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'bool PreviousWeekLevels(double &previousWeekHigh, double &previousWeekLow)',
   'previousWeekHigh = iHigh(_Symbol, PERIOD_W1, 1);',
   'previousWeekLow = iLow(_Symbol, PERIOD_W1, 1);',
   'bool RegisterPreviousWeekBreak(const double atr)',
   'bool TryActiveRetest(const double atr)',
   'barTime <= g_setup.breakoutBarTime',
   'low1 <= level + tolerance',
   'high1 >= level - tolerance',
   'OpenBreakRetestPosition(buy, atr, rawStop)',
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
if($sourceHash -ne $expectedHash) { throw "Unexpected weekly break-retest source hash: $sourceHash" }

[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $sourceHash
   SignalTimeframe = "H1"
   PreviousWeekShift = 1
   RequiresLaterRetestBar = $true
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   PreservesTakeProfitOnStopUpdate = $true
   RealTradingDefault = $false
}
