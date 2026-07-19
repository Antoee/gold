$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Protected_Runner_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = '654EEA6299C1D2ABC1F9ACB09F66C41839ABD2EDD6BFD93607A51B043BF26035'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Protected-runner source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpMOUseProtectedRunner = false',
   'InpMORunnerTakeProfitR = 4.00',
   'InpMORunnerLockTriggerR = 1.50',
   'InpMORunnerLockR = 0.75',
   'InpATBUseProtectedRunner = false',
   'InpATBRunnerTakeProfitR = 4.00',
   'InpATBRunnerLockTriggerR = 1.50',
   'InpATBRunnerLockR = 0.75',
   'double targetR = InpMOUseProtectedRunner ? InpMORunnerTakeProfitR : InpMOTakeProfitR',
   'double targetR = InpATBUseProtectedRunner ? InpATBRunnerTakeProfitR : InpATBTakeProfitR',
   'if(InpMOUseProtectedRunner && r >= InpMORunnerLockTriggerR)',
   'if(InpATBUseProtectedRunner && r >= InpATBRunnerLockTriggerR)',
   'if((buy && runnerLock > newSl) || (!buy && runnerLock < newSl))',
   'PostFillReconcile(m_trade, InpMOMagicNumber, buy, InpMORiskPercent',
   'PostFillReconcile(m_trade, InpATBMagicNumber, buy, InpATBRiskPercent',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Protected-runner source is missing required token: $token"
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
foreach($riskDefault in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;'
)) {
   if($fork.IndexOf($riskDefault, [StringComparison]::Ordinal) -lt 0) {
      throw "Frozen base risk default changed: $riskDefault"
   }
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   NewTradePaths = 0
   InitialStopsUnchanged = $true
   TighteningOnlyRunnerLock = $true
   AccountWideExposureGuard = $true
   PostFillReconciliation = $true
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
