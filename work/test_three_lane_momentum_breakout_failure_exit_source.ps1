$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Trade_Ready_RC2.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Breakout_Failure_Exit_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = 'CBC2309B98AE3EC4969E52B4ADBD5E8A4EFCE8780E0654F5F9B1E9A36AD25EE4'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Momentum breakout-failure source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpMOUseBreakoutFailureExit = false',
   'InpMOBreakoutFailureMaximumBars = 3',
   'InpMOBreakoutFailureBufferATR = 0.05',
   'BreakoutFailureLevelKey(const ulong ticket)',
   'BreakoutFailureATRKey(const ulong ticket)',
   'RegisterBreakoutFailureState(ticket, breakoutLevel, atr)',
   'int openShift = iBarShift(_Symbol, InpMOSignalTimeframe, openTime, false)',
   'openShift < 1 || openShift > InpMOBreakoutFailureMaximumBars',
   'double closePrice = iClose(_Symbol, InpMOSignalTimeframe, 1)',
   'closePrice < breakoutLevel - buffer',
   'closePrice > breakoutLevel + buffer',
   'CloseOwnedPosition(m_trade, ticket, InpMOMagicNumber, closeReason)',
   'OpenPosition(true, atr, channelHigh)',
   'OpenPosition(false, atr, channelLow)',
   'ClearBreakoutFailureState(transaction.position)',
   'InpMOBreakoutFailureMaximumBars < 1',
   'InpMOBreakoutFailureBufferATR > 1.0',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Momentum breakout-failure source is missing required token: $token"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected entry-path change for $tradeToken" }
}
$baseCloseCount = ([regex]::Matches($base, [regex]::Escape('CloseOwnedPosition('))).Count
$forkCloseCount = ([regex]::Matches($fork, [regex]::Escape('CloseOwnedPosition('))).Count
if($forkCloseCount -ne $baseCloseCount + 1) { throw 'Expected exactly one new owned-position close path.' }
foreach($token in @('m_trade.PositionClose(', 'm_trade.PositionCloseBy(')) {
   if(([regex]::Matches($fork, [regex]::Escape($token))).Count -ne
      ([regex]::Matches($base, [regex]::Escape($token))).Count) {
      throw "Unexpected direct close path: $token"
   }
}
if($fork.IndexOf('InpRVRiskPercent = 0.45;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMORiskPercent = 0.15;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpATBRiskPercent = 0.10;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMaximumPortfolioOpenRiskPercent = 0.75;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMaximumAccountPositions = 3;', [StringComparison]::Ordinal) -lt 0) {
   throw 'Frozen base risk defaults changed.'
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   CompletedBarOnly = $true
   StoredPreBreakLevel = $true
   StoredEntryATR = $true
   ExactTicketOwnership = $true
   PersistentStateCleanup = $true
   NewEntryPaths = 0
   NewOwnedClosePaths = 1
   NewDirectClosePaths = 0
   RiskDefaultsUnchanged = $true
   RealAccountDefault = $false
}
