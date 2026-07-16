param(
   [string]$CommonSourcePath = "work\Professional_XAUUSD_EA_PORTFOLIO_COMMON.mq5",
   [string]$IsolatedSourcePath = "work\Professional_XAUUSD_EA_TWO_LANE_ISOLATED.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$common = Join-Path $repo $CommonSourcePath
$isolated = Join-Path $repo $IsolatedSourcePath
foreach($required in @($common, $isolated)) {
   if(!(Test-Path -LiteralPath $required)) { throw "Required source missing: $required" }
}

$commonHash = (Get-FileHash -LiteralPath $common -Algorithm SHA256).Hash
$expectedCommonHash = "F82B6BCC030903D0E425D053747122C9F178C8D19F555FC2A242E0CC8FEE0BA0"
if($commonHash -ne $expectedCommonHash) { throw "Validated common source changed: $commonHash" }

$text = Get-Content -LiteralPath $isolated -Raw
$requiredMarkers = @(
   "input bool            InpBandVWAPReversionBypassPrimarySession = false;",
   "input bool            InpBandVWAPReversionUseIsolatedExecution = false;",
   "input ENUM_TIMEFRAMES InpBandVWAPReversionTimeframe = PERIOD_H1;",
   "input int             InpBandVWAPReversionVWAPLookbackBars = 48;",
   "bool isBandVWAPReversion;",
   "bool TradingDayAllowed()",
   "if(!TradingDayAllowed())",
   "signal.isBandVWAPReversion = true;",
   "indicators.BandReversionATR(1, atr)",
   "m_structure.VWAPValueForTimeframe(timeframe,",
   "g_lastBandReversionBarTime = iTime(_Symbol, InpBandVWAPReversionTimeframe, 0);",
   "bool OpenIsolatedBandVWAPReversionSignal(const SSignal &signal)",
   "riskManager.CanOpen(blockReason, true)",
   "signal.isBandVWAPReversion && InpBandVWAPReversionUseIsolatedExecution",
   "bool primarySessionAllowed = sessionFilter.IsAllowed();",
   "if(!primarySessionAllowed && bandMayBypassPrimarySession)",
   "signal.isBandVWAPReversion && bandMayBypassPrimarySession"
)
foreach($marker in $requiredMarkers) {
   if(!$text.Contains($marker)) { throw "Session-isolation marker missing: $marker" }
}

$falseInitializations = ([regex]::Matches($text, "signal\.isBandVWAPReversion = false;")).Count
if($falseInitializations -ne 3) {
   throw "Expected three explicit false initializations, found $falseInitializations."
}
if(([regex]::Matches($text, "signal\.isBandVWAPReversion = true;")).Count -ne 1) {
   throw "Band/VWAP flag must be set true in exactly one signal builder."
}

$closeAllStart = $text.IndexOf("void CloseAll(const string reason)")
$manageStart = $text.IndexOf("void Manage(const ENUM_TRADE_BIAS currentSignalBias)")
if($closeAllStart -lt 0 -or $manageStart -le $closeAllStart) {
   throw "Could not locate position-management boundaries."
}
$closeAllBlock = $text.Substring($closeAllStart, $manageStart - $closeAllStart)
if($closeAllBlock.Contains("InpBandVWAPReversionUseIsolatedExecution")) {
   throw "Isolated execution must not bypass account-level CloseAll handling."
}

[pscustomobject]@{
   Status = "PASS"
   CommonSha256 = $commonHash
   IsolatedSha256 = (Get-FileHash -LiteralPath $isolated -Algorithm SHA256).Hash
   FalseInitializations = $falseInitializations
}
