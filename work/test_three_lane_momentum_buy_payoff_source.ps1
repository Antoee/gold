$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Buy_Payoff_Research.mq5'
$expectedBaseHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$expectedForkHash = '52A2C2942931518EB28A8CB1BF1DD72D9C4BF07E6AC18F3C577D4971153A3923'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Buy-payoff source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.64"',
   'InpMOUseBuyTakeProfitR = false',
   'InpMOBuyTakeProfitR = 2.50',
   'double requestedTakeProfitR = InpMOTakeProfitR;',
   'if(InpMOUseBuyTakeProfitR && buy)',
   'requestedTakeProfitR = InpMOBuyTakeProfitR;',
   'entryPrice + requestedTakeProfitR * stopDistance',
   'entryPrice - requestedTakeProfitR * stopDistance',
   'InpMOBuyTakeProfitR <= InpMOTakeProfitR',
   'InpMOBuyTakeProfitR > 6.0',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Buy-payoff source is missing required token: $token"
   }
}

$allocator = [regex]::Match(
   $fork,
   'double requestedTakeProfitR = InpMOTakeProfitR;[\s\S]*?requestedTakeProfitR = InpMOBuyTakeProfitR;[\s\S]*?double takeProfit = NormalizeDouble[\s\S]*?_Digits\);',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$allocator.Success) { throw 'Buy-payoff allocator block could not be isolated.' }
foreach($forbidden in @('History', 'PositionGet', 'PositionSelect', 'AccountInfo', 'consecutive', 'drawdown', 'TimeCurrent')) {
   if($allocator.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, account-state, or calendar token found in payoff allocator: $forbidden"
   }
}
foreach($outcomeWord in @('profit','loss')) {
   if([regex]::IsMatch($allocator.Value, "(?i)\b$outcomeWord\b")) {
      throw "Outcome word found in payoff allocator: $outcomeWord"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected trade-path count for $tradeToken" }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;', 'InpMORiskPercent = 0.15;', 'InpATBRiskPercent = 0.10;',
   'InpRVMaximumPositionLots = 0.10;', 'InpRVStrongSignalMaximumPositionLots = 0.15;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;', 'InpMaximumPortfolioEquityDrawdownPercent = 5.00;',
   'InpMaximumPortfolioDailyLossPercent = 0.75;', 'InpMaximumPortfolioWeeklyLossPercent = 1.25;',
   'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen default changed: $frozen" }
}
$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs + 2) { throw "Expected exactly two new inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;FeatureDefault='DISABLED'
   AllocationState='BUY_DIRECTION_ONLY';OutcomeIndependent=$true;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   BaseMomentumTakeProfitR=2.00;FrozenCenterBuyTakeProfitR=2.50;MomentumRiskPercent=0.15
   PortfolioCapPercent=0.75;RealAccountDefault=$false
}
