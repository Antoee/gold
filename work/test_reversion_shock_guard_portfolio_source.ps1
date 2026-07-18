$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$basePath = Join-Path $PSScriptRoot "Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5"
$forkPath = Join-Path $PSScriptRoot "Professional_XAUUSD_Reversion_Shock_Guard_Portfolio.mq5"
$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash
if($baseHash -ne "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302") {
   throw "Frozen RC2 source identity changed: $baseHash"
}
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash
if($forkHash -ne "A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9") {
   throw "Tested shock-guard source identity changed: $forkHash"
}
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
foreach($required in @(
   'InpRVUseMinimumBodyGate = false;',
   'InpRVMinimumBodyPercent = 25.0;',
   'double bodyPercent = 100.0 * MathAbs(close1 - open1) / range1;',
   'if(InpRVUseMinimumBodyGate && bodyPercent < InpRVMinimumBodyPercent)',
   'InpRVMinimumBodyPercent < 0.0 || InpRVMinimumBodyPercent > 100.0',
   'input bool   InpAllowRealAccountTrading = false;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;'
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
if($fork.IndexOf('InpRVRiskPercent = 0.45;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMORiskPercent = 0.15;', [StringComparison]::Ordinal) -lt 0) {
   throw "Frozen lane-risk defaults changed."
}

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSourceSha256 = $baseHash
   BodyGateDefault = $false
   RealTradingDefault = $false
   TradePathCountsPreserved = $true
}
