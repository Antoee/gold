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

function Test-EntryOrderGate([int]$ActiveOrders) {
   return $ActiveOrders -eq 0
}

function Test-RealtimeOrderGate([int]$ActiveOrders) {
   return $ActiveOrders -gt 0
}

function Test-ResearchOrderOwnership([bool]$SymbolMatches, [bool]$MagicMatches) {
   return $SymbolMatches -and $MagicMatches
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Pending-order audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$researchOrders = Get-Section $source "int ResearchActiveOrderCount()" "int ForeignActiveOrderCount()"
$foreignOrders = Get-Section $source "int ForeignActiveOrderCount()" "bool CancelResearchOrders(const string reason)"
$cancelOrders = Get-Section $source "bool CancelResearchOrders(const string reason)" "bool g_accountHistoryStateDirty"
$deleteOrder = Get-Section $source "bool ExecuteOrderDelete(CTrade &executor," "bool IsResearchPortfolioMagic("
$realtime = Get-Section $source "bool RealtimeProtectionLimitHit(string &reason)" "double NormalizeLots(const double lots)"
$exposure = Get-Section $source "bool ExposureAllows(const ENUM_TRADE_BIAS bias," "class CTrendFilter"
$runtime = Get-Section $source "bool RuntimeAccountHistoryContractAllows(string &reason)" "class CSessionFilter"
$capital = Get-Section $source "bool ResearchCapitalContractAllows()" "bool RealAccountSafetyLockAllows()"

Add-Check "research order scan uses current active-order list" ($researchOrders.Contains('OrdersTotal()') -and $researchOrders.Contains('OrderGetTicket(i)')) "active list"
Add-Check "research order ownership requires symbol and magic" ($researchOrders.Contains('OrderGetString(ORDER_SYMBOL) == _Symbol') -and $researchOrders.Contains('IsResearchPortfolioMagic(OrderGetInteger(ORDER_MAGIC))')) "symbol plus magic"
Add-Check "foreign order scan identifies symbol or magic mismatch" ($foreignOrders.Contains('OrderGetString(ORDER_SYMBOL) != _Symbol') -and $foreignOrders.Contains('!IsResearchPortfolioMagic(OrderGetInteger(ORDER_MAGIC))')) "foreign ownership"
Add-Check "cancel loop scans active orders backwards" ($cancelOrders.Contains('for(int i = OrdersTotal() - 1; i >= 0; --i)') -and $cancelOrders.Contains('OrderGetTicket(i)')) "stable deletion loop"
Add-Check "cancel loop never targets foreign orders" ($cancelOrders.Contains('OrderGetString(ORDER_SYMBOL) != _Symbol ||') -and $cancelOrders.Contains('!IsResearchPortfolioMagic(OrderGetInteger(ORDER_MAGIC))') -and $cancelOrders.Contains('continue;')) "ownership filter"
Add-Check "cancel loop uses verified delete wrapper" ($cancelOrders.Contains('ExecuteOrderDelete(trade, ticket)')) "verified delete"
Add-Check "cancel completion rescans research orders" ($cancelOrders.Contains('ResearchActiveOrderCount() == 0')) "post-state rescan"
Add-Check "cancel failure includes broker evidence" ($cancelOrders.Contains('TradeResultEvidence(trade)')) "retcode evidence"
Add-Check "delete wrapper requires DONE" ($deleteOrder.Contains('TRADE_RETCODE_DONE')) "done required"
Add-Check "delete wrapper verifies ticket is absent" ($deleteOrder.Contains('!OrderSelect(ticket)')) "order absent"
Add-Check "no raw lane order deletion exists" ([regex]::Matches($source, '\b(?:trade|m_trade)\.OrderDelete\s*\(').Count -eq 0) "raw_delete=0"
Add-Check "exactly one OrderDelete exists in wrapper" ([regex]::Matches($source, '\.OrderDelete\s*\(').Count -eq 1) "delete_calls=1"

$realtimeOrderIndex = $realtime.IndexOf('OrdersTotal() > 0', [StringComparison]::Ordinal)
$realtimeDrawdownIndex = $realtime.IndexOf('CurrentEquityDrawdownPercent()', [StringComparison]::Ordinal)
Add-Check "realtime order gate precedes drawdown work" ($realtimeOrderIndex -ge 0 -and $realtimeDrawdownIndex -gt $realtimeOrderIndex) "order=$realtimeOrderIndex drawdown=$realtimeDrawdownIndex"
Add-Check "realtime order gate is fail closed" ($realtime.Contains('reason = "active account order";') -and $realtime.Contains('return true;')) "urgent condition"
$exposureOrderIndex = $exposure.IndexOf('OrdersTotal() > 0', [StringComparison]::Ordinal)
$exposureRiskIndex = $exposure.IndexOf('AccountWideOpenRiskPercent(', [StringComparison]::Ordinal)
Add-Check "entry order gate precedes account risk calculation" ($exposureOrderIndex -ge 0 -and $exposureRiskIndex -gt $exposureOrderIndex) "order=$exposureOrderIndex risk=$exposureRiskIndex"
Add-Check "entry order gate blocks duplicate exposure" ($exposure.Contains('reason = "account-wide active order";') -and $exposure.Contains('return false;')) "duplicate blocked"

Add-Check "runtime contract rejects foreign active orders" ($runtime.Contains('ForeignActiveOrderCount() > 0') -and $runtime.Contains('dedicated-account active-exposure contract')) "foreign blocked"
Add-Check "runtime contract rejects unresolved research orders" ($runtime.Contains('ResearchActiveOrderCount() > 0') -and $runtime.Contains('reason = "active research order";')) "research blocked"
Add-Check "initial account contract rejects foreign orders" ($capital.Contains('ForeignActiveOrderCount() > 0') -and $capital.Contains('foreign trading activity')) "foreign registration blocked"
Add-Check "initial account contract rejects research orders" ($capital.Contains('ResearchActiveOrderCount() > 0') -and $capital.Contains('unresolved research order')) "research registration blocked"
Add-Check "first registration requires zero active orders" ($capital.Contains('tradeDealCount > 0 || PositionsTotal() > 0 || OrdersTotal() > 0')) "unused account"

$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }
Add-Check "six flatten paths cancel research orders" ([regex]::Matches($onTick, 'CancelResearchOrders\(').Count -eq 6) "cancel_calls=6"
foreach($path in @(
   @{ Name='persistence failure'; Cancel='CancelResearchOrders(persistenceReason);'; Close='positionManager.CloseAll(persistenceReason);' },
   @{ Name='realtime risk'; Cancel='CancelResearchOrders(realtimeRiskReason);'; Close='positionManager.CloseAll(realtimeRiskReason);' },
   @{ Name='period risk'; Cancel='CancelResearchOrders(riskExitReason);'; Close='positionManager.CloseAll(riskExitReason);' },
   @{ Name='weekend'; Cancel='CancelResearchOrders("weekend close");'; Close='positionManager.CloseAll("weekend close");' },
   @{ Name='session'; Cancel='CancelResearchOrders("session end close");'; Close='positionManager.CloseAll("session end close");' },
   @{ Name='manual news'; Cancel='CancelResearchOrders("manual news filter");'; Close='positionManager.CloseAll("manual news filter");' }
)) {
   $cancelIndex = $onTick.IndexOf($path.Cancel, [StringComparison]::Ordinal)
   $closeIndex = $onTick.IndexOf($path.Close, [StringComparison]::Ordinal)
   Add-Check "$($path.Name) cancels orders before positions" ($cancelIndex -ge 0 -and $closeIndex -gt $cancelIndex) "cancel=$cancelIndex close=$closeIndex"
}

foreach($scenario in @(
   @{ Name='entry with no active orders'; Actual=(Test-EntryOrderGate 0); Expected=$true },
   @{ Name='entry with placed order'; Actual=(Test-EntryOrderGate 1); Expected=$false },
   @{ Name='realtime with no active orders'; Actual=(Test-RealtimeOrderGate 0); Expected=$false },
   @{ Name='realtime with placed order'; Actual=(Test-RealtimeOrderGate 1); Expected=$true },
   @{ Name='owned research order'; Actual=(Test-ResearchOrderOwnership $true $true); Expected=$true },
   @{ Name='foreign symbol order'; Actual=(Test-ResearchOrderOwnership $false $true); Expected=$false },
   @{ Name='foreign magic order'; Actual=(Test-ResearchOrderOwnership $true $false); Expected=$false }
)) {
   Add-Check "state model: $($scenario.Name)" ($scenario.Actual -eq $scenario.Expected) "actual=$($scenario.Actual)"
}

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseDedicatedAccountContract = 'true'
   InpUseAccountWideExposureGuard = 'true'
   InpAccountWideMaxPositions = '1'
   InpClosePositionsOnRiskLimit = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "pending-order profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC pending-order checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC pending-order checks"
