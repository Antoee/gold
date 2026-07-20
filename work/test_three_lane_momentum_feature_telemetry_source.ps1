$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Feature_Telemetry_Research.mq5'
$expectedBaseHash = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash = '14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen cooldown leader source identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Momentum telemetry source identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.68"',
   'string EntryTelemetry(const bool buy,',
   'd1_pct=%.6f;breakout_atr=%.6f;body_ratio=%.6f;close_location=%.6f;range_atr=%.6f;channel_width_atr=%.6f;atr_pct=%.6f;tick_volume_ratio=%.6f',
   ';stop_atr=',
   'OpenPosition(true, atr, EntryTelemetry(true, close1, atr, channelHigh, channelLow))',
   'OpenPosition(false, atr, EntryTelemetry(false, close1, atr, channelHigh, channelLow))',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input bool   InpUseRealAccountSafetyLock = true;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Momentum telemetry source is missing required token: $token"
   }
}

$telemetryBlock = [regex]::Match(
   $fork,
   'string EntryTelemetry\(const bool buy,[\s\S]*?^   }',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [Text.RegularExpressions.RegexOptions]::Multiline
)
if(!$telemetryBlock.Success) { throw 'Momentum telemetry block could not be isolated.' }
foreach($forbidden in @('m_trade.','DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','ACCOUNT_PROFIT','PositionClose','PositionModify','LotsForRisk','TimeCurrent')) {
   if($telemetryBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Behavioral or outcome token found in telemetry block: $forbidden"
   }
}
if($telemetryBlock.Value -match 'i(?:Open|High|Low|Close|Volume)\([^\r\n]*,\s*0\s*\)') {
   throw 'Telemetry reads the current unfinished bar.'
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
if($forkInputs -ne $baseInputs) { throw "Telemetry must add no inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;BehaviorNeutral=$true
   CompletedBarOnly=$true;NewInputs=0;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   MomentumRiskPercent=0.15;MomentumTakeProfitR=2.00;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
