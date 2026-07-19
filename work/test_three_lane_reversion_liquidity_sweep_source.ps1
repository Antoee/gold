$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Liquidity_Sweep_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = 'C5AB825B9F8BB701D02E4144E0062E79CC5A64FCECE04C6057C0A24755AD1A65'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Liquidity-sweep source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseLiquiditySweepGate = false',
   'InpRVLiquiditySweepLookbackBars = 5',
   'InpRVMinimumLiquiditySweepATR = 0.0',
   'bool LiquiditySweepAllows(const bool buy',
   'int lookback = MathMax(2, InpRVLiquiditySweepLookbackBars)',
   'double minimumSweep = MathMax(_Point,',
   'if(!LowestLow(2, lookback, priorExtreme))',
   'return priorExtreme - signalLow >= minimumSweep && signalClose > priorExtreme;',
   'if(!HighestHigh(2, lookback, priorExtreme))',
   'return signalHigh - priorExtreme >= minimumSweep && signalClose < priorExtreme;',
   'if(!LiquiditySweepAllows(buy, high1, low1, close1, atr))',
   'InpRVLiquiditySweepLookbackBars < 2',
   'InpRVMinimumLiquiditySweepATR > 1.0',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Liquidity-sweep source is missing required token: $token"
   }
}

$gateMatch = [regex]::Match(
   $fork,
   'bool LiquiditySweepAllows\([\s\S]*?\n   \}(?=\r?\n\r?\n   bool OpenPosition)',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$gateMatch.Success) { throw 'Liquidity-sweep gate body could not be isolated.' }
foreach($forbidden in @('iOpen(_Symbol, InpRVSignalTimeframe, 0)', 'iHigh(_Symbol, InpRVSignalTimeframe, 0)', 'iLow(_Symbol, InpRVSignalTimeframe, 0)', 'iClose(_Symbol, InpRVSignalTimeframe, 0)', 'HistorySelect', 'HistoryDeal', 'profit', 'loss', 'drawdown')) {
   if($gateMatch.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden lookahead or outcome token found in liquidity-sweep gate: $forbidden"
   }
}

$signalIndex = $fork.IndexOf('if(buy == sell)', [StringComparison]::Ordinal)
$gateIndex = $fork.IndexOf('if(!LiquiditySweepAllows(buy, high1, low1, close1, atr))', [StringComparison]::Ordinal)
$openIndex = $fork.IndexOf('OpenPosition(buy, entryPrice, stopPrice, targetPrice, diEdge);', [StringComparison]::Ordinal)
if($signalIndex -lt 0 -or $gateIndex -le $signalIndex -or $openIndex -le $gateIndex) {
   throw 'Liquidity-sweep confirmation is not ordered between signal formation and entry.'
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected direct trade-path count for $tradeToken" }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen risk default changed: $frozen" }
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   CompletedSignalBar = 1
   PriorExtremeStartShift = 2
   NewTradePaths = 0
   OutcomeIndependent = $true
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
