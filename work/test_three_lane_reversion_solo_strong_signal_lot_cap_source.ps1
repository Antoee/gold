$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Solo_Strong_Signal_Lot_Cap_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '726BCABFA64C25FA3D22E78B41AB4868EA8D5235609294F7ED68DC3DB9088EEE'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Solo-cap source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.66"',
   'InpRVUseSoloStrongSignalLotCap = false',
   'InpRVSoloStrongSignalMaximumPositionLots = 0.18',
   'int OtherManagedLanePositionCount()',
   'IsPortfolioMagic(magic) && magic != InpRVMagicNumber',
   'signalBodyRatio >= InpRVStrongSignalMinimumBodyRatio &&',
   'OtherManagedLanePositionCount() == 0',
   'requestedMaximumPositionLots = InpRVSoloStrongSignalMaximumPositionLots;',
   '!InpRVUseStrongSignalLotCap ||',
   'InpRVSoloStrongSignalMaximumPositionLots <= InpRVStrongSignalMaximumPositionLots',
   'input double InpRVRiskPercent = 0.45;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Solo-cap source is missing required token: $token"
   }
}

$helper = [regex]::Match(
   $fork,
   'int OtherManagedLanePositionCount\(\)[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$helper.Success) { throw 'Solo-position helper could not be isolated.' }
foreach($forbidden in @('History', 'DEAL_', 'profit', 'loss', 'drawdown', 'balance', 'equity', 'TimeCurrent')) {
   if($helper.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome or calendar token found in solo-position helper: $forbidden"
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
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;',
   'InpMaximumPortfolioDailyLossPercent = 0.75;',
   'InpMaximumPortfolioWeeklyLossPercent = 1.25;',
   'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen default changed: $frozen" }
}
$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs + 2) { throw "Expected exactly two new inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;FeatureDefault='DISABLED'
   Eligibility='COMPLETED_H1_STRONG_SIGNAL_AND_NO_OTHER_MANAGED_LANE_POSITION'
   OutcomeIndependent=$true;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   ReversionRiskPercent=0.45;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
