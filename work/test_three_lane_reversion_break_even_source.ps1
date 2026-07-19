$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_BreakEven_Research.mq5'
$expectedBaseHash = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedForkHash = '49A8561A5A6D9F52D5F6F00DE838EBB4B0207BE437FF0B4EB115586912C23F90'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen ATB150 source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Reversion break-even source identity changed: $forkHash" }

$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw
$required = @(
   'InpRVUseBreakEven = false',
   'InpRVBreakEvenTriggerR = 0.75',
   'InpRVBreakEvenLockR = 0.00',
   'void ImproveProtectiveStop(const ulong ticket, const bool buy)',
   'if(!InpRVUseBreakEven || !SelectOwnedPosition(ticket, InpRVMagicNumber))',
   'double initialRisk = MathAbs(openPrice - oldSl);',
   'if(favorable < InpRVBreakEvenTriggerR * initialRisk)',
   'double newSl = buy ? openPrice + InpRVBreakEvenLockR * initialRisk',
   'bool improved = buy ? newSl > oldSl + _Point : newSl < oldSl - _Point;',
   'ModifyOwnedPosition(m_trade, ticket, InpRVMagicNumber,',
   'void ManagePositionOnBar()',
   'if(ManagedPositionCount() > 0)',
   'ManagePositionOnBar();',
   'InpRVBreakEvenLockR >= InpRVBreakEvenTriggerR',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)
foreach($token in $required) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Reversion break-even source is missing required token: $token"
   }
}

$managerMatch = [regex]::Match(
   $fork,
   'void ImproveProtectiveStop\([\s\S]*?\n   \}(?=\r?\n\r?\n   void ManagePositionOnBar)',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$managerMatch.Success) { throw 'Reversion break-even manager body could not be isolated.' }
foreach($forbidden in @('PositionClose', 'm_trade.Buy(', 'm_trade.Sell(', 'HistorySelect', 'HistoryDeal', 'consecutive', 'drawdown')) {
   if($managerMatch.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Forbidden trade, outcome, or close token found in break-even manager: $forbidden"
   }
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected entry or close-path count for $tradeToken" }
}
$baseModifyCount = ([regex]::Matches($base, [regex]::Escape('ModifyOwnedPosition('))).Count
$forkModifyCount = ([regex]::Matches($fork, [regex]::Escape('ModifyOwnedPosition('))).Count
if($forkModifyCount -ne $baseModifyCount + 1) { throw 'Expected exactly one new owned-position modify call.' }

$manageIndex = $fork.IndexOf('ManagePositionOnBar();', [StringComparison]::Ordinal)
$entryIndex = $fork.IndexOf('TryEntry();', $manageIndex, [StringComparison]::Ordinal)
if($manageIndex -lt 0 -or $entryIndex -le $manageIndex) { throw 'Reversion management does not run before a new entry.' }
foreach($frozen in @(
   'InpRVRiskPercent = 0.45;',
   'InpMORiskPercent = 0.15;',
   'InpATBRiskPercent = 0.10;',
   'InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00;'
)) {
   if($fork.IndexOf($frozen, [StringComparison]::Ordinal) -lt 0) { throw "Frozen risk default changed: $frozen" }
}

[pscustomobject][ordered]@{
   Status = 'PASS'
   SourceSha256 = $forkHash
   BaseSha256 = $baseHash
   FeatureDefault = 'DISABLED'
   ManagementCadence = 'COMPLETED_H1_BAR'
   NewTradePaths = 0
   NewClosePaths = 0
   NewOwnedModifyPaths = 1
   TighteningOnly = $true
   OutcomeIndependent = $true
   PortfolioCapPercent = 0.75
   RealAccountDefault = $false
}
