$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Risk_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Rejection_Quality_Research.mq5'
$expectedBaseHash = '36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF'
$expectedForkHash = 'BD1E4035A144127BF8120B7A3C31F0A6585CC30CB508F4D353C45BD7E87ED563'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen strong-signal source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Reversion rejection-quality source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseStrongSignalRisk = false',
   'InpRVStrongSignalMinimumBodyRatio = 0.15',
   'InpRVStrongSignalRiskPercent = 0.60',
   'InpRVUseStrongRejectionQuality = false',
   'InpRVStrongSignalMinimumDirectionalWickPercent = 25.0',
   'double adjustedRiskReward = adjustedReward / adjustedRisk;',
   'double directionalBody = buy ? close1 - open1 : open1 - close1;',
   'double signalBodyRatio = MathMax(0.0, directionalBody) / range1;',
   'double signalWickPercent = buy ? lowerWickPercent : upperWickPercent;',
   'signalBodyRatio >= InpRVStrongSignalMinimumBodyRatio',
   '!InpRVUseStrongRejectionQuality ||',
   'signalWickPercent >= InpRVStrongSignalMinimumDirectionalWickPercent',
   'requestedRiskPercent = InpRVStrongSignalRiskPercent;',
   'LotsForRisk(buy, entryPrice, stopPrice,',
   'requestedRiskPercent, InpRVMaximumPositionLots)',
   'PostFillReconcile(m_trade, InpRVMagicNumber, buy, requestedRiskPercent,',
   'InpRVStrongSignalRiskPercent > InpMaximumPortfolioOpenRiskPercent',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Reversion rejection-quality source is missing required token: $token"
   }
}

$allocator = [regex]::Match(
   $fork,
   'double directionalBody = buy \? close1 - open1 : open1 - close1;[\s\S]*?requestedRiskPercent, signalBodyRatio\);',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$allocator.Success) { throw 'Reversion rejection-quality allocator block could not be isolated.' }
foreach($forbidden in @('History', 'PositionGet', 'PositionSelect', 'AccountInfo', 'consecutive', 'drawdown', 'profit', 'loss', 'TimeCurrent')) {
   if($allocator.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, account-state, or calendar token found in allocator: $forbidden"
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
   SignalData = 'COMPLETED_H1_BODY_AND_DIRECTIONAL_REJECTION_WICK'
   OutcomeIndependent = $true
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   BaseRiskPercent = 0.45
   DefaultStrongRiskPercent = 0.60
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
