$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath=Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Momentum_Same_Side_Exit_Cooldown_Research.mq5'
$forkPath=Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Reversion_Reward_Quality_Risk_Research.mq5'
$expectedBaseHash='B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedForkHash='A300713711328CE221447E452B889C0A2F9E449E2BF721BE7E49E0A354A4C416'
$baseHash=(Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash=(Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash){throw "Leader identity changed: $baseHash"}
if($forkHash -ne $expectedForkHash){throw "Reward-quality source identity changed: $forkHash"}
$base=Get-Content -LiteralPath $basePath -Raw
$fork=Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   'input bool   InpRVUseStrongSignalRewardQuality = false;',
   'input double InpRVStrongSignalMinimumRiskReward = 1.50;',
   'double adjustedRiskReward = adjustedReward / adjustedRisk;',
   'bool strongRiskQuality = !InpRVUseStrongSignalRewardQuality ||',
   'adjustedRiskReward >= InpRVStrongSignalMinimumRiskReward;',
   'signalBodyRatio >= InpRVStrongSignalMinimumBodyRatio &&',
   'strongRiskQuality)',
   'InpRVStrongSignalMinimumRiskReward < InpRVMinimumRiskReward',
   '!InpRVUseStrongSignalRisk ||',
   'input double InpRVRiskPercent = 0.45;',
   'input double InpRVStrongSignalRiskPercent = 0.60;',
   'input double InpRVStrongSignalMaximumPositionLots = 0.15;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;',
   'input bool   InpAllowRealAccountTrading = false;'
)){
   if($fork.IndexOf($token,[StringComparison]::Ordinal) -lt 0){throw "Required token missing: $token"}
}

foreach($tradeToken in @('m_trade.Buy(','m_trade.Sell(','CloseOwnedPosition(','ModifyOwnedPosition(')){
   $baseCount=([regex]::Matches($base,[regex]::Escape($tradeToken))).Count
   $forkCount=([regex]::Matches($fork,[regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount){throw "Unexpected trade-path count for $tradeToken"}
}
foreach($currentBarToken in @('iOpen(_Symbol, InpRVSignalTimeframe, 0)','iHigh(_Symbol, InpRVSignalTimeframe, 0)','iLow(_Symbol, InpRVSignalTimeframe, 0)','iClose(_Symbol, InpRVSignalTimeframe, 0)')){
   if(([regex]::Matches($fork,[regex]::Escape($currentBarToken))).Count -ne ([regex]::Matches($base,[regex]::Escape($currentBarToken))).Count){throw "Current-bar OHLC path changed: $currentBarToken"}
}
$baseInputs=([regex]::Matches($base,'(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs=([regex]::Matches($fork,'(?m)^\s*input\s+(?!group\b)')).Count
if($forkInputs -ne $baseInputs+2){throw "Expected exactly two new inputs; base=$baseInputs fork=$forkInputs"}
$qualityBlock=[regex]::Match($fork,'double adjustedRiskReward[\s\S]*?requestedRiskPercent = InpRVStrongSignalRiskPercent;',[Text.RegularExpressions.RegexOptions]::CultureInvariant)
if(!$qualityBlock.Success){throw 'Reward-quality block could not be isolated.'}
foreach($forbidden in @('HistoryDeal','DEAL_PROFIT','DEAL_SWAP','DEAL_COMMISSION','ACCOUNT_PROFIT','drawdown','consecutive')){
   if($qualityBlock.Value.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase) -ge 0){throw "Outcome token found in quality block: $forbidden"}
}
[pscustomobject][ordered]@{Status='PASS';SourceSha256=$forkHash;BaseSha256=$baseHash;FeatureDefault='DISABLED';CompletedBarOnly=$true;OutcomeIndependent=$true;NewInputs=2;NewTradePaths=0;NewClosePaths=0;NewModifyPaths=0;PortfolioCapPercent=0.75;RealAccountDefault=$false}
