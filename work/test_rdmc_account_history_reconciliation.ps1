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

function Test-WatchdogDue([int]$Now, [int]$LastAudit, [int]$Interval) {
   return $Now -le 0 -or $LastAudit -le 0 -or $Now - $LastAudit -ge $Interval
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Account-history reconciliation inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$watchdog = Get-Section $source "void RefreshAccountHistoryWatchdog()" "string InitialBalanceContractKey()"
$runtime = Get-Section $source "bool RuntimeAccountHistoryContractAllows(string &reason)" "class CSessionFilter"
$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$finalOnTradeIndex = $source.LastIndexOf('void OnTrade()', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }
$transaction = if($finalTransactionIndex -ge 0 -and $finalOnTradeIndex -gt $finalTransactionIndex) { $source.Substring($finalTransactionIndex, $finalOnTradeIndex - $finalTransactionIndex) } else { '' }
$onTrade = if($finalOnTradeIndex -ge 0) { $source.Substring($finalOnTradeIndex) } else { '' }

Add-Check "history cache starts fail closed and dirty" ($source.Contains('bool g_accountHistoryStateDirty = true;') -and $source.Contains('bool g_cachedAccountHistoryValid = false;')) "safe startup"
Add-Check "history watchdog has a bounded one-minute interval" ($source.Contains('const int ACCOUNT_HISTORY_WATCHDOG_SECONDS = 60;')) "60 seconds"
Add-Check "history watchdog is skipped in Strategy Tester" ($watchdog.Contains('if(MQLInfoInteger(MQL_TESTER))') -and $watchdog.Contains('return;')) "tester unchanged"
Add-Check "history watchdog uses server time" ($watchdog.Contains('datetime now = TimeCurrent();')) "server time"
Add-Check "history watchdog handles missing baseline" ($watchdog.Contains('g_lastAccountHistoryAuditTime <= 0')) "baseline guard"
Add-Check "history watchdog expires by elapsed interval" ($watchdog.Contains('now - g_lastAccountHistoryAuditTime >= ACCOUNT_HISTORY_WATCHDOG_SECONDS')) "elapsed guard"
Add-Check "history watchdog only invalidates the cache" ($watchdog.Contains('g_accountHistoryStateDirty = true;') -and !$watchdog.Contains('HistorySelect(')) "cheap tick path"
Add-Check "runtime contract directly checks active positions and orders before cache" ($runtime.IndexOf('ForeignOpenPositionCount()', [StringComparison]::Ordinal) -lt $runtime.IndexOf('if(!g_accountHistoryStateDirty)', [StringComparison]::Ordinal) -and $runtime.IndexOf('ResearchActiveOrderCount()', [StringComparison]::Ordinal) -lt $runtime.IndexOf('if(!g_accountHistoryStateDirty)', [StringComparison]::Ordinal)) "live exposure uncached"
Add-Check "clean cached history returns without a full scan" ($runtime.Contains('if(!g_accountHistoryStateDirty)') -and $runtime.Contains('return g_cachedAccountHistoryValid;')) "cache return"
Add-Check "full scan is reached only for dirty history" ($runtime.IndexOf('AccountHistoryContractSnapshot(', [StringComparison]::Ordinal) -gt $runtime.IndexOf('if(!g_accountHistoryStateDirty)', [StringComparison]::Ordinal)) "dirty scan"
Add-Check "successful or failed scan clears dirty state" ($runtime.Contains('g_accountHistoryStateDirty = false;')) "scan completed"
Add-Check "scan records watchdog baseline" ($runtime.Contains('g_lastAccountHistoryAuditTime = TimeCurrent();')) "audit timestamp"

Add-Check "final OnTick invokes history watchdog" ($onTick.Contains('RefreshAccountHistoryWatchdog();')) "watchdog call"
Add-Check "final OnTick no longer dirties history every tick" (!$onTick.Contains('g_accountHistoryStateDirty = true;')) "per-tick rescan removed"
Add-Check "deal-add transaction invalidates history" ($transaction.Contains('TRADE_TRANSACTION_DEAL_ADD')) "deal add"
Add-Check "deal-update transaction invalidates history" ($transaction.Contains('TRADE_TRANSACTION_DEAL_UPDATE')) "deal update"
Add-Check "deal-delete transaction invalidates history" ($transaction.Contains('TRADE_TRANSACTION_DEAL_DELETE')) "deal delete"
Add-Check "transaction invalidation precedes lane processing" ($transaction.IndexOf('g_accountHistoryStateDirty = true;', [StringComparison]::Ordinal) -lt $transaction.IndexOf('g_momentum.OnTradeTransaction(trans);', [StringComparison]::Ordinal)) "invalidation first"
Add-Check "generic OnTrade fallback invalidates history" ($onTrade.Contains('g_accountHistoryStateDirty = true;')) "fallback event"
Add-Check "account registration forces first runtime audit" ($source.Contains('g_accountHistoryStateDirty = true;') -and $source.Contains('return true;')) "post-registration dirty"

foreach($scenario in @(
   @{ Name='missing terminal time'; Now=0; Last=100; Expected=$true },
   @{ Name='missing audit baseline'; Now=100; Last=0; Expected=$true },
   @{ Name='fifty-nine seconds cached'; Now=159; Last=100; Expected=$false },
   @{ Name='sixty seconds due'; Now=160; Last=100; Expected=$true },
   @{ Name='long disconnect due'; Now=1000; Last=100; Expected=$true }
)) {
   $actual = Test-WatchdogDue $scenario.Now $scenario.Last 60
   Add-Check "watchdog model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpUseDedicatedAccountContract = 'true'
   InpRejectFundingChangesAfterRegistration = 'true'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "history profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC account-history reconciliation checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC account-history reconciliation checks"
