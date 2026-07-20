$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Retracement_Entry_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '76F0E1B6E7841BAB5B2BCA9D273AE04AD88047F1E90539E3052C0134A0A9A4C8'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Retracement-entry source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.66"',
   'InpRVUseRetracementEntry = false',
   'InpRVRetracementEntryOffsetATR = 0.15',
   'InpRVRetracementEntryLifetimeBars = 1',
   'bool ArmRetracementEntry(',
   'bool ProcessArmedEntry()',
   'tick.ask <= m_armedTriggerPrice',
   'tick.bid >= m_armedTriggerPrice',
   'TimeCurrent() >= m_armedUntil',
   'if(!SafetyAllows(safetyReason)',
   'CurrentMonthEntryCount() >= InpRVMaximumMonthlyEntries',
   'AccountWideExposureAllows(',
   'adjustedReward / adjustedRisk < MathMax(0.0, InpRVMinimumRiskReward)',
   'RRE;Band VWAP retrace;Lower',
   'RRE;Band VWAP retrace;Upper',
   'input double InpRVRiskPercent = 0.45;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Retracement-entry source is missing required token: $token"
   }
}

$featureBlock = [regex]::Match(
   $fork,
   'bool ArmRetracementEntry\([\s\S]*?void TryEntry\(\)',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$featureBlock.Success) { throw 'Retracement-entry feature block could not be isolated.' }
foreach($forbidden in @(
   'DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','consecutive','ACCOUNT_PROFIT',
   'TimeMonth','DayOfWeek','BuyLimit','SellLimit','BuyStop','SellStop'
)) {
   if($featureBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden outcome, calendar, or broker-pending token found in feature block: $forbidden"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected direct trade-path count for $tradeToken" }
}
foreach($pendingToken in @('.BuyLimit(', '.SellLimit(', '.BuyStop(', '.SellStop(', 'OrderSendAsync(')) {
   if($fork.IndexOf($pendingToken, [StringComparison]::Ordinal) -ge 0) {
      throw "Broker-pending or async path is forbidden: $pendingToken"
   }
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
if($forkInputs -ne $baseInputs + 3) { throw "Expected exactly three new inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   BrokerPendingOrders = 0
   NewDirectTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   TriggerSafetyRevalidation = $true
   OutcomeIndependent = $true
   FrozenCenterOffsetATR = 0.15
   FrozenCenterLifetimeBars = 1
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
