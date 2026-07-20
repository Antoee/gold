$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_D1_Extreme_Guard_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '6493A292B8126FD03596A0062BBC065144AEE949D63E55E7B4F10D8469989A11'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen cooldown leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "D1 extreme-guard source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.67"', 'InpMOUseMaximumD1MomentumStrength = false',
   'InpMOMaximumAbsoluteD1MomentumPercent = 18.0',
   'int MomentumDirection(double &absoluteMomentumPercent)',
   'return MomentumDirection(ignoredMomentumPercent);',
   'absoluteMomentumPercent = 100.0 * MathAbs(recentClose / pastClose - 1.0);',
   'absoluteMomentumPercent > InpMOMaximumAbsoluteD1MomentumPercent',
   'input double InpMORiskPercent = 0.15;', 'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;', 'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "D1 extreme-guard source is missing required token: $token"
   }
}

$strengthBlock = [regex]::Match(
   $fork,
   'int MomentumDirection\(double &absoluteMomentumPercent\)[\s\S]*?bool RegimeAllows\(const bool buy, const double closePrice, const double atr\)[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$strengthBlock.Success) { throw 'D1 extreme-guard regime block could not be isolated.' }
foreach($forbidden in @('DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','consecutive','drawdown','ACCOUNT_PROFIT')) {
   if($strengthBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome or account-performance token found in D1 extreme-guard block: $forbidden"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected trade-path count for $tradeToken" }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;', 'InpMORiskPercent = 0.15;', 'InpATBRiskPercent = 0.10;',
   'InpMOTakeProfitR = 2.00;', 'InpRVMaximumPositionLots = 0.10;',
   'InpRVStrongSignalMaximumPositionLots = 0.15;', 'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;', 'InpMaximumPortfolioDailyLossPercent = 0.75;',
   'InpMaximumPortfolioWeeklyLossPercent = 1.25;', 'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen default changed: $frozen" }
}
$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs + 2) { throw "Expected exactly two new inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;FeatureDefault='DISABLED'
   StrengthState='MAXIMUM_ABSOLUTE_126_BAR_D1_CLOSE_RETURN';OutcomeIndependent=$true
   NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0;FrozenCenterPercent=18.0
   MomentumRiskPercent=0.15;MomentumTakeProfitR=2.00;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
