param(
   [string]$TwoLaneSourcePath = "work\Professional_XAUUSD_EA_TWO_LANE_ISOLATED.mq5",
   [string]$DailyDonchianSourcePath = "outputs\daily_donchian_channel_exit_package\source\Professional_XAUUSD_EA.mq5",
   [string]$ThreeLaneSourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$twoLane = Join-Path $repo $TwoLaneSourcePath
$daily = Join-Path $repo $DailyDonchianSourcePath
$threeLane = Join-Path $repo $ThreeLaneSourcePath
foreach($required in @($twoLane, $daily, $threeLane)) {
   if(!(Test-Path -LiteralPath $required)) { throw "Required source missing: $required" }
}

$twoLaneHash = (Get-FileHash -LiteralPath $twoLane -Algorithm SHA256).Hash
$dailyHash = (Get-FileHash -LiteralPath $daily -Algorithm SHA256).Hash
if($twoLaneHash -ne "007B8DCF4A9A66652B1F34A32893ECA676165B88239119270A9B4D138F184472") {
   throw "Frozen two-lane source changed: $twoLaneHash"
}
if($dailyHash -ne "D387779DC3BABD6A8294C46E5827D1029AA536EA29F91C06C357D66D2B098153") {
   throw "Frozen daily Donchian source changed: $dailyHash"
}

$text = Get-Content -LiteralPath $threeLane -Raw
$requiredMarkers = @(
   "input bool            InpDailyDonchianBypassPrimarySession = false;",
   "input bool            InpDailyDonchianUseIsolatedExecution = false;",
   "input bool            InpDailyDonchianUseTakeProfit = false;",
   "input bool InpUseLaneSpecificMonthlyEntryCaps = false;",
   "bool isDailyDonchianBreakout;",
   "signal.isDailyDonchianBreakout = true;",
   "bool OpenIsolatedDailyDonchianSignal(const SSignal &signal)",
   "riskManager.CanOpen(blockReason, true)",
   "riskManager.ExposureAllows(signal.bias, entry, stopDistance, lots, exposureReason)",
   "TradingCostGuardAllows(stopDistance, lots, costReason)",
   "MarginGuardAllows(signal.bias, lots, entry, marginReason)",
   "if(InpDailyDonchianUseIsolatedExecution)",
   "signal.isDailyDonchianBreakout && dailyMayBypassPrimarySession",
   "signal.isDailyDonchianBreakout && InpDailyDonchianUseIsolatedExecution",
   "OpenIsolatedDailyDonchianSignal(signal)",
   "bool dailyIndependentAttempt = InpUseDailyDonchianBreakoutLane &&",
   "if(!openedPosition && dailyIndependentSessionAllowed)",
   "DailyDonchianChannelExitHit(type, dailyExitReason)",
   'SetupLaneEntryCount(PERIOD_MN1, "Band VWAP reversion;")',
   'SetupLaneEntryCount(PERIOD_MN1, "DDB;")'
)
foreach($marker in $requiredMarkers) {
   if(!$text.Contains($marker)) { throw "Three-lane isolation marker missing: $marker" }
}

if($text.Contains("<<<<<<<") -or $text.Contains("|||||||") -or
   $text.Contains("=======") -or $text.Contains(">>>>>>>")) {
   throw "Merge conflict marker remains in three-lane source."
}

$dailyFalseInitializations = ([regex]::Matches($text, "signal\.isDailyDonchianBreakout = false;")).Count
$bandFalseInitializations = ([regex]::Matches($text, "signal\.isBandVWAPReversion = false;")).Count
if($dailyFalseInitializations -ne 4 -or $bandFalseInitializations -ne 4) {
   throw "Every signal builder must initialize both isolated-lane flags. DDB=$dailyFalseInitializations Band=$bandFalseInitializations"
}
if(([regex]::Matches($text, "signal\.isDailyDonchianBreakout = true;")).Count -ne 1) {
   throw "Daily Donchian flag must be set true in exactly one signal builder."
}

$closeAllStart = $text.IndexOf("void CloseAll(const string reason)")
$manageStart = $text.IndexOf("void Manage(const ENUM_TRADE_BIAS currentSignalBias)")
if($closeAllStart -lt 0 -or $manageStart -le $closeAllStart) {
   throw "Could not locate position-management boundaries."
}
$closeAllBlock = $text.Substring($closeAllStart, $manageStart - $closeAllStart)
if($closeAllBlock.Contains("InpBandVWAPReversionUseIsolatedExecution") -or
   $closeAllBlock.Contains("InpDailyDonchianUseIsolatedExecution")) {
   throw "Isolated execution must not bypass account-level CloseAll handling."
}

$dailyExit = $text.IndexOf("DailyDonchianChannelExitHit(type, dailyExitReason)")
$dailySkip = $text.IndexOf("if(InpDailyDonchianUseIsolatedExecution)", $dailyExit)
if($dailyExit -lt 0 -or $dailySkip -le $dailyExit) {
   throw "Daily channel exit must run before isolated management skips primary exits."
}

[pscustomobject]@{
   Status = "PASS"
   TwoLaneSha256 = $twoLaneHash
   DailyDonchianSha256 = $dailyHash
   ThreeLaneSha256 = (Get-FileHash -LiteralPath $threeLane -Algorithm SHA256).Hash
   DailyFalseInitializations = $dailyFalseInitializations
   BandFalseInitializations = $bandFalseInitializations
}
