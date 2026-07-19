$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$parentPath = Join-Path $repo 'work\Independent_XAUUSD_M15_Dual_Regime_Portfolio.mq5'
$forkPath = Join-Path $repo 'work\Independent_XAUUSD_M15_Dual_Regime_Normalized_Stop.mq5'
$expectedParentHash = 'DEA3B16FB2D14E4A1253B422CCE80AEC4CB49DCF03067EDBCE96008F694FA5E1'
$expectedForkHash = 'E6AB84CA7780A47FDE04A01CB74966204220B91B2DA97B65F1095066A10D2F50'

$parentHash = (Get-FileHash -LiteralPath $parentPath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($parentHash -ne $expectedParentHash) { throw "Frozen dual-regime parent identity changed: $parentHash" }
if($forkHash -ne $expectedForkHash) { throw "Normalized-stop source identity changed: $forkHash" }

$parent = Get-Content -LiteralPath $parentPath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   '#property version   "1.01"',
   'InpSignalTimeframe = PERIOD_M15',
   'InpEnableVolumeClimax = true',
   'InpEnableVolatilitySqueeze = true',
   'InpMaximumStopPriceDistance = 6.00',
   'InpUsePriceNormalizedStopCap = false',
   'InpMaximumStopPricePercent = 0.30',
   'maximumPriceDistance = entryPrice * InpMaximumStopPricePercent / 100.0;',
   'if(maximumPriceDistance > 0.0 && stopDistance > maximumPriceDistance)',
   'InpMaximumStopPricePercent <= 0.0 || InpMaximumStopPricePercent > 5.0',
   'InpRiskPercent = 0.10',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpUseAccountWideExposureGuard = true',
   'InpAllowRealAccountTrading = false',
   'M15DRP_DIAGNOSTIC',
   'M15DRP_VCR_BUY',
   'M15DRP_SQ_BUY'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Normalized-stop source is missing required token: $token"
   }
}

$stopFunction = [regex]::Match(
   $fork,
   'bool FinalizeStructureStop\([\s\S]*?\n\}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$stopFunction.Success) { throw 'FinalizeStructureStop could not be isolated.' }
foreach($forbidden in @('History', 'PositionGet', 'PositionSelect', 'consecutive', 'drawdown', 'profit', 'loss', 'TimeCurrent')) {
   if($stopFunction.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, position, or calendar token found in stop-normalization function: $forbidden"
   }
}

foreach($tradeToken in @('trade.Buy(', 'trade.Sell(', 'trade.PositionClose(', 'trade.PositionModify(')) {
   $parentCount = ([regex]::Matches($parent, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $parentCount) { throw "Unexpected trade-path count for $tradeToken" }
}
$parentInputCount = ([regex]::Matches($parent, '(?m)^input\s+')).Count
$forkInputCount = ([regex]::Matches($fork, '(?m)^input\s+')).Count
if($forkInputCount -ne $parentInputCount + 2) {
   throw "Expected exactly two new inputs; parent=$parentInputCount fork=$forkInputCount"
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowMinLotRiskOverflow')) {
   if($fork.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden risk token present: $token"
   }
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   ParentSha256 = $parentHash
   FeatureDefault = 'DISABLED'
   Normalization = 'ENTRY_PRICE_PERCENT'
   SignalChanges = 0
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   BrokerAccurateSizing = $true
   MinimumLotOverflow = $false
   AccountWideExposureGuard = $true
   RealTradingDefault = $false
}
