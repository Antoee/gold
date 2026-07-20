$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Partial_Runner_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Momentum partial-runner source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpMOUsePartialRunner = false',
   'InpMOPartialClosePercent = 60.0',
   'InpMOPartialTriggerR = 2.00',
   'InpMOPartialTargetR = 4.00',
   'InpMOPartialStopLockR = 1.25',
   'bool CloseOwnedPositionPartial(CTrade &trade,',
   'trade.PositionClosePartial(ticket, closeVolume)',
   'MathAbs(resultingVolume - expectedVolume) > tolerance',
   'bool PositionIdentifierOpen(const ulong positionIdentifier)',
   'double ClosedPositionExitProfit(const ulong positionIdentifier)',
   'PositionIdentifierOpen(positionIdentifier)',
   'GlobalVariableGet(RunnerDoneKey(ticket)) > 0.5 ||',
   'currentVolume < initialVolume - tolerance',
   'if(!ProtectRunnerPosition(ticket, buy) || !SelectOwnedPosition(ticket, InpMOMagicNumber))',
   'PartialVolumes(lots, closeVolume, remainingVolume)',
   'RegisterRunnerState(ticket, PositionGetDouble(POSITION_VOLUME))',
   'if(transaction.position > 0 && !PositionIdentifierOpen(transaction.position))',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Momentum partial-runner source is missing required token: $token"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected entry-path count for $tradeToken" }
}
if(([regex]::Matches($fork, '\.PositionClosePartial\(')).Count -ne 1) {
   throw 'Exactly one raw partial-close send site is required.'
}

$partialWrapper = [regex]::Match(
   $fork,
   'bool CloseOwnedPositionPartial\(CTrade &trade,[\s\S]*?\n\}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$partialWrapper.Success) { throw 'Partial-close wrapper could not be isolated.' }
$ownershipIndex = $partialWrapper.Value.IndexOf('SelectOwnedPosition(ticket, magic)', [StringComparison]::Ordinal)
$sendIndex = $partialWrapper.Value.IndexOf('trade.PositionClosePartial(ticket, closeVolume)', [StringComparison]::Ordinal)
$resultIndex = $partialWrapper.Value.IndexOf('TradeResultAllows(trade, false)', [StringComparison]::Ordinal)
$remainderIndex = $partialWrapper.Value.IndexOf('MathAbs(resultingVolume - expectedVolume)', [StringComparison]::Ordinal)
if($ownershipIndex -lt 0 -or $sendIndex -le $ownershipIndex -or
   $resultIndex -le $sendIndex -or $remainderIndex -le $resultIndex) {
   throw 'Partial-close ownership/result/remainder confirmation order changed.'
}

$manager = [regex]::Match(
   $fork,
   'void ManagePartialRunner\(\)[\s\S]*?\n   \}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$manager.Success) { throw 'Partial-runner manager could not be isolated.' }
$protectIndex = $manager.Value.LastIndexOf('ProtectRunnerPosition(ticket, buy)', [StringComparison]::Ordinal)
$partialIndex = $manager.Value.IndexOf('CloseOwnedPositionPartial(', [StringComparison]::Ordinal)
if($protectIndex -lt 0 -or $partialIndex -le $protectIndex) {
   throw 'The runner stop must be confirmed before the partial close.'
}

foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpRVMaximumPositionLots = 0.10;',
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
if($forkInputs -ne $baseInputs + 5) {
   throw "Expected exactly five new inputs; base=$baseInputs fork=$forkInputs"
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   NewEntryPaths = 0
   RawPartialCloseSites = 1
   PartialOwnershipConfirmed = $true
   PartialRemainderConfirmed = $true
   ProtectionBeforePartial = $true
   RestartReplayGuard = $true
   PositionLevelLossAccounting = $true
   UnsplittableTradesRetainBaselineTarget = $true
   InitialRiskChanged = $false
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
