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

function ConvertTo-Base36([System.Numerics.BigInteger]$Value) {
   $digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   if($Value -eq 0) { return '0' }
   $encoded = ''
   while($Value -gt 0) {
      $digit = [int]($Value % 36)
      $encoded = $digits[$digit] + $encoded
      $Value = [System.Numerics.BigInteger]::Divide($Value, 36)
   }
   return $encoded
}

function New-StateKey(
   [string]$Prefix,
   [System.Numerics.BigInteger]$Account,
   [System.Numerics.BigInteger]$Magic,
   [System.Numerics.BigInteger]$Identifier
) {
   return '{0}_{1}_{2}_{3}' -f $Prefix,(ConvertTo-Base36 $Account),(ConvertTo-Base36 $Magic),(ConvertTo-Base36 $Identifier)
}

function Test-RetirementModel([bool]$IdentifierValid, [bool]$PositionScanReadable, [bool]$MatchingPositionOpen) {
   if(!$IdentifierValid -or !$PositionScanReadable -or $MatchingPositionOpen) { return $false }
   return $true
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Persistent-position identity audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$namespace = Get-Section $source "string UnsignedBase36(" "class CValidatedTrade"
$keys = Get-Section $source "string InitialRiskKey(" "bool StoreInitialRisk("
$retirePrimaryIndex = $source.LastIndexOf("bool RetirePrimaryPersistentPositionState(", [StringComparison]::Ordinal)
$retireMomentumIndex = $source.LastIndexOf("bool RetireMomentumPersistentPositionState(", [StringComparison]::Ordinal)
$storeRiskIndex = $source.IndexOf("bool StoreInitialRisk(", $retireMomentumIndex, [StringComparison]::Ordinal)
$retirePrimary = if($retirePrimaryIndex -ge 0 -and $retireMomentumIndex -gt $retirePrimaryIndex) { $source.Substring($retirePrimaryIndex, $retireMomentumIndex - $retirePrimaryIndex) } else { '' }
$retireMomentum = if($retireMomentumIndex -ge 0 -and $storeRiskIndex -gt $retireMomentumIndex) { $source.Substring($retireMomentumIndex, $storeRiskIndex - $retireMomentumIndex) } else { '' }
$positionState = Get-Section $source "   bool AlreadyPartiallyClosed(" "   double ProfitR("
$partialWrapper = Get-Section $source "bool ExecutePositionClosePartial(CTrade &executor," "bool ExecuteOrderDelete("
$closeMatch = [regex]::Match($source, 'bool ExecutePositionClose\(CTrade &executor, const ulong ticket\)\s*\{')
$closeEnd = if($closeMatch.Success) { $source.IndexOf('bool TradePriceMatches(', $closeMatch.Index, [StringComparison]::Ordinal) } else { -1 }
$closeWrapper = if($closeMatch.Success -and $closeEnd -gt $closeMatch.Index) { $source.Substring($closeMatch.Index, $closeEnd - $closeMatch.Index) } else { '' }
$momentumTransaction = Get-Section $source "   void OnTradeTransaction(const MqlTradeTransaction &transaction)" "CMomentumLane g_momentum;"
$finalTransactionIndex = $source.LastIndexOf("void OnTradeTransaction(", [StringComparison]::Ordinal)
$finalOnTradeIndex = $source.IndexOf("void OnTrade()", $finalTransactionIndex, [StringComparison]::Ordinal)
$finalTransaction = if($finalTransactionIndex -ge 0 -and $finalOnTradeIndex -gt $finalTransactionIndex) { $source.Substring($finalTransactionIndex, $finalOnTradeIndex - $finalTransactionIndex) } else { '' }

Add-Check "source version is 1.23" ($source.Contains('#property version   "1.23"')) "version"
Add-Check "description advertises account-scoped position state" ($source.Contains('verified account-scoped position state')) "description"
Add-Check "base36 encoder uses a fixed uppercase alphabet" ($namespace.Contains('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')) "alphabet"
Add-Check "base36 encoder handles zero" ($namespace.Contains('if(value == 0)') -and $namespace.Contains('return "0";')) "zero"
Add-Check "base36 encoder uses modulo and division" ($namespace.Contains('value % 36') -and $namespace.Contains('value /= 36')) "compact encoding"
Add-Check "persistent identity selects exact ticket" ($namespace.Contains('PositionSelectByTicket(ticketOrIdentifier)')) "ticket selection"
Add-Check "persistent identity prefers immutable identifier" ($namespace.Contains('PositionGetInteger(POSITION_IDENTIFIER)') -and $namespace.Contains('return (ulong)identifier;')) "position identifier"
Add-Check "persistent identity falls back deterministically" ($namespace.Contains('return ticketOrIdentifier;')) "fallback"
Add-Check "state key includes account login" ($namespace.Contains('AccountInfoInteger(ACCOUNT_LOGIN)')) "account scope"
Add-Check "state key includes executor magic" ($namespace.Contains('UnsignedBase36((ulong)magic)')) "magic scope"
Add-Check "state key includes persistent position identity" ($namespace.Contains('UnsignedBase36(PersistentPositionIdentity(ticketOrIdentifier))')) "position scope"
Add-Check "all position key families use shared namespace" ([regex]::Matches($source, 'PositionScopedStateKey\(').Count -eq 9) "definition plus eight families"

foreach($prefix in @('PF','IR','MF','MA','PC','BH','TP','MR')) {
   Add-Check "scoped key prefix: $prefix" ($source.Contains("PositionScopedStateKey(`"$prefix`",")) $prefix
}

foreach($obsolete in @('PXEA_INITIAL_RISK_','PXEA_MFE_R_','PXEA_MAE_R_','PXEA_PARTIAL_','PXEA_BASKET_HARVEST_','PXEA_POST_PARTIAL_TP_','RDMC_MO_RISK_')) {
   Add-Check "obsolete ticket-only key absent: $obsolete" (!$source.Contains($obsolete)) "absent"
}

$max64 = [System.Numerics.BigInteger]::Parse('18446744073709551615')
$maxKey = New-StateKey 'LONGPREFIX' $max64 $max64 $max64
Add-Check "maximum modeled key stays below MT5 limit" ($maxKey.Length -le 63) "length=$($maxKey.Length) key=$maxKey"
$baseKey = New-StateKey 'IR' 10001 26070401 987654321
Add-Check "same identity is deterministic" ($baseKey -ceq (New-StateKey 'IR' 10001 26070401 987654321)) $baseKey
Add-Check "account switch changes namespace" ($baseKey -cne (New-StateKey 'IR' 10002 26070401 987654321)) "account isolated"
Add-Check "magic switch changes namespace" ($baseKey -cne (New-StateKey 'IR' 10001 26071831 987654321)) "magic isolated"
Add-Check "position switch changes namespace" ($baseKey -cne (New-StateKey 'IR' 10001 26070401 987654322)) "position isolated"

Add-Check "partial marker uses scoped key" ($positionState.Contains('GlobalVariableCheck(PartialCloseKey(ticket))') -and $positionState.Contains('SetCriticalPersistentState(PartialCloseKey(ticket), TimeCurrent())') -and $positionState.Contains('DeleteCriticalPersistentState(PartialCloseKey(ticket))')) "partial state"
Add-Check "basket marker uses scoped key" ($positionState.Contains('BasketHarvestKey(ticket)')) "basket state"
Add-Check "runner target marker uses scoped key" ($positionState.Contains('PostPartialRunnerTPKey(ticket)')) "target state"
Add-Check "momentum initial risk uses scoped key" ($source.Contains('SetCriticalPersistentState(MomentumRiskKey(filledTicket), filledRiskDistance)') -and $source.Contains('GlobalVariableCheck(MomentumRiskKey(ticket))')) "momentum state"

Add-Check "open-identifier scan validates symbol" ($keys.Contains('PositionGetString(POSITION_SYMBOL) == _Symbol')) "symbol ownership"
Add-Check "open-identifier scan validates magic" ($keys.Contains('PositionGetInteger(POSITION_MAGIC) == magic')) "magic ownership"
Add-Check "open-identifier scan validates expert reason" ($keys.Contains('PositionGetInteger(POSITION_REASON) == POSITION_REASON_EXPERT')) "expert ownership"
Add-Check "open-identifier scan matches immutable identifier" ($keys.Contains('PositionGetInteger(POSITION_IDENTIFIER) == (long)positionIdentifier')) "identifier ownership"
Add-Check "unreadable position scan preserves state" ($keys.Contains('if(ticket == 0)') -and $keys.Contains('return true;')) "fail closed"

foreach($keyFunction in @('InitialRiskKey','TradeMFEKey','TradeMAEKey','PartialCloseKey','BasketHarvestKey','PostPartialRunnerTPKey')) {
   Add-Check "primary retirement deletes $keyFunction" ($retirePrimary.Contains("DeleteCriticalPersistentState($keyFunction(positionIdentifier))")) $keyFunction
}
Add-Check "primary retirement deletes forced-close state" ($retirePrimary.Contains('PostFillForcedCloseKey(positionIdentifier, InpMagicNumber)')) "primary forced close"
Add-Check "momentum retirement deletes risk state" ($retireMomentum.Contains('MomentumRiskKey(positionIdentifier)')) "momentum risk"
Add-Check "momentum retirement deletes forced-close state" ($retireMomentum.Contains('PostFillForcedCloseKey(positionIdentifier, InpMOMagicNumber)')) "momentum forced close"

Add-Check "full-close wrapper captures identifier before send" ($closeWrapper.IndexOf('PersistentPositionIdentity(ticket)', [StringComparison]::Ordinal) -lt $closeWrapper.IndexOf('executor.PositionClose(ticket)', [StringComparison]::Ordinal)) "pre-close identity"
Add-Check "full-close wrapper retires primary only after disappearance" ($closeWrapper.IndexOf('if(closed)', [StringComparison]::Ordinal) -lt $closeWrapper.IndexOf('RetirePrimaryPersistentPositionState(positionIdentifier)', [StringComparison]::Ordinal)) "primary cleanup"
Add-Check "full-close wrapper retires momentum only after disappearance" ($closeWrapper.IndexOf('if(closed)', [StringComparison]::Ordinal) -lt $closeWrapper.IndexOf('RetireMomentumPersistentPositionState(positionIdentifier)', [StringComparison]::Ordinal)) "momentum cleanup"
Add-Check "partial-close wrapper never retires position state" (!$partialWrapper.Contains('RetirePrimaryPersistentPositionState') -and !$partialWrapper.Contains('RetireMomentumPersistentPositionState')) "partial preservation"

Add-Check "momentum exit recognizes all closing deal types" (@('DEAL_ENTRY_OUT','DEAL_ENTRY_OUT_BY','DEAL_ENTRY_INOUT').Where({ $momentumTransaction.Contains($_) }).Count -eq 3) "exit types"
Add-Check "momentum transaction preserves partial-exit state" ($momentumTransaction.Contains('!ResearchPositionIdentifierOpen((ulong)positionId, InpMOMagicNumber)') -and $momentumTransaction.Contains('RetireMomentumPersistentPositionState((ulong)positionId)')) "open check before retire"
Add-Check "primary exit recognizes all closing deal types" (@('DEAL_ENTRY_OUT','DEAL_ENTRY_OUT_BY','DEAL_ENTRY_INOUT').Where({ $finalTransaction.Contains($_) }).Count -eq 3) "exit types"
Add-Check "primary transaction preserves partial-exit state" ($finalTransaction.Contains('!ResearchPositionIdentifierOpen((ulong)positionId, InpMagicNumber)') -and $finalTransaction.Contains('RetirePrimaryPersistentPositionState((ulong)positionId)')) "open check before retire"

foreach($scenario in @(
   @{ Name='partial exit keeps state'; Valid=$true; Readable=$true; Open=$true; Expected=$false },
   @{ Name='full exit retires state'; Valid=$true; Readable=$true; Open=$false; Expected=$true },
   @{ Name='invalid identifier keeps state'; Valid=$false; Readable=$true; Open=$false; Expected=$false },
   @{ Name='unreadable scan keeps state'; Valid=$true; Readable=$false; Open=$false; Expected=$false }
)) {
   $actual = Test-RetirementModel $scenario.Valid $scenario.Readable $scenario.Open
   Add-Check "retirement model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpUseDedicatedAccountContract = 'true'
   InpAccountWideMaxPositions = '1'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "position-state profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC persistent-position identity checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC persistent-position identity checks"
