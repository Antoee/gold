$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Protected_Winner_AddOn_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = 'F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Protected-add-on source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpMOUseProtectedWinnerAddOn = false',
   'InpMOAddOnMagicNumber = 26071762',
   'InpMOAddOnMinimumProfitR = 1.25',
   'InpMOAddOnRiskMultiplier = 0.50',
   'InpMOAddOnPrimaryLockR = 0.75',
   'InpMOAddOnLockedProfitCoverage = 1.25',
   'CountOwnedMagicPositions(InpMOAddOnMagicNumber) > 0',
   'FindOnlyOwnedPosition(InpMOMagicNumber, primaryTicket, findReason)',
   'favorable / initialRisk < InpMOAddOnMinimumProfitR',
   'desiredSl > openPrice && desiredSl < current - minimumDistance',
   'desiredSl < openPrice && desiredSl > current + minimumDistance',
   'OrderCalcProfit(orderType, _Symbol, volume, openPrice, lockedSl, lockedProfitMoney)',
   'addedRiskMoney * InpMOAddOnLockedProfitCoverage',
   '!AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason)',
   'PostFillReconcile(m_trade, magic, buy, riskPercent',
   'CountOwnedMagicPositions(InpMOMagicNumber) == 1',
   'CountOwnedMagicPositions(InpMOAddOnMagicNumber) == 0',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Protected-add-on source is missing required token: $token"
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
   if($forkCount -ne $baseCount) { throw "Unexpected direct trade-path count for $tradeToken" }
}
if($fork.IndexOf('InpRVRiskPercent = 0.45;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMORiskPercent = 0.15;', [StringComparison]::Ordinal) -lt 0 -or
   $fork.IndexOf('InpMaximumPortfolioOpenRiskPercent = 0.75;', [StringComparison]::Ordinal) -lt 0) {
   throw 'Frozen base risk defaults changed.'
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   OneAddOnMaximum = $true
   WinnerOnly = $true
   LockedProfitCoverage = $true
   AccountWideExposureGuard = $true
   PostFillReconciliation = $true
   RealAccountDefault = $false
}
