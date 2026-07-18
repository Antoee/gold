$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$basePath = Join-Path $PSScriptRoot "Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5"
$forkPath = Join-Path $PSScriptRoot "Professional_XAUUSD_Momentum_Breakout_Quality_Portfolio.mq5"
$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash
if($baseHash -ne "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302") {
   throw "Frozen RC2 source identity changed: $baseHash"
}
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash
if($forkHash -ne "7BCFE5C270F0B9B62121164877A88F0D6212C6B7090438400DBA9391D99C6F3A") {
   throw "Tested research source identity changed: $forkHash"
}
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
foreach($required in @(
   'InpMOUseBreakoutCandleQuality', 'InpMOMinimumBreakoutBodyPercent',
   'InpMOMinimumBreakoutCloseLocation', 'InpMOMinimumBreakoutRangeATR',
   'InpMOUseTickVolumeConfirmation', 'InpMOTickVolumeLookbackBars',
   'InpMOMinimumTickVolumeRatio', 'bool BreakoutQualityAllows(',
   'BreakoutQualityAllows(true, atr)', 'BreakoutQualityAllows(false, atr)',
   'input bool   InpAllowRealAccountTrading = false;'
)) {
   if($fork.IndexOf($required, [StringComparison]::Ordinal) -lt 0) {
      throw "Research source is missing: $required"
   }
}
foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'm_trade.PositionClose(', 'm_trade.PositionModify(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Trade path count changed for $tradeToken" }
}
if($fork.IndexOf('InpMORiskPercent = 0.15;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMaximumPortfolioOpenRiskPercent = 0.75;', [StringComparison]::Ordinal) -lt 0) {
   throw "Frozen risk defaults changed."
}
"MOMENTUM_BREAKOUT_QUALITY_SOURCE_TEST_PASS source=$forkHash"
