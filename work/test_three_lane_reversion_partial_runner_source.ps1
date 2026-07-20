$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Lot_Cap_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Partial_Runner_Research.mq5'
$expectedBaseHash = 'C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91'
$expectedForkHash = '614DCF5B0C55DF25DABDCF903C3193A0CE248AA2671788A400B5C39A4209F719'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Partial-runner source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseStrongSignalPartialRunner = false',
   'InpRVPartialRunnerClosePercent = 80.0',
   'InpRVPartialRunnerTargetMultiplier = 2.00',
   'InpRVPartialRunnerStopLockR = 0.50',
   'bool CloseOwnedPositionPartial(CTrade &trade,',
   'SelectOwnedPosition(ticket, magic)',
   'trade.PositionClosePartial(ticket, closeVolume)',
   'MathAbs(resultingVolume - expectedVolume) > tolerance',
   'GlobalVariableGet(RunnerDoneKey(ticket)) > 0.5 ||',
   'currentVolume < initialVolume - tolerance',
   'if(!ProtectRunnerPosition(ticket, buy) || !SelectOwnedPosition(ticket, InpRVMagicNumber))',
   'signalBodyRatio >= InpRVStrongSignalMinimumBodyRatio',
   'RegisterRunnerState(ticket, targetPrice, PositionGetDouble(POSITION_VOLUME))',
   'return RejectPostFill(m_trade, InpRVMagicNumber,',
   'input double InpRVRiskPercent = 0.45;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Partial-runner source is missing required token: $token"
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
$protectIndex = $manager.Value.IndexOf('ProtectRunnerPosition(ticket, buy)', [StringComparison]::Ordinal)
$partialIndex = $manager.Value.IndexOf('CloseOwnedPositionPartial(', [StringComparison]::Ordinal)
if($protectIndex -lt 0 -or $partialIndex -le $protectIndex) {
   throw 'The stop must be confirmed before the partial close.'
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
if($forkInputs -ne $baseInputs + 4) {
   throw "Expected exactly four new inputs; base=$baseInputs fork=$forkInputs"
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   SignalData = 'COMPLETED_H1_BAR_ONLY'
   NewEntryPaths = 0
   RawPartialCloseSites = 1
   PartialOwnershipConfirmed = $true
   PartialRemainderConfirmed = $true
   ProtectionBeforePartial = $true
   RestartReplayGuard = $true
   InitialRiskChanged = $false
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
