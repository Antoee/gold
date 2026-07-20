$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Adaptive_Agreement_Research.mq5'
$expectedBaseHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$expectedForkHash = '6402A284BE2C4BDBEC2F44B8851650C64A6AEBAD87A35CF8CA2BD8A0275206D2'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Agreement source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   '#property version   "1.63"',
   'InpMOUseAdaptiveAgreementRisk = false',
   'InpMOAdaptiveAgreementRiskPercent = 0.25',
   'PositionGetString(POSITION_SYMBOL) == _Symbol',
   '(ulong)PositionGetInteger(POSITION_MAGIC) == InpATBMagicNumber',
   'PositionGetInteger(POSITION_TYPE) == requiredType',
   'double requestedRiskPercent = EntryRiskPercent(buy, adaptiveAgreement);',
   'requestedRiskPercent, InpMOMaximumPositionLots);',
   'PostFillReconcile(m_trade, InpMOMagicNumber, buy, requestedRiskPercent,',
   'MTSM_XA_BUY',
   'MTSM_XA_SELL',
   'adaptive agreement allocation',
   'InpMOAdaptiveAgreementRiskPercent <= InpMORiskPercent',
   'InpMOAdaptiveAgreementRiskPercent > InpMaximumPortfolioOpenRiskPercent',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Agreement source is missing required token: $token"
   }
}

$allocator = [regex]::Match(
   $fork,
   'double EntryRiskPercent\(const bool buy, bool &adaptiveAgreement\)[\s\S]*?return InpMORiskPercent;\s*\}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$allocator.Success) { throw 'Agreement allocator block could not be isolated.' }
foreach($forbidden in @('History', 'AccountInfo', 'consecutive', 'drawdown', 'profit', 'loss', 'TimeCurrent')) {
   if($allocator.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, account-performance, or calendar token found in allocator: $forbidden"
   }
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
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen risk default changed: $frozen" }
}

$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs + 2) { throw "Expected exactly two new inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   EntryState = 'EXISTING_SAME_SYMBOL_DIRECTION_ATB_POSITION'
   OutcomeIndependent = $true
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   BaseMomentumRiskPercent = 0.15
   AgreementRiskPercent = 0.25
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
