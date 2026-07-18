param(
   [string]$OutputDirectory = "outputs\rdmc_diversified_repair_restart_safe_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$out = Join-Path $repo $OutputDirectory
$source = Join-Path $out "source\Professional_XAUUSD_EA.mq5"
$profile = Join-Path $out "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$configs = Join-Path $out "configs"
$reports = Join-Path $out "reports"
$v1Source = Join-Path $repo "outputs\rdmc_diversified_repair_model1_package\source\Professional_XAUUSD_EA.mq5"
$launchLock = Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"
$launchUnlock = Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock"

$expectedV1SourceHash = "4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5"
$expectedSourceHash = "9B5D41B4B55B8FFB69A06ECA4F435F13FBB0D043EDDCC6B24339B25298783785"
$expectedProfileHash = "89D2EEDC11F8C2C08C37D115D059EA5D61B378CF3397B0B66930E77DD2E4FECD"

foreach($required in @($source, $profile, $v1Source, $launchLock)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) {
      throw "Required frozen input is missing: $required"
   }
}
if(Test-Path -LiteralPath $launchUnlock) {
   throw "Unexpected MT5 launch unlock is present. Static package generation stopped."
}

$v1Hash = (Get-FileHash -LiteralPath $v1Source -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
if($v1Hash -ne $expectedV1SourceHash) { throw "Frozen v1 predecessor source changed." }
if($sourceHash -ne $expectedSourceHash) { throw "Restart-safe v2 source identity changed." }
if($profileHash -ne $expectedProfileHash) { throw "Restart-safe v2 profile identity changed." }

$sourceText = Get-Content -LiteralPath $source -Raw
$sourceInputs = [regex]::Matches($sourceText, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=') |
   ForEach-Object { $_.Groups[1].Value }
$profileLines = @(Get-Content -LiteralPath $profile)
$profileInputs = @($profileLines | ForEach-Object {
   if($_ -match '^([^;=]+)=') { $matches[1] }
})
$duplicateSourceInputs = @($sourceInputs | Group-Object | Where-Object Count -gt 1)
$duplicateProfileInputs = @($profileInputs | Group-Object | Where-Object Count -gt 1)
$missingProfileInputs = @($sourceInputs | Where-Object { $_ -notin $profileInputs })
$extraProfileInputs = @($profileInputs | Where-Object { $_ -notin $sourceInputs })
if($sourceInputs.Count -ne 589 -or $profileInputs.Count -ne 589) {
   throw "Expected 589 source/profile inputs; found source=$($sourceInputs.Count) profile=$($profileInputs.Count)."
}
if($duplicateSourceInputs.Count -gt 0 -or $duplicateProfileInputs.Count -gt 0 -or
   $missingProfileInputs.Count -gt 0 -or $extraProfileInputs.Count -gt 0) {
   throw "The restart-safe profile does not exactly freeze the source input surface."
}

New-Item -ItemType Directory -Force -Path $configs, $reports | Out-Null
Get-ChildItem -LiteralPath $configs -Filter "*.ini" -File -ErrorAction SilentlyContinue |
   Remove-Item -Force

$windows = [System.Collections.Generic.List[object]]::new()
for($year = 2015; $year -le 2025; $year++) {
   $windows.Add([pscustomobject]@{ Year = [string]$year; From = "$year.01.01"; To = "$year.12.31" })
}
$windows.Add([pscustomobject]@{ Year = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" })

$queue = [System.Collections.Generic.List[object]]::new()
$index = 0
foreach($window in $windows) {
   $index++
   $name = "rdmc_diversified_repair_restart_safe_v2_$($window.Year)_m1"
   $configName = "{0:D3}_{1}.ini" -f $index, $name
   $configPath = Join-Path $configs $configName
   $configLines = [System.Collections.Generic.List[string]]::new()
   foreach($line in @(
      "[Tester]", "Expert=Professional_XAUUSD_EA.ex5", "Symbol=XAUUSD", "Period=15",
      "Optimization=0", "Model=1", "FromDate=$($window.From)", "ToDate=$($window.To)",
      "ForwardMode=0", "Deposit=10000", "Currency=USD", "ProfitInPips=0", "Leverage=100",
      "ExecutionMode=0", "OptimizationCriterion=6", "Visual=0", "Report=$name",
      "ReplaceReport=1", "ShutdownTerminal=1", "[TesterInputs]"
   )) { $configLines.Add($line) }
   foreach($line in $profileLines) { $configLines.Add($line) }
   [IO.File]::WriteAllLines($configPath, $configLines.ToArray(), [Text.Encoding]::ASCII)

   $queue.Add([pscustomobject]@{
      QueueIndex = $index
      Candidate = "rdmc_diversified_repair_restart_safe_v2"
      Window = $window.Year
      FromDate = $window.From
      ToDate = $window.To
      Model = 1
      Deposit = 10000
      ProfileSha256 = $profileHash
      SourceSha256 = $sourceHash
      Config = "outputs/rdmc_diversified_repair_restart_safe_model1_package/configs/$configName"
      Status = "LOCKED_LOCAL_LAUNCH_DISABLED"
   })
}

$queuePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv"
$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII

$manifest = [pscustomobject]@{
   Candidate = "rdmc_diversified_repair_restart_safe_v2"
   Status = "STATIC_ONLY_LOCKED"
   PromotionStatus = "NOT_PROMOTED"
   ForwardCandidateChanged = "NO"
   StartingCapital = 10000
   Currency = "USD"
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
   PredecessorSourceSha256 = $v1Hash
   SourceInputs = $sourceInputs.Count
   ProfileInputs = $profileInputs.Count
   ConfigCount = $queue.Count
   EntryPathSafetyStatus = "PASS_74_CHECKS"
   MomentumCostMarginGuard = "ENABLED"
   PortfolioCooldownAllLanes = "ENABLED"
   RealtimeProtectionStatus = "PASS_31_CHECKS"
   RealtimeEquityDrawdownClose = "ENABLED"
   RealtimeMissingStopClose = "ENABLED"
   NormalPositionManagement = "NEW_BAR"
   TradeResultSafetyStatus = "PASS_60_CHECKS"
   BrokerRetcodeVerification = "ENABLED"
   PostRequestStateVerification = "ENABLED"
   SynchronousTradeRequests = "ENABLED"
   SymbolNativeOrderFilling = "ENABLED"
   PendingOrderSafetyStatus = "PASS_45_CHECKS"
   ActiveOrderEntryBlock = "ENABLED"
   VerifiedResearchOrderCancel = "ENABLED"
   ForeignOrderOwnershipPreserved = "ENABLED"
   FlattenOrderFirst = "ENABLED"
   VolumeContractSafetyStatus = "PASS_43_CHECKS"
   BrokerStepAwareVolume = "ENABLED"
   PartialCloseStepNormalization = "ENABLED"
   AccountHistoryReconciliationStatus = "PASS_34_CHECKS"
   TransactionDrivenHistoryInvalidation = "ENABLED"
   PeriodicHistoryWatchdog = "ENABLED_60_SECONDS"
   PerTickHistoryRescan = "DISABLED"
   AccountModeSafetyStatus = "PASS_34_CHECKS"
   HedgingAccountRequired = "ENABLED"
   NettingAccountRejected = "ENABLED"
   ExchangeAccountRejected = "ENABLED"
   EntryPermissionSafetyStatus = "PASS_50_CHECKS"
   TerminalPermissionGate = "ENABLED"
   AccountPermissionGate = "ENABLED"
   DirectionalSymbolGate = "ENABLED"
   MarketOrderAndStopLossRequired = "ENABLED"
   ProtectiveExitPathPreserved = "ENABLED"
   OrderPreflightSafetyStatus = "PASS_55_CHECKS"
   ExactBrokerOrderCheck = "ENABLED"
   PreflightFailureBlocksSend = "ENABLED"
   PreflightBrokerCommentEvidence = "ENABLED"
   PostFillReconciliationStatus = "PASS_77_CHECKS"
   ResultLinkedPositionIdentity = "ENABLED"
   AttachedProtectionVerification = "ENABLED"
   ActualCashRiskReconciliation = "ENABLED"
   AggregateAccountRiskReconciliation = "ENABLED"
   IncompleteAccountRiskFailsClosed = "ENABLED"
   PostFillPositionCountReconciliation = "ENABLED"
   FailedReconciliationForcedClose = "ENABLED"
   FailedCloseRealtimeRetry = "ENABLED"
   StopModificationSafetyStatus = "PASS_50_CHECKS"
   ModifyOwnershipVerification = "ENABLED"
   TighteningOnlyStopModification = "ENABLED"
   StopRemovalBlocked = "ENABLED"
   SymbolNativeModifyTolerance = "ENABLED"
   CloseOwnershipSafetyStatus = "PASS_57_CHECKS"
   FullCloseOwnershipVerification = "ENABLED"
   PartialCloseOwnershipVerification = "ENABLED"
   StrictPartialVolumeContract = "ENABLED"
   PartialCloseDisappearanceRejected = "ENABLED"
   ExactPartialRemainderVerification = "ENABLED"
   CompileStatus = "NOT_RUN_LOCAL_LOCK_ACTIVE"
   BacktestStatus = "NOT_RUN_LOCAL_LOCK_ACTIVE"
   HistoricalBestChanged = "NO"
}
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_MANIFEST.csv"
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

$packagePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_PACKAGE.md"
$packageLines = @(
   "# RDMC Diversified Repair Restart-Safe Model1 Package",
   "",
   "Status: **STATIC ONLY / LOCKED / NOT PROMOTED**",
   "",
   'This package supersedes the uncompiled v1 package before its first MT5 run. It preserves the four-lane strategy and risk settings but repairs account restart behavior. It does not establish a new best or change the registered forward candidate.',
   "",
   "## Repair",
   "",
   '- First non-tester registration still requires an unused, flat account at the frozen `$10,000 USD` starting balance.',
   '- The starting-capital, funding-count, and peak-equity contracts persist under account-and-magic-scoped terminal global variables.',
   '- Restarts after ordinary profit or loss retain the original `$10,000` baseline and lifetime peak equity instead of comparing current balance with the starting deposit.',
   '- Deposits, withdrawals, credits, corrections, bonuses, foreign trade history, foreign open positions, missing persistence, and invalid stored peaks fail closed.',
   '- Broker commission, charge, and interest deal types are not misclassified as new funding.',
   '- Runtime history is refreshed before either momentum or primary entry evaluation. Position management and protective exits remain available.',
   '- All four order-opening sites now require broker-native lot sizing, account-wide exposure approval, trading-cost approval, margin approval, explicit magic, and bounded deviation before Buy/Sell.',
   '- The momentum lane now uses the same trading-cost and margin guards as the other three lanes.',
   '- Isolated lanes may bypass adaptive strategy pauses, but the hard portfolio consecutive-loss and four-hour post-loss cooldown gates can no longer be bypassed.',
   '- A lightweight per-tick emergency path issues close requests for both magic families on the 5% lifetime equity-drawdown limit or a missing/invalid protective stop.',
   '- The emergency path performs no trade-history scan, sleep, or retry loop; ordinary trailing, channel exits, and full period-risk calculations remain new-bar work.',
   '- All four entries require a completed broker retcode and a nonzero deal ticket; a locally valid or merely placed request is not logged as an entry.',
   '- Full closes, partial closes, and SL/TP modifications verify both the broker retcode and resulting position state before success logs or state markers are written.',
   '- Both trade executors are explicitly synchronous and use the symbol-native filling policy; successful entry logs use broker-confirmed deal, volume, and price fields.',
   '- Any active account order blocks new exposure, preventing a merely placed market request from being duplicated before it resolves.',
   '- Emergency, period-risk, weekend, session-end, and manual-news flattening cancel research-owned orders with verified broker results before closing positions.',
   '- Foreign orders are never canceled by the EA and instead fail the dedicated-account contract closed.',
   '- Entry, margin-cap, and partial-close volumes are rounded down with the broker-provided `SYMBOL_VOLUME_STEP`; precision is derived from the step instead of being hardcoded to two decimals.',
   '- Live account-history validation is invalidated by deal and generic trade events, with a fixed 60-second watchdog for missed or delayed events. Active positions and orders remain uncached and are checked on every entry evaluation.',
   '- Initialization requires `ACCOUNT_MARGIN_MODE_RETAIL_HEDGING` before capital registration, indicator allocation, or executor setup. Netting, exchange, and unknown accounting modes fail closed because ticket ownership and partial-close behavior depend on hedging semantics.',
   '- Every new entry requires live terminal, EA, and account trading permission plus a compatible symbol direction with market-order and protective-stop support.',
   '- Entry-permission checks stay inside shared exposure approval, so permission loss blocks new exposure without removing the protective management and close paths.',
   '- Both trade executors run MT5 `OrderCheck` on the exact side, volume, price, SL, TP, deviation, filling policy, magic, and comment before any Buy/Sell request.',
   '- A failed broker preflight blocks the send and preserves the check retcode and broker comment in failure evidence; protective close paths do not depend on entry preflight.',
   '- After a successful send, the exact broker result order or deal-linked immutable position identifier is reconciled to one unique expert-owned position; newest-position guessing is not used.',
   '- The broker-attached open price, volume, stop loss, and requested take-profit state are verified before an entry is accepted or its initial risk is registered.',
   '- Planned cash risk is compared with actual fill-to-stop cash risk. The new position may exceed planned risk by at most `5%` and can never exceed its configured per-position cash-risk cap.',
   '- After each fill, every open account position is reselected and broker-valued from its open price to attached stop. An unreadable position, missing/invalid stop, failed valuation, post-fill position-count breach, or aggregate account-risk breach rejects the fill.',
   '- The entry precheck and post-fill reconciliation share the same fail-closed account-risk helper, so a configurable multi-position profile cannot hide slippage behind a per-position-only comparison.',
   '- Reconciliation failures mark and force-close the exact filled ticket through the verified close wrapper. The marker is scoped to account, EA magic, and ticket; a failed emergency close remains marked for lightweight per-tick retry until the position is confirmed gone.',
   '- Initial-risk state is stored against the exact filled position ticket using its actual fill-to-stop distance for every entry lane.',
   '- One shared wrapper owns every raw `PositionModify` request. It selects the exact ticket first and verifies executor magic plus expert ownership before sending.',
   '- Existing and requested protective stops must both be present. Buy stops cannot move lower and sell stops cannot move higher beyond symbol-native half-tick tolerance; unavailable symbol geometry, stop removal, and unknown position types fail closed.',
   '- TP-only changes remain allowed when the stop is preserved. Completed modification retcodes and the final broker-attached SL/TP state are still verified before success.',
   '- One shared ownership selector gates every raw full-close, partial-close, and modification request by exact ticket, executor magic, expert reason, and symbol identity.',
   '- A full close succeeds only after an accepted broker retcode and confirmed ticket disappearance. A partial close must leave the same owned position open at the exact requested broker-step-normalized remainder.',
   '- Partial closes reject stale volume snapshots, off-step or below-minimum requests, full-close-sized requests, below-minimum remainders, unavailable symbol geometry, and unexpected position disappearance.',
   "",
   "## Frozen identity",
   "",
   ("- Source SHA-256: ``{0}``" -f $sourceHash),
   ("- Profile SHA-256: ``{0}``" -f $profileHash),
   ("- Predecessor source SHA-256: ``{0}``" -f $v1Hash),
   '- Source/profile inputs: `589 / 589`',
   '- Queue: `outputs/RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv`',
   "",
   "## Hard boundary",
   "",
   'The source is tester-only, real-account trading is disabled, and all 12 annual/YTD Model1 rows remain `LOCKED_LOCAL_LAUNCH_DISABLED`. The new cost, margin, hard-cooldown, intrabar emergency, and broker-result safeguards can change entries and exits. The active-order reconciliation can change entries and exits. Broker-volume reconciliation can change entries and exits. Post-fill risk reconciliation can change entries and exits. Tightening-only stop enforcement and ownership-checked close reconciliation can change exits too, so the earlier post-hoc collision score is not attributed to this executable path. Static checks cannot prove compilation, profit, drawdown, or restart behavior inside MT5. Compilation, annual and continuous Model1, annual and continuous real-tick Model4, cost stress, Monte Carlo, broker variation, and valid forward evidence are still required.'
)
[IO.File]::WriteAllLines($packagePath, $packageLines, [Text.Encoding]::ASCII)

$manifest
