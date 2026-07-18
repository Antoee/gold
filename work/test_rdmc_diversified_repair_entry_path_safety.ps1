Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourcePath = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\source\Professional_XAUUSD_EA.mq5"
$profilePath = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\profiles\rdmc_diversified_repair_restart_safe_v2.set"

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [bool]$Pass, [string]$Evidence) {
   $checks.Add([pscustomobject]@{ Check = $Name; Pass = $Pass; Evidence = $Evidence })
}

function Get-Section([string]$Text, [string]$Start, [string]$End) {
   $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
   $endIndex = if($startIndex -ge 0) { $Text.IndexOf($End, $startIndex, [StringComparison]::Ordinal) } else { -1 }
   if($startIndex -lt 0 -or $endIndex -le $startIndex) { return "" }
   return $Text.Substring($startIndex, $endIndex - $startIndex)
}

function Read-Profile([string]$Path) {
   $values = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -match '^([^;=]+)=([^|]*)(.*)$') { $values[$matches[1]] = $matches[2] }
   }
   return $values
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Entry-path audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$orderCalls = @([regex]::Matches($source, 'ExecuteMarketEntry\('))
$wrappedBuySellCalls = @([regex]::Matches($source, '\bexecutor\.(?:Buy|Sell)\s*\('))
$alternateEntryCalls = @([regex]::Matches($source, '\b(?:OrderSendAsync|OrderSend|PositionOpen|BuyLimit|SellLimit|BuyStop|SellStop)\s*\('))
Add-Check "exactly four verified market entry paths exist" ($orderCalls.Count -eq 5 -and $wrappedBuySellCalls.Count -eq 2) "wrapper_refs=$($orderCalls.Count) internal_calls=$($wrappedBuySellCalls.Count)"
Add-Check "no alternate order-opening API exists" ($alternateEntryCalls.Count -eq 0) "calls=$($alternateEntryCalls.Count)"

$momentumClass = Get-Section $source "class CMomentumLane" "CMomentumLane g_momentum;"
$momentumSafety = Get-Section $momentumClass "bool SafetyAllows(string &reason)" "bool ChannelBounds("
$momentumTryEntry = Get-Section $momentumClass "void TryEntry(const double atr)" "public:"
$momentumOpen = Get-Section $momentumClass "bool OpenPosition(const bool buy, const double atr)" "bool TryChannelExit("
$bandOpen = Get-Section $source "bool OpenIsolatedBandVWAPReversionSignal(const SSignal &signal)" "bool OpenIsolatedDailyDonchianSignal(const SSignal &signal)"
$dailyOpen = Get-Section $source "bool OpenIsolatedDailyDonchianSignal(const SSignal &signal)" "bool OpenSignal(const SSignal &signal)"
$primaryOpen = Get-Section $source "bool OpenSignal(const SSignal &signal)" "ENUM_TRADE_BIAS OppositeBias("

foreach($entry in @(
   [pscustomobject]@{ Name='momentum'; Text=$momentumOpen },
   [pscustomobject]@{ Name='band reversion'; Text=$bandOpen },
   [pscustomobject]@{ Name='daily Donchian'; Text=$dailyOpen },
   [pscustomobject]@{ Name='primary'; Text=$primaryOpen }
)) {
   $directCalls = @([regex]::Matches($entry.Text, 'ExecuteMarketEntry\(')).Count
   Add-Check "$($entry.Name) has one verified market entry" ($directCalls -eq 1) "calls=$directCalls"
   foreach($marker in @('LotsForRisk(','ExposureAllows(','TradingCostGuardAllows(','MarginGuardAllows(','SetExpertMagicNumber(','SetDeviationInPoints(')) {
      Add-Check "$($entry.Name) entry guard: $marker" $entry.Text.Contains($marker) $marker
   }
   $exposureIndex = $entry.Text.IndexOf('ExposureAllows(', [StringComparison]::Ordinal)
   $costIndex = $entry.Text.IndexOf('TradingCostGuardAllows(', [StringComparison]::Ordinal)
   $marginIndex = $entry.Text.IndexOf('MarginGuardAllows(', [StringComparison]::Ordinal)
   $orderIndex = $entry.Text.IndexOf('ExecuteMarketEntry(', [StringComparison]::Ordinal)
   Add-Check "$($entry.Name) final guard order is exposure-cost-margin-order" ($exposureIndex -ge 0 -and $costIndex -gt $exposureIndex -and $marginIndex -gt $costIndex -and $orderIndex -gt $marginIndex) "exposure=$exposureIndex cost=$costIndex margin=$marginIndex order=$orderIndex"
}

Add-Check "momentum uses nonzero stop and target" ($momentumOpen.Contains('stopPrice, takeProfit, comment') -and $momentumOpen.Contains('stopDistance <= 0.0')) "SL and TP passed"
Add-Check "band reversion always passes SL and TP" ($bandOpen.Contains('_Symbol, sl, tp, tradeComment') -and $bandOpen.Contains('stopDistance <= 0.0 || tpDistance <= 0.0')) "SL and TP validated"
Add-Check "daily Donchian always passes SL" ($dailyOpen.Contains('_Symbol, sl, tp, tradeComment') -and $dailyOpen.Contains('stopDistance <= 0.0')) "SL validated"
Add-Check "primary always passes computed SL" ($primaryOpen.Contains('_Symbol, sl, tp, tradeComment') -and $primaryOpen.Contains('stopDistance = MathMax(stopDistance, MinimumBrokerStopDistance());') -and $primaryOpen.Contains('if(lots <= 0)')) "SL validated through minimum distance and lot sizing"

foreach($marker in @('TradeEnvironmentAllows(reason)','riskManager.CanOpen(reason)','WeekendCloseWindowActive()','newsFilter.IsBlocked()','InpMOMaximumDailyLossPercent','InpMOMaximumTradesPerDay','InpMOMaximumSpreadPoints','SessionAllows()','InpMOMaximumConsecutiveLosses')) {
   Add-Check "momentum safety marker: $marker" $momentumSafety.Contains($marker) $marker
}
$safetyIndex = $momentumTryEntry.IndexOf('SafetyAllows(safetyReason)', [StringComparison]::Ordinal)
$openIndex = $momentumTryEntry.IndexOf('OpenPosition(', [StringComparison]::Ordinal)
Add-Check "momentum safety runs before its only entry calls" ($safetyIndex -ge 0 -and $openIndex -gt $safetyIndex -and @([regex]::Matches($momentumTryEntry, 'OpenPosition\(')).Count -eq 2) "safety=$safetyIndex first_open=$openIndex"

$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }
$environmentIndex = $onTick.IndexOf('TradeEnvironmentAllows(environmentReason)', [StringComparison]::Ordinal)
$firstPrimaryEntryIndex = @('OpenIsolatedBandVWAPReversionSignal(signal)','OpenIsolatedDailyDonchianSignal(signal)','OpenSignal(signal)') |
   ForEach-Object { $onTick.IndexOf($_, [StringComparison]::Ordinal) } |
   Where-Object { $_ -ge 0 } |
   Measure-Object -Minimum |
   Select-Object -ExpandProperty Minimum
Add-Check "shared environment guard precedes primary-lane entry dispatch" ($environmentIndex -ge 0 -and $firstPrimaryEntryIndex -gt $environmentIndex) "environment=$environmentIndex entry=$firstPrimaryEntryIndex"
Add-Check "session and news gates precede primary-lane entries" ($onTick.IndexOf('newsFilter.IsBlocked()', [StringComparison]::Ordinal) -lt $firstPrimaryEntryIndex -and $onTick.IndexOf('selectedSignalSessionAllowed', [StringComparison]::Ordinal) -lt $firstPrimaryEntryIndex) "gates before dispatch"

$environment = Get-Section $source "bool TradeEnvironmentAllows(string &reason)" "bool TradeReadinessSafetyGateAllows()"
$runtimeIndex = $environment.IndexOf('RuntimeAccountHistoryContractAllows(reason)', [StringComparison]::Ordinal)
$optionalIndex = $environment.IndexOf('if(!InpUseTradeEnvironmentGuard)', [StringComparison]::Ordinal)
Add-Check "persistent account contract cannot be disabled by environment toggle" ($runtimeIndex -ge 0 -and $optionalIndex -gt $runtimeIndex) "runtime=$runtimeIndex optional=$optionalIndex"

$canOpen = Get-Section $source "bool CanOpen(string &reason, const bool bypassStrategyLossState = false)" "bool RiskLimitHit(string &reason)"
Add-Check "hard consecutive-loss control is never bypassed" ($canOpen.Contains('if(InpMaxConsecutiveLosses > 0 && m_consecutiveLosses >= InpMaxConsecutiveLosses)') -and $canOpen -notmatch 'if\(!bypassStrategyLossState\s*&&\s*InpMaxConsecutiveLosses') "shared hard gate"
Add-Check "hard post-loss cooldown is never bypassed" ($canOpen.Contains('if(m_lastLossTime > 0 && InpCooldownMinutesAfterLoss > 0)') -and $canOpen -notmatch 'if\(!bypassStrategyLossState\s*&&\s*m_lastLossTime') "shared hard gate"
Add-Check "adaptive pauses may remain lane-isolated" ($canOpen.Contains('if(!bypassStrategyLossState && AbnormalLossStreakQuarantineActive())') -and $canOpen.Contains('if(!bypassStrategyLossState && RecentPerformancePauseActive())')) "adaptive-only bypass"

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpUseTradingCostGuard = 'true'
   InpUseMarginGuard = 'true'
   InpUseMarginAwareLotCap = 'true'
   InpUseTradeMarginRiskScaling = 'true'
   InpUseAccountWideExposureGuard = 'true'
   InpAccountWideMaxOpenRiskPercent = '0.75'
   InpAccountWideMaxPositions = '1'
   InpAccountWideBlockUnprotectedExposure = 'true'
   InpAllowMinLotRiskOverflow = 'false'
   InpMaxEquityDrawdownPercent = '5.00'
   InpClosePositionsOnRiskLimit = 'true'
   InpMOMaximumPositionLots = '0.10'
   InpMOMaximumSpreadPoints = '50.0'
}.GetEnumerator()) {
   Add-Check "entry-safety profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC entry-path safety checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC entry-path safety checks"
