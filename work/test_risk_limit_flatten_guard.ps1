param(
   [string]$EaPath = "outputs\Professional_XAUUSD_EA.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if(!(Test-Path -LiteralPath $EaPath)) {
   throw "EA source missing: $EaPath"
}

$source = Get-Content -LiteralPath $EaPath -Raw

$requiredPatterns = @(
   'input bool\s+InpClosePositionsOnRiskLimit\s*=\s*false;',
   'bool RiskLimitHit\(string &reason\)',
   'if\(RiskLimitHit\(reason\)\)\s*[\r\n\s]*return false;',
   'void CloseAll\(const string reason\)',
   'logger\.Write\("risk_exit"',
   'if\(InpClosePositionsOnRiskLimit\)',
   'riskManager\.RiskLimitHit\(riskExitReason\)',
   'positionManager\.CloseAll\(riskExitReason\)',
   'g_lastBlockReason = riskExitReason;'
)

foreach($pattern in $requiredPatterns) {
   if($source -notmatch $pattern) {
      throw "Missing expected risk-limit flatten pattern: $pattern"
   }
}

$signalIndex = $source.IndexOf('SSignal signal = entryEngine.Build(trendBias);')
$flattenIndex = $source.IndexOf('if(InpClosePositionsOnRiskLimit)')
$manageIndex = $source.IndexOf('positionManager.Manage(signal.bias);')
$sessionIndex = $source.IndexOf('if(!sessionFilter.IsAllowed())')

if($signalIndex -lt 0 -or $flattenIndex -lt 0 -or $manageIndex -lt 0 -or $sessionIndex -lt 0) {
   throw "Could not locate OnTick signal, flatten, manage, or session blocks."
}

if(!($signalIndex -lt $flattenIndex -and $flattenIndex -lt $manageIndex -and $manageIndex -lt $sessionIndex)) {
   throw "Risk-limit flatten must run after signal construction and before normal position management/session entry checks."
}

"RISK_LIMIT_FLATTEN_GUARD_SMOKE_PASS"
