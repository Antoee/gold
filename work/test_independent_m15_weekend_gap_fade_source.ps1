param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Weekend_Gap_Fade.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
$text = Get-Content -LiteralPath $sourceFull -Raw

$required = @(
   '#property description "Date-independent XAUUSD M15 weekend-gap fade research EA"',
   'InpUseRealAccountSafetyLock = true;',
   'InpAllowRealAccountTrading = false;',
   'InpEnforceInitialBalanceContract = true;',
   'InpExpectedInitialBalance = 10000.0;',
   'InpRiskPercent = 0.10;',
   'InpRequireEmptyAccountAtEntry = true;',
   'bool IsFirstBarAfterWeekend(MqlRates &firstBar, MqlRates &priorBar)',
   'priorTime.day_of_week == 5',
   'firstBar.time - priorBar.time >= 24 * 3600',
   'double signedGap = firstBar.open - priorBar.close;',
   'confirmationFraction < InpMinimumConfirmationFraction',
   'rawStop = buy ? firstBar.low - InpStopBufferATR * atr',
   'targetDistance / stopDistance < InpMinimumRewardRisk',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'return NormalizeVolume(riskMoney / lossPerLot);',
   'if(volume < minimum)',
   'return 0.0;',
   'PositionsTotal() > 0',
   'trade.PositionModify(ticket, newStop, takeProfit);'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Missing source contract token: $token"
   }
}

foreach($forbidden in @(
   'martingale',
   'grid recovery',
   'averaging down',
   'InpLotMultiplier',
   'MathMax(minimum, volume)'
)) {
   if($text.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden unsafe or out-of-contract source token: $forbidden"
   }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne '0B0DB2770C3CF7170C248A94B829932166F9ADA42ACB3956B7FC4450993C8121') {
   throw "Unexpected weekend-gap source hash: $sourceHash"
}

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $sourceHash
   DiscoveryCutoff = '2020-12-31'
   RiskUsesOrderCalcProfit = $true
   ForcesMinimumLot = $false
   RealTradingDefault = $false
}
