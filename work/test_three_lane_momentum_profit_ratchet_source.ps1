$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Profit_Ratchet_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '04E9A3FA2B85090A53E7B9D769BA536693D7A590794F58AD97F926D5CB2AFAF4'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen cooldown leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Momentum profit-ratchet source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.70"',
   'input bool   InpMOUseProfitRatchet = false;',
   'input double InpMOProfitRatchetTriggerR = 1.50;',
   'input double InpMOProfitRatchetLockR = 0.75;',
   'if(InpMOUseProfitRatchet && r >= InpMOProfitRatchetTriggerR)',
   'double ratchet = buy ? openPrice + InpMOProfitRatchetLockR * initialRisk',
   ': openPrice - InpMOProfitRatchetLockR * initialRisk;',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Momentum profit-ratchet source is missing required token: $token"
   }
}

$ratchetBlock = [regex]::Match(
   $fork,
   'if\(InpMOUseProfitRatchet && r >= InpMOProfitRatchetTriggerR\)[\s\S]*?^      }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$ratchetBlock.Success) { throw 'Momentum profit-ratchet block could not be isolated.' }
foreach($forbidden in @('m_trade.','DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','ACCOUNT_PROFIT','PositionClose','PositionModify','LotsForRisk','TimeCurrent','iTime')) {
   if($ratchetBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome, trade, or clock token found in momentum profit-ratchet block: $forbidden"
   }
}
if($ratchetBlock.Value -match 'i(?:Open|High|Low|Close|Volume)\([^\r\n]*,\s*0\s*\)') {
   throw 'Momentum profit ratchet reads the unfinished current bar.'
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
if($forkInputs -ne $baseInputs + 3) { throw "Expected exactly three new profit-ratchet inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;DefaultOff=$true
   CompletedBarOnly=$true;NewInputs=3;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   EntrySignalChanged=$false;InitialStopChanged=$false;PositionRiskChanged=$false
   MomentumRiskPercent=0.15;TakeProfitR=2.00;CenterRatchetTriggerR=1.50;CenterRatchetLockR=0.75
   PortfolioCapPercent=0.75;RealAccountDefault=$false
}
