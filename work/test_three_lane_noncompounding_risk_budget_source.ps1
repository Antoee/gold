$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$parentPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Strong_Signal_Risk_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Noncompounding_Risk_Budget_Research.mq5'
$expectedParentHash = '36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF'
$expectedForkHash = 'B72F61E0633F5A57C3BC4D5688C8F7F29155B772F7D2BDE3EDC72429A41E9EA8'

$parentHash = (Get-FileHash -LiteralPath $parentPath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($parentHash -ne $expectedParentHash) { throw "Strong-signal parent identity changed: $parentHash" }
if($forkHash -ne $expectedForkHash) { throw "Noncompounding risk-budget source identity changed: $forkHash" }

$parent = Get-Content -LiteralPath $parentPath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   '#property version   "1.53"',
   'InpUseNoncompoundingRiskBudget = false',
   'double RiskBudgetCapital()',
   'double equity = AccountInfoDouble(ACCOUNT_EQUITY);',
   'if(!InpUseNoncompoundingRiskBudget)',
   'return MathMin(equity, InpExpectedInitialBalance);',
   'double riskMoney = RiskBudgetCapital() * riskPercent / 100.0;',
   '(InpUseNoncompoundingRiskBudget && InpExpectedInitialBalance <= 0.0)',
   'InpRVUseStrongSignalRisk = false',
   'InpRVStrongSignalMinimumBodyRatio = 0.15',
   'InpRVStrongSignalRiskPercent = 0.60',
   'InpMaximumPortfolioOpenRiskPercent = 0.75',
   'InpAllowRealAccountTrading = false',
   'InpUseRealAccountSafetyLock = true'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Noncompounding risk-budget source is missing required token: $token"
   }
}

$budgetFunction = [regex]::Match(
   $fork,
   'double RiskBudgetCapital\(\)\s*\{(?<body>[\s\S]*?)\n\}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$budgetFunction.Success) { throw 'RiskBudgetCapital function could not be isolated.' }
foreach($forbidden in @('History', 'PositionGet', 'PositionSelect', 'consecutive', 'drawdown', 'profit', 'loss', 'TimeCurrent')) {
   if($budgetFunction.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, position, or calendar token found in risk-budget function: $forbidden"
   }
}

$lotsFunction = [regex]::Match(
   $fork,
   'double LotsForRisk\([\s\S]*?\n\}',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$lotsFunction.Success -or
   $lotsFunction.Value.IndexOf('RiskBudgetCapital()', [StringComparison]::Ordinal) -lt 0 -or
   $lotsFunction.Value.IndexOf('AccountInfoDouble(ACCOUNT_EQUITY)', [StringComparison]::Ordinal) -ge 0) {
   throw 'LotsForRisk does not exclusively use the bounded risk-budget capital helper.'
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(')) {
   $parentCount = ([regex]::Matches($parent, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $parentCount) { throw "Unexpected trade-path count for $tradeToken" }
}
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpRVStrongSignalRiskPercent = 0.60;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;',
   'InpMaximumPortfolioDailyLossPercent = 0.75;',
   'InpMaximumPortfolioWeeklyLossPercent = 1.25;',
   'InpMaximumPortfolioMonthlyLossPercent = 1.50;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen risk default changed: $frozen" }
}

$parentInputCount = ([regex]::Matches($parent, '(?m)^input\s+')).Count
$forkInputCount = ([regex]::Matches($fork, '(?m)^input\s+')).Count
if($forkInputCount -ne $parentInputCount + 1) {
   throw "Expected exactly one new input; parent=$parentInputCount fork=$forkInputCount"
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   ParentSha256 = $parentHash
   FeatureDefault = 'DISABLED'
   RiskBudget = 'MIN_CURRENT_EQUITY_OR_FROZEN_INITIAL_CAPITAL'
   DecreasesAfterLoss = $true
   IncreasesAfterProfit = $false
   OutcomeSignal = $false
   NewTradePaths = 0
   NewClosePaths = 0
   NewModifyPaths = 0
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
