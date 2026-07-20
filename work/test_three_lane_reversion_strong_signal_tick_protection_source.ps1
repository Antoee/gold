$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Risk_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Tick_Protection_Research.mq5'
$expectedBaseHash = '36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF'
$expectedForkHash = '096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen strong-signal source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Strong-signal tick-protection source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseStrongSignalRisk = false',
   'InpRVStrongSignalMinimumBodyRatio = 0.15',
   'InpRVStrongSignalRiskPercent = 0.60',
   'InpRVUseStrongSignalProtection = false',
   'InpRVStrongSignalProtectionTriggerR = 1.00',
   'InpRVStrongSignalProtectionLockR = 0.10',
   'double directionalBody = buy ? close1 - open1 : open1 - close1;',
   'double signalBodyRatio = MathMax(0.0, directionalBody) / range1;',
   'signalBodyRatio >= InpRVStrongSignalMinimumBodyRatio',
   'bool strongSignal = InpRVUseStrongSignalRisk &&',
   'RegisterStrongRisk(ticket)',
   'GlobalVariableGet(riskKey)',
   'favorable < InpRVStrongSignalProtectionTriggerR * initialRisk',
   'newSl = buy ? openPrice + InpRVStrongSignalProtectionLockR * initialRisk',
   'bool improves = buy ? newSl > oldSl + _Point * 0.5',
   'ModifyOwnedPosition(m_trade, ticket, InpRVMagicNumber,',
   'ManageStrongPositionOnTick();',
   'requestedRiskPercent = InpRVStrongSignalRiskPercent;',
   'LotsForRisk(buy, entryPrice, stopPrice,',
   'requestedRiskPercent, InpRVMaximumPositionLots)',
   'PostFillReconcile(m_trade, InpRVMagicNumber, buy, requestedRiskPercent,',
   'InpRVStrongSignalRiskPercent > InpMaximumPortfolioOpenRiskPercent',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Strong-signal tick-protection source is missing required token: $token"
   }
}

$protection = [regex]::Match(
   $fork,
   'void ImproveStrongProtectiveStop\(const ulong ticket\)[\s\S]*?void ManageStrongPositionOnTick\(\)',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$protection.Success) { throw 'Strong-signal tick-protection block could not be isolated.' }
foreach($forbidden in @('History', 'AccountInfo', 'consecutive', 'drawdown', 'DEAL_PROFIT', 'ACCOUNT_PROFIT', 'POSITION_PROFIT', 'loss', 'TimeCurrent')) {
   if($protection.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, account-state, or calendar token found in protection block: $forbidden"
   }
}
$tickFirst = [regex]::IsMatch(
   $fork,
   'void OnTick\(\)\s*\{\s*if\(!InpRVEnabled\)[\s\S]*?ManageStrongPositionOnTick\(\);[\s\S]*?datetime currentBar = iTime',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$tickFirst) { throw 'Strong-position protection is not evaluated before the new-bar entry guard.' }

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected trade-path count for $tradeToken" }
}
$baseModifyCount = ([regex]::Matches($base, [regex]::Escape('ModifyOwnedPosition('))).Count
$forkModifyCount = ([regex]::Matches($fork, [regex]::Escape('ModifyOwnedPosition('))).Count
if($forkModifyCount -ne $baseModifyCount + 1) { throw 'Expected exactly one tightening-only modify path.' }
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;',
   'InpMaximumPortfolioDailyLossPercent = 0.75;',
   'InpMaximumPortfolioWeeklyLossPercent = 1.25;',
   'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen risk default changed: $frozen" }
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   SignalData = 'COMPLETED_H1_BODY_AND_EVERY_TICK_EXECUTABLE_PRICE_PROGRESS'
   OutcomeIndependent = $true
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 1
   TighteningOnly = $true
   BaseRiskPercent = 0.45
   DefaultStrongRiskPercent = 0.60
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
