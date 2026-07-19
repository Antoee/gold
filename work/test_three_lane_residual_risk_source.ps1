$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Residual_Risk_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = '6FCAF941E0BA5BFD30C7286CFD9037D31912232D3BF40E020F672A67433ED53E'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Residual-risk source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpUseResidualRiskAllocation = false',
   'InpResidualRiskReservePercent = 0.05',
   'InpRVMaximumEntryRiskPercent = 0.45',
   'InpMOMaximumEntryRiskPercent = 0.15',
   'InpATBMaximumEntryRiskPercent = 0.10',
   'double RequestedLaneRiskPercent(const double baseRiskPercent',
   'double openRiskPercent = AccountWideOpenRiskPercent(hasUnprotected, positionCount)',
   'double expansionCap = InpMaximumPortfolioOpenRiskPercent -',
   'double availableRiskPercent = expansionCap - openRiskPercent',
   'return MathMin(maximumEntryRiskPercent, availableRiskPercent)',
   'RequestedLaneRiskPercent(InpRVRiskPercent',
   'RequestedLaneRiskPercent(InpMORiskPercent',
   'RequestedLaneRiskPercent(InpATBRiskPercent',
   'PostFillReconcile(m_trade, InpRVMagicNumber, buy, laneRiskPercent',
   'PostFillReconcile(m_trade, InpMOMagicNumber, buy, laneRiskPercent',
   'PostFillReconcile(m_trade, InpATBMagicNumber, buy, laneRiskPercent',
   'InpResidualRiskReservePercent >= InpMaximumPortfolioOpenRiskPercent',
   'InpRVMaximumEntryRiskPercent < InpRVRiskPercent',
   'InpMOMaximumEntryRiskPercent < InpMORiskPercent',
   'InpATBMaximumEntryRiskPercent < InpATBRiskPercent',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Residual-risk source is missing required token: $token"
   }
}

$allocatorMatch = [regex]::Match(
   $fork,
   'double RequestedLaneRiskPercent\([\s\S]*?\n\}(?=\r?\n\r?\ndouble ClosedPortfolioProfitSince)',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$allocatorMatch.Success) { throw 'Residual-risk allocator body could not be isolated.' }
foreach($forbiddenDependency in @('HistorySelect', 'HistoryDeal', 'ClosedPortfolioProfit', 'consecutive', 'drawdown')) {
   if($allocatorMatch.Value.IndexOf($forbiddenDependency, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome-dependent token found in allocator: $forbiddenDependency"
   }
}
foreach($forbiddenToken in @('martingale', 'averaging down', 'grid recovery', 'recovery sizing')) {
   if($fork.IndexOf($forbiddenToken, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden sizing/recovery token present: $forbiddenToken"
   }
}
foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected direct trade-path count for $tradeToken" }
}
if($fork.IndexOf('InpRVRiskPercent = 0.45;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMORiskPercent = 0.15;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMaximumPortfolioOpenRiskPercent = 0.75;', [StringComparison]::Ordinal) -lt 0) {
   throw 'Frozen base risk defaults changed.'
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   NewTradePaths = 0
   OutcomeIndependent = $true
   AccountWideExposureGuard = $true
   PostFillReconciliation = $true
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
