$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_D1_Ema_Slope_Guard_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '4119CAF3DACE9D35C80CDE7BBDDB5DBAB45001C654352A82E216B80BF70E9D67'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen cooldown leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "D1 EMA-slope guard source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.69"',
   'input bool   InpMOUseD1EmaSlopeOverextensionGuard = false;',
   'input int    InpMOD1EmaSlopePeriod = 50;',
   'input int    InpMOD1EmaSlopeLookbackBars = 20;',
   'input int    InpMOD1EmaSlopeATRPeriod = 14;',
   'input double InpMOMaximumD1EmaSlopeATR = 1.00;',
   'bool D1EmaSlopeAllows(const bool buy)',
   'double directionalSlopeATR = direction * (recentEma - pastEma) / d1Atr;',
   'return directionalSlopeATR <= InpMOMaximumD1EmaSlopeATR;',
   'return momentumAligned && D1EmaSlopeAllows(buy);',
   'm_d1SlopeEmaHandle = iMA(_Symbol, InpMOMomentumTimeframe,',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "D1 EMA-slope guard source is missing required token: $token"
   }
}

$guardBlock = [regex]::Match(
   $fork,
   'bool D1EmaSlopeAllows\(const bool buy\)[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$guardBlock.Success) { throw 'D1 EMA-slope guard block could not be isolated.' }
foreach($forbidden in @('DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','ACCOUNT_PROFIT','PositionClose','PositionModify','LotsForRisk','TimeCurrent')) {
   if($guardBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Outcome or management token found in D1 EMA-slope guard: $forbidden"
   }
}
foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(', 'OpenPosition(true', 'OpenPosition(false')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected behavioral-path count for $tradeToken" }
}
$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs + 5) { throw "Expected exactly five new guard inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;DefaultOff=$true
   CompletedBarOnly=$true;NewInputs=5;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   CenterMaximumD1EmaSlopeATR=1.0;LowerNeighbor=0.75;UpperNeighbor=1.25
   MomentumRiskPercent=0.15;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
