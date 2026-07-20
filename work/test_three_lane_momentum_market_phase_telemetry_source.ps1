$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Feature_Telemetry_Research.mq5'
$forkPath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Market_Phase_Telemetry_Research.mq5'
$expectedBaseHash = '14F40409A6865F081774AEE18FEEC3E0F22ED1833F8ECAB54DD4BD852A3AD14B'
$expectedForkHash = '87B5158ABAEACEA12E0FE5FA249DFB8D97FECD84CF3B1983A26079CA459086C2'

$baseHash = (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash = (Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash) { throw "Frozen entry-feature telemetry identity changed: $baseHash" }
if($forkHash -ne $expectedForkHash) { throw "Market-phase telemetry identity changed: $forkHash" }
$base = Get-Content -LiteralPath $basePath -Raw
$fork = Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property version   "1.69"',
   'DirectionalEfficiency(const ENUM_TIMEFRAMES timeframe,',
   'DirectionalRangePosition(const ENUM_TIMEFRAMES timeframe,',
   'double H1CompressionRatio()',
   'market_d1_adx=%.6f;market_h4_adx=%.6f;market_h1_adx=%.6f',
   'd1_ema_gap_atr=%.6f;d1_price_gap_atr=%.6f;d1_ema_slope_atr=%.6f',
   'd1_efficiency20=%.6f;d1_range_position60=%.6f;h4_efficiency20=%.6f;h1_efficiency20=%.6f;h1_compression5_20=%.6f',
   'm_d1FastEmaHandle = iMA(_Symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE);',
   'm_d1SlowEmaHandle = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);',
   'input double InpMORiskPercent = 0.15;',
   'input double InpMOTakeProfitR = 2.00;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;'
)) {
   if($fork.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Market-phase telemetry source is missing required token: $token"
   }
}

$telemetryBlock = [regex]::Match(
   $fork,
   'double DirectionalEfficiency\([\s\S]*?bool RegisterRiskForPosition',
   [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
if(!$telemetryBlock.Success) { throw 'Market-phase telemetry block could not be isolated.' }
foreach($forbidden in @('m_trade.','DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','ACCOUNT_PROFIT','PositionClose','PositionModify','LotsForRisk','TimeCurrent')) {
   if($telemetryBlock.Value.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Behavioral or outcome token found in market-phase telemetry block: $forbidden"
   }
}
if($telemetryBlock.Value -match 'i(?:Open|High|Low|Close|Volume)\([^\r\n]*,\s*0\s*\)') {
   throw 'Market-phase telemetry reads the current unfinished bar.'
}

foreach($tradeToken in @('m_trade.Buy(', 'm_trade.Sell(', 'CloseOwnedPosition(', 'ModifyOwnedPosition(', 'OpenPosition(true', 'OpenPosition(false')) {
   $baseCount = ([regex]::Matches($base, [regex]::Escape($tradeToken))).Count
   $forkCount = ([regex]::Matches($fork, [regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount) { throw "Unexpected behavioral-path count for $tradeToken" }
}
$baseInputs = ([regex]::Matches($base, '(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs = ([regex]::Matches($fork, '(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs) { throw "Market-phase telemetry must add no inputs; base=$baseInputs fork=$forkInputs" }

[pscustomobject][ordered]@{
   Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;BehaviorNeutral=$true
   CompletedBarOnly=$true;NewInputs=0;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0
   NewTelemetryFields=11;MomentumRiskPercent=0.15;PortfolioCapPercent=0.75;RealAccountDefault=$false
}
