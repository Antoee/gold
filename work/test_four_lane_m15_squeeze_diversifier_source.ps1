$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Diversifier_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Squeeze-diversifier source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.66"',
   'InpSQEnabled = false',
   'InpSQMagicNumber = 26071772',
   'InpSQRiskPercent = 0.10',
   'InpSQSignalTimeframe = PERIOD_M15',
   'InpSQBreakoutLookbackBars = 8',
   'InpSQMaximumBreakoutChannelATR = 3.50',
   'InpSQTakeProfitR = 1.50',
   'InpSQMaximumHoldBars = 32',
   'class CSqueezeDiversifierLane',
   'AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason)',
   'PostFillReconcile(m_trade, InpSQMagicNumber, buy, InpSQRiskPercent',
   'CloseOwnedPosition(m_trade, ticket, InpSQMagicNumber',
   'ModifyOwnedPosition(m_trade, ticket, InpSQMagicNumber',
   '(InpSQEnabled && InpMaximumAccountPositions < 4)',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Squeeze-diversifier source is missing required token: $token"
   }
}

$entry = [regex]::Match(
   $fork,
   'void TryEntry\(const double atr\)[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$entry.Success) { throw 'Squeeze entry block could not be isolated.' }
foreach($forbidden in @('HistoryDeal', 'DEAL_PROFIT', 'profit', 'loss', 'drawdown', 'balance', 'equity')) {
   if($entry.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome token found in squeeze entry block: $forbidden"
   }
}

$expectedDeltas = [ordered]@{
   'm_trade.Buy(' = 1
   'm_trade.Sell(' = 1
   'CloseOwnedPosition(' = 2
   'ModifyOwnedPosition(' = 1
}
foreach($tradeToken in $expectedDeltas.Keys) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount + $expectedDeltas[$tradeToken]) {
      throw "Unexpected trade-path count for $tradeToken; base=$baseCount fork=$forkCount"
   }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;', 'InpMORiskPercent = 0.15;', 'InpATBRiskPercent = 0.10;',
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
if($baseInputs -ne 185 -or $forkInputs -ne 247) {
   throw "Unexpected input counts; base=$baseInputs fork=$forkInputs"
}

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;FeatureDefault='DISABLED'
   Eligibility='COMPLETED_M15_SQUEEZE_BREAKOUT_WITH_H1_TREND_ALIGNMENT'
   OutcomeIndependent=$true;NewEntryPaths=2;NewClosePaths=2;NewModifyPaths=1
   SqueezeCenterRiskPercent=0.10;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
