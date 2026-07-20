$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Risk_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_High_Water_Risk_Research.mq5'
$expectedBaseHash = '36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF'
$expectedForkHash = '38CA497BB6E0E013927B2FAC2C4D4350AFC476C8EAC837FACE6C6D0991B5D232'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen strong-signal source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "High-water risk source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseStrongSignalDrawdownThrottle = false',
   'InpRVStrongSignalFullRiskMaximumDrawdownPercent = 0.30',
   'bool CurrentPortfolioDrawdownPercent(double &drawdownPercent)',
   'double equity = AccountInfoDouble(ACCOUNT_EQUITY);',
   'double peakEquity = MathMax(g_peakEquity, equity);',
   'drawdownPercent = MathMax(0.0, 100.0 * (peakEquity - equity) / peakEquity);',
   'double requestedRiskPercent = InpRVRiskPercent;',
   'bool fullStrongRiskAllowed = !InpRVUseStrongSignalDrawdownThrottle ||',
   'portfolioDrawdownPercent <=',
   'InpRVStrongSignalFullRiskMaximumDrawdownPercent',
   'InpRVUseStrongSignalRisk && fullStrongRiskAllowed &&',
   'requestedRiskPercent = InpRVStrongSignalRiskPercent;',
   'PostFillReconcile(m_trade, InpRVMagicNumber, buy, requestedRiskPercent,',
   '!InpRVUseStrongSignalRisk ||',
   'InpRVStrongSignalFullRiskMaximumDrawdownPercent >',
   'InpMaximumPortfolioEquityDrawdownPercent',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "High-water risk source is missing required token: $token"
   }
}

$allocator = [regex]::Match(
   $fork,
   'double directionalBody = buy \? close1 - open1 : open1 - close1;[\s\S]*?requestedRiskPercent, signalBodyRatio, portfolioDrawdownPercent\);',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$allocator.Success) { throw 'High-water risk allocator block could not be isolated.' }
foreach($forbidden in @('History', 'PositionGet', 'PositionSelect', 'TimeCurrent', 'consecutive', 'profit', 'loss')) {
   if($allocator.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Trade-outcome, position-outcome, or calendar token found in allocator: $forbidden"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(', 'LotsForRisk(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected trade-path count for $tradeToken" }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;',
   'InpMaximumPortfolioDailyLossPercent = 0.75;',
   'InpMaximumPortfolioWeeklyLossPercent = 1.25;',
   'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen risk default changed: $frozen" }
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   RiskDirection = 'REDUCE_TO_BASE_DURING_DRAWDOWN'
   PeakState = 'EXISTING_PORTFOLIO_EQUITY_HIGH_WATER'
   MissingStateBehavior = 'FAIL_SAFE_TO_BASE_RISK'
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   BaseRiskPercent = 0.45
   DefaultStrongRiskPercent = 0.60
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
