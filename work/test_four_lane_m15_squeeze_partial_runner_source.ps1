$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Diversifier_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Partial_Runner_Research.mq5'
$expectedBaseHash = '5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6'
$expectedForkHash = '1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen squeeze source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Squeeze partial-runner source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpSQUsePartialRunner = false',
   'InpSQPartialClosePercent = 80.0',
   'InpSQPartialTriggerR = 1.50',
   'InpSQPartialTargetR = 4.00',
   'InpSQPartialStopLockR = 1.25',
   'bool CloseOwnedPositionPartial(CTrade &trade,',
   'trade.PositionClosePartial(ticket, closeVolume)',
   'MathAbs(resultingVolume - expectedVolume) > tolerance',
   'bool PositionIdentifierOpen(const ulong positionIdentifier)',
   'GlobalVariableGet(RunnerDoneKey(ticket)) > 0.5 ||',
   'currentVolume < initialVolume - tolerance',
   'oldSl > 0.0 &&',
   'if(!ProtectRunnerPosition(ticket, buy) || !SelectOwnedPosition(ticket, InpSQMagicNumber))',
   'PartialVolumes(lots, closeVolume, remainingVolume)',
   '!RegisterRunnerState(ticket, actualVolume)',
   'ManagePartialRunner();',
   'if(transaction.position > 0 && !PositionIdentifierOpen(transaction.position))',
   'input double InpSQRiskPercent = 0.10;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Squeeze partial-runner source is missing required token: $token"
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
foreach($forbidden in @('HistoryDealGetDouble','DEAL_PROFIT','ACCOUNT_BALANCE','ACCOUNT_EQUITY','drawdown','LossStreak')) {
   if($manager.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome-conditioned runner logic is forbidden: $forbidden"
   }
}

$onTick = [regex]::Match(
   $fork,
   'class CSqueezeDiversifierLane[\s\S]*?void OnTick\(\)[\s\S]*?\n   \}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$onTick.Success -or
   $onTick.Value.IndexOf('ManagePartialRunner();', [StringComparison]::Ordinal) -gt
   $onTick.Value.IndexOf('currentBar == m_lastSignalBar', [StringComparison]::Ordinal)) {
   throw 'The partial runner must be managed on every tick before the new-bar gate.'
}

foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpSQRiskPercent = 0.10;',
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
   EveryTickManagement = $true
   RestartReplayGuard = $true
   OutcomeConditionedLogic = $false
   UnsplittableTradesRetainBaselineTarget = $true
   InitialRiskChanged = $false
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
