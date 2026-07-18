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

function Test-PersistentWriteModel(
   [bool]$KeyValid,
   [bool]$ValueValid,
   [bool]$SetSucceeded,
   [bool]$Exists,
   [bool]$ReadbackMatches
) {
   return $KeyValid -and $ValueValid -and $SetSucceeded -and $Exists -and $ReadbackMatches
}

function Invoke-OneShotModel(
   [bool]$ReservationSucceeded,
   [bool]$ActionSucceeded,
   [bool]$ClearSucceeded
) {
   $submitted = $false
   $markerPresent = $false
   $healthy = $true
   if(!$ReservationSucceeded) {
      $healthy = $false
      return [pscustomobject]@{ Submitted=$submitted; Marker=$markerPresent; Healthy=$healthy }
   }

   $markerPresent = $true
   $submitted = $true
   if($ActionSucceeded) {
      return [pscustomobject]@{ Submitted=$submitted; Marker=$markerPresent; Healthy=$healthy }
   }

   if($ClearSucceeded) {
      $markerPresent = $false
   }
   else {
      $healthy = $false
   }
   return [pscustomobject]@{ Submitted=$submitted; Marker=$markerPresent; Healthy=$healthy }
}

function Invoke-InitialRiskModel([bool]$WriteSucceeded, [bool]$ImmediateCloseSucceeded) {
   return [pscustomobject]@{
      EntryAccepted = $WriteSucceeded
      CloseRequested = !$WriteSucceeded
      PositionRemains = !$WriteSucceeded -and !$ImmediateCloseSucceeded
      CriticalHealthy = $WriteSucceeded
      NextTickFlatten = !$WriteSucceeded -and !$ImmediateCloseSucceeded
   }
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Persistent-state audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$setHelper = Get-Section $source "bool SetCriticalPersistentState(" "bool DeleteCriticalPersistentState("
$deleteHelper = Get-Section $source "bool DeleteCriticalPersistentState(" "bool SelectOwnedExpertPosition("
$entry = Get-Section $source "bool ExecuteMarketEntry(CValidatedTrade &executor," "bool ExecutePositionClose(CTrade &executor, const ulong ticket)"
$initialRisk = Get-Section $source "bool StoreInitialRisk(" "class CIndicators"
$stateMethods = Get-Section $source "   bool AlreadyPartiallyClosed(" "   double ProfitR("
$tpExpansion = Get-Section $source "   void PostPartialRunnerTPExpansion(" "   void OpenBasketPartialHarvest()"
$basketHarvest = Get-Section $source "   void OpenBasketPartialHarvest()" "   void Manage(const ENUM_TRADE_BIAS currentSignalBias)"
$manage = Get-Section $source "   void Manage(const ENUM_TRADE_BIAS currentSignalBias)" "class CMomentumLane"
$momentumEntry = Get-Section $source "   bool OpenPosition(const bool buy, const double atr)" "   bool TryChannelExit("
$capital = Get-Section $source "bool ResearchCapitalContractAllows()" "bool RealAccountSafetyLockAllows()"
$onInit = Get-Section $source "int OnInit()" "void OnDeinit(const int reason)"
$finalOnTickIndex = $source.LastIndexOf("void OnTick()", [StringComparison]::Ordinal)
$finalTransactionIndex = $source.IndexOf("void OnTradeTransaction(", $finalOnTickIndex, [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }

Add-Check "source version is 1.23" ($source.Contains('#property version   "1.23"')) "version"
Add-Check "description advertises verified account-scoped state" ($source.Contains('verified account-scoped position state')) "description"
Add-Check "one raw terminal-global write site remains" ([regex]::Matches($source, 'GlobalVariableSet\(').Count -eq 1) "raw set=1"
Add-Check "one raw terminal-global delete site remains" ([regex]::Matches($source, 'GlobalVariableDel\(').Count -eq 1) "raw delete=1"
Add-Check "all critical writes route through shared verifier" ([regex]::Matches($source, 'SetCriticalPersistentState\(').Count -eq 15) "definition plus 14 callers"
Add-Check "all critical deletes route through shared verifier" ([regex]::Matches($source, 'DeleteCriticalPersistentState\(').Count -eq 14) "definition plus 13 callers"
Add-Check "write verifier rejects invalid keys and values" ($setHelper.Contains('StringLen(key) <= 0') -and $setHelper.Contains('!MathIsValidNumber(value)')) "input validation"
Add-Check "write verifier checks broker write and key existence" ($setHelper.Contains('GlobalVariableSet(key, value) <= 0') -and $setHelper.Contains('!GlobalVariableCheck(key)')) "write result"
Add-Check "write verifier validates finite readback" ($setHelper.Contains('double stored = GlobalVariableGet(key)') -and $setHelper.Contains('!MathIsValidNumber(stored)')) "readback"
Add-Check "write verifier uses scale-aware readback tolerance" ($setHelper.Contains('MathAbs(value) * 0.000000000001') -and $setHelper.Contains('MathAbs(stored - value) > tolerance')) "tolerance"
Add-Check "write verifier poisons critical health on every failure" ([regex]::Matches($setHelper, 'g_criticalPersistenceHealthy = false;').Count -eq 3) "three failure paths"
Add-Check "delete verifier accepts already absent state" ($deleteHelper.Contains('if(!GlobalVariableCheck(key))') -and $deleteHelper.Contains('return true;')) "idempotent delete"
Add-Check "delete verifier confirms durable absence" ($deleteHelper.Contains('!GlobalVariableDel(key) || GlobalVariableCheck(key)')) "delete readback"
Add-Check "delete failure poisons critical health" ([regex]::Matches($deleteHelper, 'g_criticalPersistenceHealthy = false;').Count -eq 2) "failure paths"

Add-Check "post-fill forced-close marker is verified" ($entry.Contains('SetCriticalPersistentState(PostFillForcedCloseKey(')) "forced-close state"
Add-Check "post-fill marker precedes emergency close" ($entry.IndexOf('SetCriticalPersistentState(PostFillForcedCloseKey(', [StringComparison]::Ordinal) -lt $entry.IndexOf('ExecutePositionClose(executor, ticket)', [StringComparison]::Ordinal)) "write before close"
Add-Check "initial-risk storage returns verified status" ($initialRisk.Contains('bool StoreInitialRisk(') -and $initialRisk.Contains('return SetCriticalPersistentState(InitialRiskKey(ticket), riskDistance);')) "verified initial risk"
Add-Check "invalid initial-risk identity poisons health" ($initialRisk.Contains('ticket == 0 || riskDistance <= 0.0') -and $initialRisk.Contains('g_criticalPersistenceHealthy = false;')) "invalid state"
Add-Check "primary initial-risk failure closes exact fill" ($initialRisk.Contains('PersistPrimaryInitialRiskOrClose') -and $initialRisk.Contains('ExecutePositionClose(executor, ticket)')) "primary emergency close"
Add-Check "all three primary entry lanes require durable initial risk" ([regex]::Matches($source, 'PersistPrimaryInitialRiskOrClose\(trade\)').Count -eq 3) "three primary paths"
Add-Check "momentum entry requires durable initial risk" ($momentumEntry.Contains('SetCriticalPersistentState(MomentumRiskKey(filledTicket), filledRiskDistance)')) "momentum risk state"
Add-Check "momentum risk failure closes exact fill" ($momentumEntry.Contains('ExecutePositionClose(m_trade, filledTicket)') -and $momentumEntry.Contains('return false;')) "momentum emergency close"

Add-Check "partial marker uses verified write" ($stateMethods.Contains('bool MarkPartialClose(') -and $stateMethods.Contains('SetCriticalPersistentState(PartialCloseKey(ticket), TimeCurrent())')) "partial reserve"
Add-Check "partial marker has verified rollback" ($stateMethods.Contains('bool ClearPartialClose(') -and $stateMethods.Contains('DeleteCriticalPersistentState(PartialCloseKey(ticket))')) "partial rollback"
Add-Check "basket marker uses verified write and rollback" ($stateMethods.Contains('bool MarkBasketHarvest(') -and $stateMethods.Contains('bool ClearBasketHarvest(') -and $stateMethods.Contains('SetCriticalPersistentState(BasketHarvestKey(ticket), TimeCurrent())') -and $stateMethods.Contains('DeleteCriticalPersistentState(BasketHarvestKey(ticket))')) "basket reserve"
Add-Check "runner target marker uses verified write and rollback" ($stateMethods.Contains('bool MarkPostPartialRunnerTPExpanded(') -and $stateMethods.Contains('bool ClearPostPartialRunnerTPExpanded(') -and $stateMethods.Contains('SetCriticalPersistentState(PostPartialRunnerTPKey(ticket), TimeCurrent())') -and $stateMethods.Contains('DeleteCriticalPersistentState(PostPartialRunnerTPKey(ticket))')) "target reserve"
Add-Check "runner target reserves before modification" ($tpExpansion.IndexOf('MarkPostPartialRunnerTPExpanded(ticket)', [StringComparison]::Ordinal) -lt $tpExpansion.IndexOf('ModifyAndLog(ticket', [StringComparison]::Ordinal)) "write-ahead target"
Add-Check "failed runner target modification rolls back" ($tpExpansion.Contains('if(!ModifyAndLog(ticket,') -and $tpExpansion.Contains('ClearPostPartialRunnerTPExpanded(ticket);')) "target rollback"
Add-Check "basket harvest reserves before partial close" ($basketHarvest.IndexOf('MarkBasketHarvest(ticket)', [StringComparison]::Ordinal) -lt $basketHarvest.IndexOf('PartialCloseAndLog(ticket', [StringComparison]::Ordinal)) "write-ahead basket"
Add-Check "failed basket harvest rolls back" ($basketHarvest.Contains('else') -and $basketHarvest.Contains('ClearBasketHarvest(ticket);')) "basket rollback"
$normalizedBasketHarvest = $basketHarvest.Replace("`r`n", "`n").Replace("`r", "`n")
Add-Check "basket rollback else stays attached to partial request" ($normalizedBasketHarvest.Contains("         }`n         else`n            ClearBasketHarvest(ticket);")) "direct else attachment"
Add-Check "all three primary partial paths reserve first" ([regex]::Matches($manage, 'MarkPartialClose\(ticket\)').Count -eq 3) "three partial reservations"
Add-Check "all three primary partial paths roll back failures" ([regex]::Matches($manage, 'ClearPartialClose\(ticket\)').Count -eq 3) "three partial rollbacks"

Add-Check "peak-equity writes use verified persistence" ([regex]::Matches($source, 'SetCriticalPersistentState\(PeakEquityContractKey\(\), m_peakEquity\)').Count -eq 2) "init and update"
Add-Check "capital registration uses verified persistence" ($capital.Contains('SetCriticalPersistentState(fundingKey, (double)fundingCount)') -and $capital.Contains('SetCriticalPersistentState(peakKey, equity)') -and $capital.Contains('SetCriticalPersistentState(InitialBalanceContractKey(), expected)')) "three capital keys"
Add-Check "MFE writes only when the maximum advances" ($stateMethods.Contains('if(maxR <= stored)') -and $stateMethods.Contains('SetCriticalPersistentState(key, maxR)')) "efficient MFE"
Add-Check "MAE writes only when the minimum advances" ($stateMethods.Contains('if(minR >= stored)') -and $stateMethods.Contains('SetCriticalPersistentState(key, minR)')) "efficient MAE"
Add-Check "initialization fails on critical persistence" ($onInit.Contains('!g_peakEquityPersistenceHealthy || !g_criticalPersistenceHealthy') -and $onInit.Contains('return INIT_FAILED;')) "init fail closed"
Add-Check "runtime account contract blocks unhealthy persistence" ($source.Contains('reason = "critical trade-state persistence";') -and $source.Contains('if(!g_criticalPersistenceHealthy)')) "entry block"
Add-Check "OnTick flattens on persistence failure unconditionally" ($onTick.IndexOf('if(!g_criticalPersistenceHealthy)', [StringComparison]::Ordinal) -lt $onTick.IndexOf('if(InpClosePositionsOnRiskLimit)', [StringComparison]::Ordinal) -and $onTick.Contains('positionManager.CloseAll(persistenceReason)') -and $onTick.Contains('g_momentum.CloseAll(persistenceReason)')) "hard flatten"
Add-Check "persistence failure blocks momentum processing" ($onTick.IndexOf('if(!g_criticalPersistenceHealthy)', [StringComparison]::Ordinal) -lt $onTick.IndexOf('g_momentum.OnTick()', [StringComparison]::Ordinal)) "before lane tick"

$writeScenarios = @(
   @{ Name='verified write'; Expected=$true; Key=$true; Value=$true; Set=$true; Exists=$true; Match=$true },
   @{ Name='invalid key'; Expected=$false; Key=$false; Value=$true; Set=$true; Exists=$true; Match=$true },
   @{ Name='invalid value'; Expected=$false; Key=$true; Value=$false; Set=$true; Exists=$true; Match=$true },
   @{ Name='write failure'; Expected=$false; Key=$true; Value=$true; Set=$false; Exists=$false; Match=$false },
   @{ Name='missing readback'; Expected=$false; Key=$true; Value=$true; Set=$true; Exists=$false; Match=$false },
   @{ Name='mismatched readback'; Expected=$false; Key=$true; Value=$true; Set=$true; Exists=$true; Match=$false }
)
foreach($scenario in $writeScenarios) {
   $actual = Test-PersistentWriteModel $scenario.Key $scenario.Value $scenario.Set $scenario.Exists $scenario.Match
   Add-Check "write model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

$reservedSuccess = Invoke-OneShotModel $true $true $true
Add-Check "one-shot model: success submits after reservation" ($reservedSuccess.Submitted -and $reservedSuccess.Marker -and $reservedSuccess.Healthy) "$reservedSuccess"
$reservationFailure = Invoke-OneShotModel $false $true $true
Add-Check "one-shot model: reservation failure blocks broker action" (!$reservationFailure.Submitted -and !$reservationFailure.Marker -and !$reservationFailure.Healthy) "$reservationFailure"
$actionFailure = Invoke-OneShotModel $true $false $true
Add-Check "one-shot model: action failure clears reservation" ($actionFailure.Submitted -and !$actionFailure.Marker -and $actionFailure.Healthy) "$actionFailure"
$rollbackFailure = Invoke-OneShotModel $true $false $false
Add-Check "one-shot model: rollback failure stays marked and unhealthy" ($rollbackFailure.Submitted -and $rollbackFailure.Marker -and !$rollbackFailure.Healthy) "$rollbackFailure"

$riskSuccess = Invoke-InitialRiskModel $true $false
Add-Check "initial-risk model: durable state accepts entry" ($riskSuccess.EntryAccepted -and !$riskSuccess.CloseRequested -and !$riskSuccess.PositionRemains -and $riskSuccess.CriticalHealthy) "$riskSuccess"
$riskClosed = Invoke-InitialRiskModel $false $true
Add-Check "initial-risk model: write failure rejects and closes entry" (!$riskClosed.EntryAccepted -and $riskClosed.CloseRequested -and !$riskClosed.PositionRemains -and !$riskClosed.CriticalHealthy) "$riskClosed"
$riskCloseFailed = Invoke-InitialRiskModel $false $false
Add-Check "initial-risk model: failed close arms next-tick flatten" (!$riskCloseFailed.EntryAccepted -and $riskCloseFailed.CloseRequested -and $riskCloseFailed.PositionRemains -and !$riskCloseFailed.CriticalHealthy -and $riskCloseFailed.NextTickFlatten) "$riskCloseFailed"

foreach($contract in @{
   InpUseDedicatedAccountContract = 'true'
   InpRejectFundingChangesAfterRegistration = 'true'
   InpClosePositionsOnRiskLimit = 'true'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "persistent-state profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC persistent-trade-state checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC persistent-trade-state checks"
