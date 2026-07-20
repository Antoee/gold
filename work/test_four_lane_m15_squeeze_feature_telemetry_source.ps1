$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath=Join-Path $repo 'work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Partial_Runner_Research.mq5'
$forkPath=Join-Path $repo 'work\Professional_XAUUSD_Four_Lane_M15_Squeeze_Feature_Telemetry_Research.mq5'
$expectedBaseHash='1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005'
$expectedForkHash='C6B4BC66F661BB70CC51B92E320A87A5643745454C26791B09766F84DA9C94C4'

$baseHash=(Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()
$forkHash=(Get-FileHash -LiteralPath $forkPath -Algorithm SHA256).Hash.ToUpperInvariant()
if($baseHash -ne $expectedBaseHash){throw "Frozen partial-runner source changed: $baseHash"}
if($forkHash -ne $expectedForkHash){throw "Squeeze telemetry source changed: $forkHash"}
$base=Get-Content -LiteralPath $basePath -Raw
$fork=Get-Content -LiteralPath $forkPath -Raw

foreach($token in @(
   '#property description "Behavior-neutral M15 squeeze entry-feature telemetry',
   'string EntryTelemetry(const bool buy,',
   'double EntryTickVolumeRatio(const int signalShift)',
   'breakout_atr=%.6f',
   'squeeze_ratio_mean=%.6f',
   'trend_slope_atr=%.6f',
   'string evidenceReason = entryTelemetry +',
   'runnerRequested ? "m15_sq_pr_telemetry" : "m15_sq_b8_telemetry"',
   'position_open_after_exit=',
   'string telemetry = EntryTelemetry(buy, close1, atr, channelHigh, channelLow,',
   'OpenPosition(buy, atr, rawStop, telemetry);',
   'input bool   InpSQUsePartialRunner = false;',
   'input bool   InpAllowRealAccountTrading = false;',
   'input double InpMaximumPortfolioOpenRiskPercent = 0.75;'
)){
   if($fork.IndexOf($token,[StringComparison]::Ordinal) -lt 0){throw "Missing required telemetry token: $token"}
}

foreach($tradeToken in @('m_trade.Buy(','m_trade.Sell(','.PositionClosePartial(','ModifyOwnedPosition(')){
   $baseCount=([regex]::Matches($base,[regex]::Escape($tradeToken))).Count
   $forkCount=([regex]::Matches($fork,[regex]::Escape($tradeToken))).Count
   if($forkCount -ne $baseCount){throw "Behavioral trade-path count changed for ${tradeToken}: $baseCount -> $forkCount"}
}
$baseInputs=([regex]::Matches($base,'(?m)^\s*input\s+(?!group\b)')).Count
$forkInputs=([regex]::Matches($fork,'(?m)^\s*input\s+(?!group\b)')).Count
if($baseInputs -ne 252 -or $forkInputs -ne $baseInputs){throw "Telemetry must add zero inputs: base=$baseInputs fork=$forkInputs"}

$telemetry=[regex]::Match($fork,'string EntryTelemetry\(const bool buy,[\s\S]*?\n   \}',[Text.RegularExpressions.RegexOptions]::CultureInvariant)
if(!$telemetry.Success){throw 'EntryTelemetry could not be isolated.'}
foreach($forbidden in @('HistoryDeal','DEAL_PROFIT','ACCOUNT_BALANCE','ACCOUNT_EQUITY','LossStreak','drawdown','PositionClose','Buy(','Sell(')){
   if($telemetry.Value.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase) -ge 0){throw "Outcome or trade logic found in telemetry: $forbidden"}
}
foreach($required in @('iHigh(_Symbol, InpSQSignalTimeframe, 1)','iLow(_Symbol, InpSQSignalTimeframe, 1)','BufferValue(m_adxHandle, 0, 1, adx)','BufferValue(m_trendEmaHandle, 0, 1, emaNow)','for(int shift = 2; shift < 2 + InpSQSqueezeBars; ++shift)')){
   if($telemetry.Value.IndexOf($required,[StringComparison]::Ordinal) -lt 0){throw "Telemetry is not completed-bar-only: $required"}
}

$tryEntries=[regex]::Matches($fork,'void TryEntry\(const double atr\)[\s\S]*?\n   \}',[Text.RegularExpressions.RegexOptions]::CultureInvariant)
$tryEntry=@($tryEntries|Where-Object{$_.Value.IndexOf('InpSQSqueezeBars',[StringComparison]::Ordinal) -ge 0})|Select-Object -First 1
if($null -eq $tryEntry -or !$tryEntry.Success){throw 'Squeeze TryEntry could not be isolated.'}
$safetyIndex=$tryEntry.Value.IndexOf('if(!SafetyAllows(safetyReason))',[StringComparison]::Ordinal)
$telemetryIndex=$tryEntry.Value.IndexOf('EntryTelemetry(',[StringComparison]::Ordinal)
$openIndex=$tryEntry.Value.IndexOf('OpenPosition(buy, atr, rawStop, telemetry)',[StringComparison]::Ordinal)
if($safetyIndex -lt 0 -or $telemetryIndex -le $safetyIndex -or $openIndex -le $telemetryIndex){throw 'Telemetry must be computed after all entry gates and immediately before the existing open path.'}

[pscustomobject][ordered]@{
   Status='PASS'
   SourceSha256=$forkHash
   BaseSha256=$baseHash
   NewInputs=0
   NewBuyPaths=0
   NewSellPaths=0
   NewPartialClosePaths=0
   NewModifyPaths=0
   CompletedBarFeatures=$true
   OutcomeConditionedLogic=$false
   StrategyDecisionChanged=$false
   RealAccountDefault=$false
}
