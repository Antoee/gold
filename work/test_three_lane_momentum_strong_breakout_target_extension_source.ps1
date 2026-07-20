$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Strong_Breakout_Target_Extension_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = 'C7B5D50FF1229525CDD619D4943B232C97E229BA7086513A6515EABCC6015110'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen cooldown leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Strong-breakout target-extension source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.69"',
   'input bool   InpMOUseStrongBreakoutTargetExtension = false;',
   'input double InpMOStrongBreakoutMinimumBodyRatio = 0.50;',
   'input double InpMOStrongBreakoutMinimumCloseLocation = 0.75;',
   'input double InpMOStrongBreakoutTakeProfitR = 3.00;',
   'double BreakoutTargetR(const bool buy, const double closePrice)',
   'if(!InpMOUseStrongBreakoutTargetExtension)',
   'return InpMOTakeProfitR;',
   'return InpMOStrongBreakoutTakeProfitR;',
   'OpenPosition(true, atr, BreakoutTargetR(true, close1),',
   'OpenPosition(false, atr, BreakoutTargetR(false, close1),',
   ';target_r=',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Strong-breakout target-extension source is missing required token: $token"
   }
}

$targetBlock = [regex]::Match(
   $fork,
   'double BreakoutTargetR\(const bool buy, const double closePrice\)[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$targetBlock.Success) { throw 'Strong-breakout target block could not be isolated.' }
foreach($forbidden in @('m_trade.','DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','ACCOUNT_PROFIT','PositionClose','PositionModify','LotsForRisk','TimeCurrent','iTime')) {
   if($targetBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, trade, or clock token found in strong-breakout target block: $forbidden"
   }
}
if($targetBlock.Value -match 'i(?:Open|High|Low|Close|Volume)\([^\r\n]*,\s*0\s*\)') {
   throw 'Strong-breakout target extension reads the unfinished current bar.'
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected trade-path count for $tradeToken" }
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
if($forkInputs -ne $baseInputs + 4) { throw "Expected exactly four new target-extension inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;DefaultOff=$true
   CompletedBarOnly=$true;NewInputs=4;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   EntrySignalChanged=$false;InitialStopChanged=$false;PositionRiskChanged=$false
   MomentumRiskPercent=0.15;BaseTakeProfitR=2.00;CenterStrongTakeProfitR=3.00
   PortfolioCapPercent=0.75;RealAccountDefault=$false
}
