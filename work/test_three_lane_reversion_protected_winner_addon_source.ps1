$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Tick_Protection_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Protected_Winner_AddOn_Research.mq5'
$expectedBaseHash = '096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248'
$expectedForkHash = '1C28EC85646409F3C82E584AD2DA66E6A4FA936CEFAE142D09846694E5369FE2'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen research base identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Protected reversion add-on source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseProtectedWinnerAddOn = false',
   'InpRVAddOnMagicNumber = 26071722',
   'InpRVAddOnTriggerR = 1.00',
   'InpRVAddOnPrimaryLockR = 0.50',
   'InpRVAddOnRiskPercent = 0.15',
   'InpRVAddOnLockedProfitCoverage = 1.25',
   'InpRVAddOnMinimumRemainingRR = 1.20',
   'CountOwnedMagicPositions(InpRVMagicNumber) != 1',
   'CountOwnedMagicPositions(InpRVAddOnMagicNumber) != 0',
   'GlobalVariableCheck(AddOnAttemptKey(primaryTicket))',
   'GlobalVariableCheck(StrongRiskKey(primaryTicket))',
   'favorable < InpRVAddOnTriggerR * initialRisk',
   'remainingReward / addedRiskDistance < InpRVAddOnMinimumRemainingRR',
   'lockedProfitMoney + 1e-8 < addedRiskMoney * InpRVAddOnLockedProfitCoverage',
   'AccountWideExposureAllowsWithStopOverride(buy, executablePrice, desiredLock',
   'AccountWideExposureAllows(buy, executablePrice, desiredLock, lots, exposureReason)',
   'ModifyOwnedPosition(m_trade, primaryTicket, InpRVMagicNumber',
   'PostFillReconcile(m_trade, InpRVAddOnMagicNumber, buy',
   'NormalizeDouble(primaryTarget, _Digits)',
   'VerifiedGlobalSet(AddOnAttemptKey(primaryTicket), 1.0)',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Protected reversion add-on source is missing required token: $token"
   }
}
foreach($token in @('martingale','averaging down','grid recovery','recovery sizing')) {
   if($fork.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden sizing/recovery token present: $token"
   }
}
foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount + 1) { throw "Expected exactly one new add-on path for $tradeToken" }
}
foreach($closeToken in @('m_trade.PositionClose(', 'm_trade.PositionCloseBy(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($closeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($closeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected new close path for $closeToken" }
}
if($fork.IndexOf('InpRVRiskPercent = 0.45;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMORiskPercent = 0.15;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpATBRiskPercent = 0.10;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMaximumPortfolioOpenRiskPercent = 0.75;', [StringComparison]::Ordinal) -lt 0) {
   throw 'Frozen base risk defaults changed.'
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   StrongSignalOnly = $true
   OneAddOnMaximum = $true
   PersistentAttemptLatch = $true
   WinnerOnly = $true
   LockedProfitCoverage = $true
   RemainingRewardGate = $true
   HypotheticalExposurePrecheck = $true
   AccountWideExposureGuard = $true
   PostFillReconciliation = $true
   NewEntryPaths = 1
   NewClosePaths = 0
   RealAccountDefault = $false
}
