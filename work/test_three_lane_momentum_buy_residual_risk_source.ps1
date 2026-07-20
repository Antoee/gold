$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Buy_Residual_Risk_Research.mq5'
$expectedBaseHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$expectedForkHash = '872028C76FDD4183E6266BB0E48125BB6B0F48EA3E77B9663B92A7F68B9ACD04'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Buy residual-risk source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   '#property version   "1.63"',
   'InpMOUseBuyResidualRisk = false',
   'InpMOBuyResidualRiskPercent = 0.20',
   'double baseLots = LotsForRisk(buy, entryPrice, stopPrice,',
   'if(baseLots <= 0.0)',
   'double requestedRiskPercent = InpMORiskPercent;',
   'if(InpMOUseBuyResidualRisk && buy)',
   'requestedRiskPercent = InpMOBuyResidualRiskPercent;',
   'PostFillReconcile(m_trade, InpMOMagicNumber, buy, requestedRiskPercent,',
   'InpMOBuyResidualRiskPercent <= InpMORiskPercent',
   'InpMOBuyResidualRiskPercent > InpMaximumPortfolioOpenRiskPercent',
   'InpRVRiskPercent + InpMORiskPercent + InpATBRiskPercent >',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Buy residual-risk source is missing required token: $token"
   }
}

$allocator = [regex]::Match(
   $fork,
   'double baseLots = LotsForRisk[\s\S]*?requestedRiskPercent = InpMOBuyResidualRiskPercent;[\s\S]*?LotsForRisk\(buy, entryPrice, stopPrice,[\s\S]*?requestedRiskPercent, InpMOMaximumPositionLots\);',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$allocator.Success) { throw 'Buy residual-risk allocator block could not be isolated.' }
foreach($forbidden in @('History', 'PositionGet', 'PositionSelect', 'AccountInfo', 'consecutive', 'drawdown', 'profit', 'loss', 'TimeCurrent')) {
   if($allocator.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, account-state, or calendar token found in allocator: $forbidden"
   }
}
if($allocator.Value.IndexOf('if(baseLots <= 0.0)', [StringComparison]::Ordinal) -gt
   $allocator.Value.IndexOf('requestedRiskPercent = InpMOBuyResidualRiskPercent;', [StringComparison]::Ordinal)) {
   throw 'Base-lot eligibility must be enforced before residual-risk sizing.'
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected trade-path count for $tradeToken" }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpRVMaximumPositionLots = 0.10;',
   'InpRVStrongSignalMaximumPositionLots = 0.15;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;',
   'InpMaximumPortfolioDailyLossPercent = 0.75;',
   'InpMaximumPortfolioWeeklyLossPercent = 1.25;',
   'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) {
      throw "Frozen risk default changed: $frozen"
   }
}

$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs + 2) {
   throw "Expected exactly two new inputs; base=$baseInputs fork=$forkInputs"
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   BaseLotEligibility = 'REQUIRED_BEFORE_RESIDUAL_SIZING'
   AllocationState = 'BUY_DIRECTION_ONLY'
   OutcomeIndependent = $true
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   BaseMomentumRiskPercent = 0.15
   MaximumBuyResidualRiskPercent = 0.20
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
