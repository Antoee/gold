$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$expectedBaseHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$expectedForkHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Exit-cooldown source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.65"', 'InpMOUseSameSideExitCooldown = false',
   'InpMOSameSideExitCooldownMinutes = 60', 'datetime LastExitTimeForSide(const bool buy)',
   'ENUM_DEAL_TYPE closingDealType = buy ? DEAL_TYPE_SELL : DEAL_TYPE_BUY;',
   '(ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMOMagicNumber',
   'entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY',
   'HistoryDealGetInteger(ticket, DEAL_TYPE) != closingDealType',
   'bool ExitCooldownAllows(const bool buy)', 'if(ExitCooldownAllows(true))',
   'if(ExitCooldownAllows(false))', 'InpMOSameSideExitCooldownMinutes > 1440',
   'input double InpMORiskPercent = 0.15;', 'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;', 'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Exit-cooldown source is missing required token: $token"
   }
}

$historyBlock = [regex]::Match(
   $fork,
   'datetime LastExitTimeForSide\(const bool buy\)[\s\S]*?bool ExitCooldownAllows\(const bool buy\)[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$historyBlock.Success) { throw 'Exit-cooldown history block could not be isolated.' }
foreach($forbidden in @('DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','consecutive','drawdown','ACCOUNT_PROFIT')) {
   if($historyBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome or account-performance token found in exit-cooldown block: $forbidden"
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
   CooldownState='SAME_SYMBOL_MAGIC_AND_POSITION_SIDE';OutcomeIndependent=$true
   NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0;FrozenCenterMinutes=60
   MomentumRiskPercent=0.15;MomentumTakeProfitR=2.00;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
