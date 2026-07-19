$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Selective_Payoff_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = '56B674D2C85A879212350F944838FDCE7AF91E320D799FEA1EDAB5BF9A0D5C02'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Selective-payoff source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpATBUseSelectiveTargetExtension = false',
   'InpATBExtendedTakeProfitR = 3.00',
   'InpATBExtensionMinimumADX = 22.0',
   'InpATBExtensionMinimumBodyPercent = 55.0',
   'InpATBExtensionMinimumCloseLocationPercent = 75.0',
   'InpATBExtensionMinimumRangeATR = 0.75',
   'bool UseExtendedTarget(const bool buy, const double atr)',
   'double open1 = iOpen(_Symbol, InpATBSignalTimeframe, 1)',
   'double close1 = iClose(_Symbol, InpATBSignalTimeframe, 1)',
   '!BufferValue(m_adxHandle, 0, 1, adx)',
   'bool extendedTarget = UseExtendedTarget(buy, atr)',
   'double targetR = extendedTarget ? InpATBExtendedTakeProfitR : InpATBTakeProfitR',
   'comment += "_EXT"',
   'PostFillReconcile(m_trade, InpATBMagicNumber, buy, InpATBRiskPercent',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Selective-payoff source is missing required token: $token"
   }
}

$helperMatch = [regex]::Match(
   $fork,
   'bool UseExtendedTarget\([\s\S]*?\n\s*\}(?=\r?\n\r?\n\s*bool OpenPosition)',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$helperMatch.Success) { throw 'Selective-payoff helper body could not be isolated.' }
foreach($forbiddenDependency in @('HistorySelect', 'HistoryDeal', 'ClosedPortfolioProfit', 'consecutive', 'drawdown', 'AccountInfoDouble')) {
   if($helperMatch.Value.IndexOf($forbiddenDependency, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome-dependent token found in target selector: $forbiddenDependency"
   }
}
foreach($forbiddenToken in @('martingale', 'averaging down', 'grid recovery', 'recovery sizing')) {
   if($fork.IndexOf($forbiddenToken, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden sizing/recovery token present: $forbiddenToken"
   }
}
foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected direct trade-path count for $tradeToken" }
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
   NewTradePaths = 0
   CompletedEntryBarOnly = $true
   OutcomeIndependent = $true
   AccountWideExposureGuard = $true
   PostFillReconciliation = $true
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
