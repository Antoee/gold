Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$package = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package"
$sourcePath = Join-Path $package "source\Professional_XAUUSD_EA.mq5"
$profilePath = Join-Path $package "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$v1SourcePath = Join-Path $repo "outputs\rdmc_diversified_repair_model1_package\source\Professional_XAUUSD_EA.mq5"
$queuePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv"
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_MANIFEST.csv"
$documentPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_PACKAGE.md"

$expectedSourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$expectedProfileHash = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
$expectedV1SourceHash = "4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5"

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

function Invoke-CapitalContractModel {
   param(
      [bool]$Tester = $false,
      [double]$Balance = 10000.0,
      [double]$Equity = 10000.0,
      [double]$Expected = 10000.0,
      [double]$TolerancePercent = 1.0,
      [int]$FundingCount = 1,
      [int]$TradeDealCount = 0,
      [int]$ForeignTradeCount = 0,
      [int]$OpenPositionCount = 0,
      [int]$ForeignOpenPositionCount = 0,
      [int]$ActiveOrderCount = 0,
      [int]$ForeignActiveOrderCount = 0,
      [int]$ResearchActiveOrderCount = 0,
      [bool]$StoredBalanceExists = $false,
      [double]$StoredBalance = 0.0,
      [bool]$StoredFundingExists = $false,
      [int]$StoredFundingCount = 0,
      [bool]$StoredPeakExists = $false,
      [double]$StoredPeak = 0.0
   )
   $tolerance = $Expected * [Math]::Max(0.0, $TolerancePercent) / 100.0
   if($Tester) {
      if($Expected -le 0.0 -or [Math]::Abs($Balance - $Expected) -gt $tolerance) { return "starting-capital contract" }
      return "allowed"
   }
   if($ForeignTradeCount -gt 0 -or $ForeignOpenPositionCount -gt 0 -or $ForeignActiveOrderCount -gt 0) { return "dedicated-account contract" }
   if($ResearchActiveOrderCount -gt 0) { return "active research order" }
   if($StoredBalanceExists) {
      if([Math]::Abs($StoredBalance - $Expected) -gt 0.01) { return "stored starting-capital contract" }
   }
   else {
      if($Expected -le 0.0 -or [Math]::Abs($Balance - $Expected) -gt $tolerance) { return "starting-capital contract" }
      if($TradeDealCount -gt 0 -or $OpenPositionCount -gt 0 -or $ActiveOrderCount -gt 0) { return "unused flat account contract" }
   }
   if($StoredFundingExists) {
      if($StoredFundingCount -ne $FundingCount) { return "funding changed" }
   }
   elseif($StoredBalanceExists) { return "funding persistence missing" }
   if($StoredPeakExists) {
      if($StoredPeak -le 0.0 -or $StoredPeak + $tolerance -lt $Expected) { return "stored peak invalid" }
   }
   elseif($StoredBalanceExists) { return "peak persistence missing" }
   elseif($Equity -le 0.0 -or [Math]::Abs($Equity - $Balance) -gt 0.01) { return "peak registration" }
   return "allowed"
}

foreach($required in @($sourcePath, $profilePath, $v1SourcePath, $queuePath, $manifestPath, $documentPath)) {
   Add-Check "required artifact: $([IO.Path]::GetFileName($required))" (Test-Path -LiteralPath $required -PathType Leaf) $required
}
if($checks.Where({ !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Required restart-safe package artifacts are missing."
}

$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
$v1Hash = (Get-FileHash -LiteralPath $v1SourcePath -Algorithm SHA256).Hash
Add-Check "v2 source hash frozen" ($sourceHash -eq $expectedSourceHash) $sourceHash
Add-Check "v2 profile hash frozen" ($profileHash -eq $expectedProfileHash) $profileHash
Add-Check "v1 predecessor unchanged" ($v1Hash -eq $expectedV1SourceHash) $v1Hash

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Get-Content -LiteralPath $profilePath
$sourceInputs = @([regex]::Matches($source, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=') |
   ForEach-Object { $_.Groups[1].Value })
$profileValues = @{}
foreach($line in $profile) {
   if($line -match '^([^;=]+)=([^|]*)(.*)$') { $profileValues[$matches[1]] = $matches[2] }
}
$missing = @($sourceInputs | Where-Object { !$profileValues.ContainsKey($_) })
$extra = @($profileValues.Keys | Where-Object { $_ -notin $sourceInputs })
Add-Check "589 source inputs remain below MT5 limit" ($sourceInputs.Count -eq 589) "source=$($sourceInputs.Count)"
Add-Check "profile freezes every source input" ($profileValues.Count -eq 589 -and $missing.Count -eq 0 -and $extra.Count -eq 0) "profile=$($profileValues.Count) missing=$($missing.Count) extra=$($extra.Count)"
Add-Check "source inputs are unique" (@($sourceInputs | Group-Object | Where-Object Count -gt 1).Count -eq 0) "inputs=$($sourceInputs.Count)"

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseInitialBalanceContract = 'true'
   InpExpectedInitialBalance = '10000.0'
   InpUseAccountCurrencyLock = 'true'
   InpRequiredAccountCurrency = 'USD'
   InpUseDedicatedAccountContract = 'true'
   InpRejectFundingChangesAfterRegistration = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpUseAccountWideExposureGuard = 'true'
   InpAccountWideMaxOpenRiskPercent = '0.75'
   InpAccountWideMaxPositions = '1'
   InpMaxPostFillRiskIncreasePercent = '5.00'
   InpMaxEquityDrawdownPercent = '5.00'
}.GetEnumerator()) {
   Add-Check "profile contract: $($contract.Key)" ($profileValues[$contract.Key] -eq $contract.Value) "$($profileValues[$contract.Key])"
}
Add-Check "profile identity is v2" ($profileValues.InpEvidenceProfileId -eq 'rdmc_diversified_repair_restart_safe_v2') $profileValues.InpEvidenceProfileId
Add-Check "profile source identity matches" ($profileValues.InpEvidenceSourceHash -eq $sourceHash) $profileValues.InpEvidenceSourceHash
Add-Check "v2 magic identities are distinct" ($profileValues.InpMagicNumber -eq '26071831' -and $profileValues.InpMOMagicNumber -eq '26071762') "primary=$($profileValues.InpMagicNumber) momentum=$($profileValues.InpMOMagicNumber)"

$fundingSection = Get-Section $source "bool IsFundingMutationDealType" "bool AccountHistoryContractSnapshot"
Add-Check "funding mutation types are explicit" (@('DEAL_TYPE_BALANCE','DEAL_TYPE_CREDIT','DEAL_TYPE_CORRECTION','DEAL_TYPE_BONUS').Where({ $fundingSection.Contains($_) }).Count -eq 4) "deposit/credit/correction/bonus"
Add-Check "broker costs are not classified as funding" (@('DEAL_TYPE_COMMISSION','DEAL_TYPE_CHARGE','DEAL_TYPE_INTEREST').Where({ $fundingSection.Contains($_) }).Count -eq 0) "commission/charge/interest excluded"

$capitalSection = Get-Section $source "bool ResearchCapitalContractAllows()" "bool RealAccountSafetyLockAllows()"
foreach($marker in @('AccountHistoryContractSnapshot','ForeignOpenPositionCount','ForeignActiveOrderCount','ResearchActiveOrderCount','GlobalVariableCheck(balanceKey)','FundingCountContractKey()','PeakEquityContractKey()','tradeDealCount > 0 || PositionsTotal() > 0 || OrdersTotal() > 0','balanceContractExists','peak-equity persistence is missing')) {
   Add-Check "capital contract marker: $marker" $capitalSection.Contains($marker) $marker
}

$riskSection = Get-Section $source "class CRiskManager" "class CPositionManager"
Add-Check "risk manager restores original capital baseline" ($riskSection.Contains('m_initialEquity = InpExpectedInitialBalance;') -and $riskSection.Contains('m_initialBalance = InpExpectedInitialBalance;')) "expected initial balance used"
Add-Check "risk manager restores persisted lifetime peak" ($riskSection.Contains('GlobalVariableGet(PeakEquityContractKey())') -and $riskSection.Contains('UpdatePeakEquity(equity);')) "peak loaded and updated"
Add-Check "peak persistence failure closes entry path" ($source.Contains('g_peakEquityPersistenceHealthy = false;') -and $source.Contains('if(!g_peakEquityPersistenceHealthy ||') -and $source.Contains('!g_criticalPersistenceHealthy ||') -and $source.Contains('Failed to initialize or reconcile critical persistent risk state.')) "fail closed"
$drawdownSection = Get-Section $source "double CurrentEquityDrawdownPercent()" "void RefreshConsecutiveLosses()"
Add-Check "peak write failure blocks the same risk check" ($drawdownSection.Contains('if(!g_peakEquityPersistenceHealthy)') -and $drawdownSection.Contains('return DBL_MAX;')) "blocking drawdown sentinel"

$environmentSection = Get-Section $source "bool TradeEnvironmentAllows(string &reason)" "bool TradeReadinessSafetyGateAllows()"
$runtimeIndex = $environmentSection.IndexOf('RuntimeAccountHistoryContractAllows(reason)', [StringComparison]::Ordinal)
$guardIndex = $environmentSection.IndexOf('if(!InpUseTradeEnvironmentGuard)', [StringComparison]::Ordinal)
Add-Check "runtime account contract precedes optional environment guard" ($runtimeIndex -ge 0 -and $guardIndex -gt $runtimeIndex) "runtime=$runtimeIndex guard=$guardIndex"
$readinessSection = Get-Section $source "bool TradeReadinessSafetyGateAllows()" "bool SymbolSafetyLockAllows()"
$readinessMarkers = @('starting-capital contract disabled or invalid','account currency contract disabled or invalid','dedicated-account contract disabled','funding-drift contract disabled','account-wide exposure guard disabled','account-wide open risk cap missing or too high','account-wide position cap missing or too high','account-wide unprotected exposure block disabled')
Add-Check "trade-readiness gate requires persistent account-wide safety" (@($readinessMarkers | Where-Object { !$readinessSection.Contains($_) }).Count -eq 0) "markers=$($readinessMarkers.Count)"

$onTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$onTradeIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($onTickIndex -ge 0 -and $onTradeIndex -gt $onTickIndex) { $source.Substring($onTickIndex, $onTradeIndex - $onTickIndex) } else { '' }
$dirtyIndex = $onTick.IndexOf('RefreshAccountHistoryWatchdog();', [StringComparison]::Ordinal)
$momentumIndex = $onTick.IndexOf('g_momentum.OnTick();', [StringComparison]::Ordinal)
Add-Check "bounded history refresh precedes momentum entry evaluation" ($dirtyIndex -ge 0 -and $momentumIndex -gt $dirtyIndex) "watchdog=$dirtyIndex momentum=$momentumIndex"

$scenarios = @(
   @{ Name='tester exact capital'; Expected='allowed'; Args=@{ Tester=$true; Balance=10000.0 } },
   @{ Name='tester capital mismatch'; Expected='starting-capital contract'; Args=@{ Tester=$true; Balance=100000.0 } },
   @{ Name='fresh live registration'; Expected='allowed'; Args=@{} },
   @{ Name='fresh live mismatch'; Expected='starting-capital contract'; Args=@{ Balance=100000.0; Equity=100000.0 } },
   @{ Name='restart after profit'; Expected='allowed'; Args=@{ Balance=12100.0; Equity=12050.0; StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=12500.0 } },
   @{ Name='restart after loss'; Expected='allowed'; Args=@{ Balance=9400.0; Equity=9350.0; StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=10200.0 } },
   @{ Name='funding change'; Expected='funding changed'; Args=@{ FundingCount=2; StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=10000.0 } },
   @{ Name='foreign closed trade'; Expected='dedicated-account contract'; Args=@{ ForeignTradeCount=1 } },
   @{ Name='foreign open position'; Expected='dedicated-account contract'; Args=@{ ForeignOpenPositionCount=1; OpenPositionCount=1 } },
   @{ Name='foreign active order'; Expected='dedicated-account contract'; Args=@{ ForeignActiveOrderCount=1; ActiveOrderCount=1 } },
   @{ Name='research active order'; Expected='active research order'; Args=@{ ResearchActiveOrderCount=1; ActiveOrderCount=1 } },
   @{ Name='unresolved active order registration'; Expected='unused flat account contract'; Args=@{ ActiveOrderCount=1 } },
   @{ Name='missing funding persistence'; Expected='funding persistence missing'; Args=@{ StoredBalanceExists=$true; StoredBalance=10000.0; StoredPeakExists=$true; StoredPeak=10000.0 } },
   @{ Name='missing peak persistence'; Expected='peak persistence missing'; Args=@{ StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1 } },
   @{ Name='invalid stored peak'; Expected='stored peak invalid'; Args=@{ StoredBalanceExists=$true; StoredBalance=10000.0; StoredFundingExists=$true; StoredFundingCount=1; StoredPeakExists=$true; StoredPeak=9000.0 } },
   @{ Name='used account registration'; Expected='unused flat account contract'; Args=@{ TradeDealCount=2 } },
   @{ Name='non-flat registration'; Expected='unused flat account contract'; Args=@{ OpenPositionCount=1 } }
)
foreach($scenario in $scenarios) {
   $modelArgs = $scenario.Args
   $actual = Invoke-CapitalContractModel @modelArgs
   Add-Check "state model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual expected=$($scenario.Expected)"
}

$queue = @(Import-Csv -LiteralPath $queuePath)
$manifest = @(Import-Csv -LiteralPath $manifestPath)
$configs = @(Get-ChildItem -LiteralPath (Join-Path $package 'configs') -Filter '*.ini' -File)
$reports = @(Get-ChildItem -LiteralPath (Join-Path $package 'reports') -File -ErrorAction SilentlyContinue)
$configContractPass = $true
$configProfilePass = $true
foreach($config in $configs) {
   $configLines = @(Get-Content -LiteralPath $config.FullName)
   foreach($marker in @('Optimization=0','Model=1','Deposit=10000','Currency=USD','Visual=0','ShutdownTerminal=1')) {
      if($configLines -notcontains $marker) { $configContractPass = $false }
   }
   $inputsIndex = [Array]::IndexOf($configLines, '[TesterInputs]')
   if($inputsIndex -lt 0) {
      $configProfilePass = $false
   }
   else {
      $embeddedProfile = @($configLines[($inputsIndex + 1)..($configLines.Count - 1)])
      if([string]::Join("`n", $embeddedProfile) -cne [string]::Join("`n", $profile)) {
         $configProfilePass = $false
      }
   }
}
Add-Check "queue contains 12 locked annual/YTD rows" ($queue.Count -eq 12 -and @($queue | Where-Object Status -ne 'LOCKED_LOCAL_LAUNCH_DISABLED').Count -eq 0) "rows=$($queue.Count)"
Add-Check "queue identity and capital are frozen" (@($queue | Where-Object { $_.SourceSha256 -ne $sourceHash -or $_.ProfileSha256 -ne $profileHash -or $_.Deposit -ne '10000' -or $_.Model -ne '1' }).Count -eq 0) "rows=$($queue.Count)"
Add-Check "package contains 12 nonvisual configs" ($configs.Count -eq 12 -and @($configs | Where-Object { (Get-Content -Raw $_.FullName) -notmatch '(?m)^Visual=0\r?$' }).Count -eq 0) "configs=$($configs.Count)"
Add-Check "every config freezes the tester contract" $configContractPass "configs=$($configs.Count)"
Add-Check "every config embeds the exact profile" $configProfilePass "profile_lines=$($profile.Count)"
Add-Check "locked package contains no MT5 reports" ($reports.Count -eq 0) "reports=$($reports.Count)"
Add-Check "manifest remains static and unpromoted" ($manifest.Count -eq 1 -and $manifest[0].Status -eq 'STATIC_ONLY_LOCKED' -and $manifest[0].PromotionStatus -eq 'NOT_PROMOTED' -and $manifest[0].HistoricalBestChanged -eq 'NO') "rows=$($manifest.Count)"
Add-Check "manifest freezes all-entry execution hardening" ($manifest[0].EntryPathSafetyStatus -eq 'PASS_74_CHECKS' -and $manifest[0].MomentumCostMarginGuard -eq 'ENABLED' -and $manifest[0].PortfolioCooldownAllLanes -eq 'ENABLED') "$($manifest[0].EntryPathSafetyStatus)"
Add-Check "manifest freezes lightweight realtime protection" ($manifest[0].RealtimeProtectionStatus -eq 'PASS_60_CHECKS' -and $manifest[0].RealtimeEquityDrawdownClose -eq 'ENABLED' -and $manifest[0].RealtimeMissingStopClose -eq 'ENABLED' -and $manifest[0].NormalPositionManagement -eq 'NEW_BAR') "$($manifest[0].RealtimeProtectionStatus)"
Add-Check "manifest freezes always-on critical position state" ($manifest[0].RealtimeCriticalPositionIdentityRequired -eq 'ENABLED' -and $manifest[0].RealtimeInitialRiskStateRequired -eq 'ENABLED' -and $manifest[0].CriticalStateValidationAlwaysOn -eq 'ENABLED' -and $manifest[0].RestartMissingStateEmergencyFlatten -eq 'ENABLED') "$($manifest[0].RealtimeInitialRiskStateRequired)"
Add-Check "manifest freezes disabled-momentum cleanup" ($manifest[0].MomentumOwnershipIndependentOfEnable -eq 'ENABLED' -and $manifest[0].DisabledMomentumExposureFlatten -eq 'ENABLED' -and $manifest[0].DisabledMomentumCloseExecutorReady -eq 'ENABLED' -and $manifest[0].PositiveDistinctMagicContract -eq 'ENABLED') "$($manifest[0].DisabledMomentumExposureFlatten)"
Add-Check "manifest freezes broker-result verification" ($manifest[0].TradeResultSafetyStatus -eq 'PASS_60_CHECKS' -and $manifest[0].BrokerRetcodeVerification -eq 'ENABLED' -and $manifest[0].PostRequestStateVerification -eq 'ENABLED' -and $manifest[0].SynchronousTradeRequests -eq 'ENABLED' -and $manifest[0].SymbolNativeOrderFilling -eq 'ENABLED') "$($manifest[0].TradeResultSafetyStatus)"
Add-Check "manifest freezes pending-order reconciliation" ($manifest[0].PendingOrderSafetyStatus -eq 'PASS_53_CHECKS' -and $manifest[0].ActiveOrderEntryBlock -eq 'ENABLED' -and $manifest[0].VerifiedResearchOrderCancel -eq 'ENABLED' -and $manifest[0].ForeignOrderOwnershipPreserved -eq 'ENABLED' -and $manifest[0].FlattenOrderFirst -eq 'ENABLED' -and $manifest[0].RegisteredOrderRestartRecovery -eq 'ENABLED' -and $manifest[0].FirstRegistrationActiveOrderRejected -eq 'ENABLED' -and $manifest[0].ActiveOrderRecoveryAlwaysOn -eq 'ENABLED' -and $manifest[0].RestartOrderBeforeReconciliation -eq 'ENABLED') "$($manifest[0].PendingOrderSafetyStatus)"
Add-Check "manifest freezes broker-step-aware volume" ($manifest[0].VolumeContractSafetyStatus -eq 'PASS_43_CHECKS' -and $manifest[0].BrokerStepAwareVolume -eq 'ENABLED' -and $manifest[0].PartialCloseStepNormalization -eq 'ENABLED') "$($manifest[0].VolumeContractSafetyStatus)"
Add-Check "manifest freezes bounded history reconciliation" ($manifest[0].AccountHistoryReconciliationStatus -eq 'PASS_34_CHECKS' -and $manifest[0].TransactionDrivenHistoryInvalidation -eq 'ENABLED' -and $manifest[0].PeriodicHistoryWatchdog -eq 'ENABLED_60_SECONDS' -and $manifest[0].PerTickHistoryRescan -eq 'DISABLED') "$($manifest[0].AccountHistoryReconciliationStatus)"
Add-Check "manifest freezes hedging account mode" ($manifest[0].AccountModeSafetyStatus -eq 'PASS_34_CHECKS' -and $manifest[0].HedgingAccountRequired -eq 'ENABLED' -and $manifest[0].NettingAccountRejected -eq 'ENABLED' -and $manifest[0].ExchangeAccountRejected -eq 'ENABLED') "$($manifest[0].AccountModeSafetyStatus)"
Add-Check "manifest freezes entry-permission safety" ($manifest[0].EntryPermissionSafetyStatus -eq 'PASS_50_CHECKS' -and $manifest[0].TerminalPermissionGate -eq 'ENABLED' -and $manifest[0].AccountPermissionGate -eq 'ENABLED' -and $manifest[0].DirectionalSymbolGate -eq 'ENABLED' -and $manifest[0].MarketOrderAndStopLossRequired -eq 'ENABLED') "$($manifest[0].EntryPermissionSafetyStatus)"
Add-Check "manifest preserves protective exits across entry permission loss" ($manifest[0].ProtectiveExitPathPreserved -eq 'ENABLED') $manifest[0].ProtectiveExitPathPreserved
Add-Check "manifest freezes exact-request broker preflight" ($manifest[0].OrderPreflightSafetyStatus -eq 'PASS_55_CHECKS' -and $manifest[0].ExactBrokerOrderCheck -eq 'ENABLED' -and $manifest[0].PreflightFailureBlocksSend -eq 'ENABLED' -and $manifest[0].PreflightBrokerCommentEvidence -eq 'ENABLED') "$($manifest[0].OrderPreflightSafetyStatus)"
Add-Check "manifest freezes post-fill reconciliation" ($manifest[0].PostFillReconciliationStatus -eq 'PASS_86_CHECKS' -and $manifest[0].ResultLinkedPositionIdentity -eq 'ENABLED' -and $manifest[0].PositivePostFillPositionIdentifierRequired -eq 'ENABLED' -and $manifest[0].AttachedProtectionVerification -eq 'ENABLED' -and $manifest[0].ExactAttachedStopVerification -eq 'ENABLED' -and $manifest[0].ExactAttachedTargetVerification -eq 'ENABLED' -and $manifest[0].UnexpectedAttachedTargetRejected -eq 'ENABLED' -and $manifest[0].ActualCashRiskReconciliation -eq 'ENABLED' -and $manifest[0].AggregateAccountRiskReconciliation -eq 'ENABLED' -and $manifest[0].IncompleteAccountRiskFailsClosed -eq 'ENABLED' -and $manifest[0].PostFillPositionCountReconciliation -eq 'ENABLED' -and $manifest[0].FailedReconciliationForcedClose -eq 'ENABLED' -and $manifest[0].FailedCloseRealtimeRetry -eq 'ENABLED') "$($manifest[0].PostFillReconciliationStatus)"
Add-Check "manifest freezes tightening-only stop modification" ($manifest[0].StopModificationSafetyStatus -eq 'PASS_50_CHECKS' -and $manifest[0].ModifyOwnershipVerification -eq 'ENABLED' -and $manifest[0].TighteningOnlyStopModification -eq 'ENABLED' -and $manifest[0].StopRemovalBlocked -eq 'ENABLED' -and $manifest[0].SymbolNativeModifyTolerance -eq 'ENABLED') "$($manifest[0].StopModificationSafetyStatus)"
Add-Check "manifest freezes ownership-checked closes" ($manifest[0].CloseOwnershipSafetyStatus -eq 'PASS_57_CHECKS' -and $manifest[0].FullCloseOwnershipVerification -eq 'ENABLED' -and $manifest[0].PartialCloseOwnershipVerification -eq 'ENABLED' -and $manifest[0].StrictPartialVolumeContract -eq 'ENABLED' -and $manifest[0].PartialCloseDisappearanceRejected -eq 'ENABLED' -and $manifest[0].ExactPartialRemainderVerification -eq 'ENABLED') "$($manifest[0].CloseOwnershipSafetyStatus)"
Add-Check "manifest freezes verified persistent trade state" ($manifest[0].PersistentTradeStateSafetyStatus -eq 'PASS_64_CHECKS' -and $manifest[0].VerifiedPersistentWrites -eq 'ENABLED' -and $manifest[0].CriticalReadbackVerification -eq 'ENABLED' -and $manifest[0].WriteAheadOneShotActions -eq 'ENABLED' -and $manifest[0].FailedReservationBlocksAction -eq 'ENABLED' -and $manifest[0].FailedRollbackPoisonsHealth -eq 'ENABLED' -and $manifest[0].InitialRiskPersistenceRequired -eq 'ENABLED' -and $manifest[0].PersistenceFailureEmergencyFlatten -eq 'ENABLED' -and $manifest[0].ExcursionWriteCoalescing -eq 'ENABLED') "$($manifest[0].PersistentTradeStateSafetyStatus)"
Add-Check "manifest freezes scoped persistent position identity" ($manifest[0].PersistentPositionIdentitySafetyStatus -eq 'PASS_102_CHECKS' -and $manifest[0].AccountScopedPositionState -eq 'ENABLED' -and $manifest[0].MagicScopedPositionState -eq 'ENABLED' -and $manifest[0].ImmutablePositionIdentifierState -eq 'ENABLED' -and $manifest[0].TicketDerivedStateKeying -eq 'ENABLED' -and $manifest[0].IdentifierExactStateRetirement -eq 'ENABLED' -and $manifest[0].IdentifierTicketAliasGuard -eq 'ENABLED' -and $manifest[0].OrphanedPositionStateReconciliation -eq 'ENABLED' -and $manifest[0].OfflineExitStateRetirement -eq 'ENABLED' -and $manifest[0].InitializationStateReconciliation -eq 'ENABLED' -and $manifest[0].TransactionDrivenStateReconciliation -eq 'ENABLED' -and $manifest[0].ReconciliationFailureEmergencyFlatten -eq 'ENABLED' -and $manifest[0].CriticalStateBeforeReconciliation -eq 'ENABLED' -and $manifest[0].UnreadablePositionSnapshotBlocksProcessing -eq 'ENABLED' -and $manifest[0].Base36StateSchemaValidation -eq 'ENABLED' -and $manifest[0].PerTickGlobalVariableScan -eq 'DISABLED' -and $manifest[0].CompactBase36GlobalKeys -eq 'ENABLED' -and $manifest[0].TerminalGlobalNameLimitGuard -eq 'ENABLED' -and $manifest[0].PartialExitStatePreservation -eq 'ENABLED' -and $manifest[0].FullExitStateRetirement -eq 'ENABLED' -and $manifest[0].EaCloseImmediateStateRetirement -eq 'ENABLED' -and $manifest[0].UnreadablePositionScanPreservesState -eq 'ENABLED' -and $manifest[0].TicketOnlyPositionKeys -eq 'ABSENT') "$($manifest[0].PersistentPositionIdentitySafetyStatus)"

$document = Get-Content -LiteralPath $documentPath -Raw
Add-Check "package states restart repair boundary" ($document.Contains('supersedes the uncompiled v1 package') -and $document.Contains('does not establish a new best') -and $document.Contains('Static checks cannot prove compilation')) "boundary present"
Add-Check "package states entry-hardening evidence boundary" ($document.Contains('All four order-opening sites') -and $document.Contains('earlier post-hoc collision score is not attributed')) "boundary present"
Add-Check "package states realtime efficiency boundary" ($document.Contains('lightweight per-tick emergency path') -and $document.Contains('performs no trade-history scan') -and $document.Contains('Both research magics must remain positive and distinct') -and $document.Contains('remain owned when momentum is disabled') -and $document.Contains('contract runs before capital-state registration') -and $document.Contains('close executor is configured before the disabled early return') -and $document.Contains('instead of becoming unmanaged') -and $document.Contains('intrabar emergency') -and $document.Contains('disabled-lane cleanup') -and $document.Contains('can change entries and exits')) "boundary present"
Add-Check "package states broker-result evidence boundary" ($document.Contains('completed broker retcode') -and $document.Contains('resulting position state') -and $document.Contains('broker-result') -and $document.Contains('can change entries and exits')) "boundary present"
Add-Check "package states pending-order evidence boundary" ($document.Contains('active account order blocks new exposure') -and $document.Contains('verified starting-capital registration permits initialization') -and $document.Contains('first registration with any active order still fails closed') -and $document.Contains('always-on emergency condition') -and $document.Contains('before position-state reconciliation') -and $document.Contains('cancel research-owned orders') -and $document.Contains('Foreign orders are never canceled') -and $document.Contains('registered-restart recovery before reconciliation') -and $document.Contains('can change entries and exits')) "boundary present"
Add-Check "package states broker-volume evidence boundary" ($document.Contains('SYMBOL_VOLUME_STEP') -and $document.Contains('precision is derived') -and $document.Contains('Broker-volume reconciliation can change entries and exits')) "boundary present"
Add-Check "package states bounded history reconciliation" ($document.Contains('generic trade events') -and $document.Contains('fixed 60-second watchdog') -and $document.Contains('positions and orders remain uncached')) "boundary present"
Add-Check "package states hedging-only account contract" ($document.Contains('ACCOUNT_MARGIN_MODE_RETAIL_HEDGING') -and $document.Contains('Netting, exchange, and unknown accounting modes fail closed') -and $document.Contains('partial-close behavior depend')) "boundary present"
Add-Check "package states entry-permission contract" ($document.Contains('terminal, EA, and account trading permission') -and $document.Contains('compatible symbol direction') -and $document.Contains('market-order and protective-stop support')) "boundary present"
Add-Check "package preserves protective paths when entries are blocked" ($document.Contains('permission loss blocks new exposure') -and $document.Contains('protective management and close paths')) "boundary present"
Add-Check "package states exact-request broker preflight" ($document.Contains('MT5 `OrderCheck` on the exact side') -and $document.Contains('failed broker preflight blocks the send') -and $document.Contains('protective close paths do not depend on entry preflight')) "boundary present"
Add-Check "package states result-linked post-fill identity" ($document.Contains('deal-linked immutable position identifier') -and $document.Contains('one unique expert-owned position') -and $document.Contains('newest-position guessing is not used') -and $document.Contains('positive immutable `POSITION_IDENTIFIER`') -and $document.Contains('accepted, logged, or assigned durable risk state') -and $document.Contains('force-closes the exact captured ticket')) "boundary present"
Add-Check "package states attached-protection and actual-risk contract" ($document.Contains('broker-attached open price and volume') -and $document.Contains('attached SL/TP prices must match the exact requested state') -and $document.Contains('half the larger symbol point or trade tick') -and $document.Contains('target attached when none was requested is rejected') -and $document.Contains('actual fill-to-stop cash risk') -and $document.Contains('at most `5%`') -and $document.Contains('per-position cash-risk cap')) "boundary present"
Add-Check "package states aggregate account-risk reconciliation" ($document.Contains('every open account position is reselected') -and $document.Contains('post-fill position-count breach') -and $document.Contains('aggregate account-risk breach rejects the fill') -and $document.Contains('same fail-closed account-risk helper') -and $document.Contains('multi-position profile')) "boundary present"
Add-Check "package states persistent failed-close recovery" ($document.Contains('force-close the exact filled ticket') -and $document.Contains('scoped to account, EA magic, and ticket') -and $document.Contains('per-tick retry') -and $document.Contains('confirmed gone')) "boundary present"
Add-Check "package states tightening-only stop contract" ($document.Contains('One shared wrapper owns every raw `PositionModify` request') -and $document.Contains('Buy stops cannot move lower') -and $document.Contains('sell stops cannot move higher') -and $document.Contains('unavailable symbol geometry') -and $document.Contains('stop removal') -and $document.Contains('TP-only changes remain allowed')) "boundary present"
Add-Check "package states close ownership and exact partial contract" ($document.Contains('One shared ownership selector gates every raw full-close') -and $document.Contains('confirmed ticket disappearance') -and $document.Contains('exact requested broker-step-normalized remainder') -and $document.Contains('reject stale volume snapshots') -and $document.Contains('unexpected position disappearance')) "boundary present"
Add-Check "package states durable write-ahead trade state" ($document.Contains('operation result plus finite readback') -and $document.Contains('reserve durable one-shot state before the broker request') -and $document.Contains('Reservation failure blocks the action') -and $document.Contains('Initial fill-to-stop risk must persist') -and $document.Contains('Independently of optional risk-close settings') -and $document.Contains('positive immutable identifier') -and $document.Contains('finite, positive initial-risk record') -and $document.Contains('flattens both research lanes before management or entry') -and $document.Contains('flattened before momentum processing') -and $document.Contains('MFE and MAE persistence writes are coalesced')) "boundary present"
Add-Check "package states scoped position identity lifecycle" ($document.Contains('base-36 account login, strategy magic, and immutable `POSITION_IDENTIFIER`') -and $document.Contains('below MT5 terminal-global name limits') -and $document.Contains('isolated across account switches') -and $document.Contains('derive identity only from a selected position ticket') -and $document.Contains('never reinterpret it as a ticket') -and $document.Contains('equals a closed identifier') -and $document.Contains('redirecting cleanup') -and $document.Contains('offline SL/TP exits or transaction ordering') -and $document.Contains('not scanned on every tick') -and $document.Contains('uppercase base-36 identifier suffix') -and $document.Contains('Unrelated or malformed terminal globals are ignored') -and $document.Contains('processing remains blocked') -and $document.Contains('Partial exits retain runner state') -and $document.Contains('Full exits retire all scoped state') -and $document.Contains('unreadable active-position scan preserves persistent state') -and $document.Contains('obsolete ticket-only key family is absent')) "boundary present"
Add-Check "registered forward candidate stays unchanged" ($document.Contains('does not') -and $manifest[0].ForwardCandidateChanged -eq 'NO') $manifest[0].ForwardCandidateChanged
Add-Check "no account identifier published" ($document -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $document -notmatch '(?i)login\s*[:=]\s*\d{5,}') "public markdown clean"
Add-Check "no GitHub token published" ($document -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}') "public markdown clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) restart-safe package checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC restart-safe package checks"
