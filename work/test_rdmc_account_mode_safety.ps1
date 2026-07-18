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

function Test-AccountMode([string]$Mode) {
   return $Mode -eq 'ACCOUNT_MARGIN_MODE_RETAIL_HEDGING'
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Account-mode audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$modeGate = Get-Section $source "bool AccountPositionModeAllows()" "bool ResearchCapitalContractAllows()"
$onInit = Get-Section $source "int OnInit()" "void OnDeinit(const int reason)"

Add-Check "source version is 1.30" ($source.Contains('#property version   "1.30"')) "version"
Add-Check "description advertises the hedging lock" ($source.Contains('Restart-safe, hedging-locked and permission-gated')) "description"
Add-Check "account gate reads ACCOUNT_MARGIN_MODE" ($modeGate.Contains('AccountInfoInteger(ACCOUNT_MARGIN_MODE)')) "account property"
Add-Check "account gate uses the typed margin-mode enum" ($modeGate.Contains('ENUM_ACCOUNT_MARGIN_MODE mode')) "typed mode"
Add-Check "only retail hedging is accepted" ($modeGate.Contains('mode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING') -and $modeGate.Contains('return true;')) "hedging only"
Add-Check "non-hedging modes fail closed" ($modeGate.Contains('return false;')) "fail closed"
Add-Check "failure log names the accounting requirement" ($modeGate.Contains('requires hedging accounting')) "actionable log"
Add-Check "failure log includes the observed enum" ($modeGate.Contains('EnumToString(mode)')) "observed mode"
Add-Check "account mode gate has no input bypass" ($modeGate -notmatch '\bInp[A-Za-z0-9_]+') "non-bypassable"
Add-Check "account mode gate has one definition and one call" ([regex]::Matches($source, 'AccountPositionModeAllows\(').Count -eq 2) "definition plus call"

$symbolIndex = $onInit.IndexOf('SymbolSafetyLockAllows()', [StringComparison]::Ordinal)
$modeIndex = $onInit.IndexOf('AccountPositionModeAllows()', [StringComparison]::Ordinal)
$capitalIndex = $onInit.IndexOf('ResearchCapitalContractAllows()', [StringComparison]::Ordinal)
$realIndex = $onInit.IndexOf('RealAccountSafetyLockAllows()', [StringComparison]::Ordinal)
$readinessIndex = $onInit.IndexOf('TradeReadinessSafetyGateAllows()', [StringComparison]::Ordinal)
$indicatorIndex = $onInit.IndexOf('indicators.Init()', [StringComparison]::Ordinal)
$executorIndex = $onInit.IndexOf('trade.SetExpertMagicNumber', [StringComparison]::Ordinal)
Add-Check "mode gate follows symbol lock" ($symbolIndex -ge 0 -and $modeIndex -gt $symbolIndex) "symbol=$symbolIndex mode=$modeIndex"
Add-Check "mode gate precedes capital registration" ($modeIndex -ge 0 -and $capitalIndex -gt $modeIndex) "mode=$modeIndex capital=$capitalIndex"
Add-Check "mode gate precedes real-account approval" ($realIndex -gt $modeIndex) "mode=$modeIndex real=$realIndex"
Add-Check "mode gate precedes trade-readiness checks" ($readinessIndex -gt $modeIndex) "mode=$modeIndex readiness=$readinessIndex"
Add-Check "mode gate precedes indicator allocation" ($indicatorIndex -gt $modeIndex) "mode=$modeIndex indicators=$indicatorIndex"
Add-Check "mode gate precedes trade-executor setup" ($executorIndex -gt $modeIndex) "mode=$modeIndex executor=$executorIndex"
Add-Check "mode failure returns INIT_PARAMETERS_INCORRECT" ($onInit.Contains('if(!AccountPositionModeAllows())') -and $onInit.Contains('return INIT_PARAMETERS_INCORRECT;')) "init fail closed"

Add-Check "ticket-based partial close remains present" ($source.Contains('executor.PositionClosePartial(ticket, closeVolume)')) "hedging API dependency"
Add-Check "primary positions are selected by ticket and magic" ($source.Contains('PositionSelectByTicket(ticket)') -and $source.Contains('PositionGetInteger(POSITION_MAGIC) != InpMagicNumber')) "primary ownership"
Add-Check "momentum positions are selected by ticket and magic" ($source.Contains('PositionGetInteger(POSITION_MAGIC) != InpMOMagicNumber')) "momentum ownership"
Add-Check "both executors still configure account margin behavior" ([regex]::Matches($source, 'SetMarginMode\(\)').Count -eq 2) "executors=2"

foreach($scenario in @(
   @{ Name='retail hedging'; Mode='ACCOUNT_MARGIN_MODE_RETAIL_HEDGING'; Expected=$true },
   @{ Name='retail netting'; Mode='ACCOUNT_MARGIN_MODE_RETAIL_NETTING'; Expected=$false },
   @{ Name='exchange'; Mode='ACCOUNT_MARGIN_MODE_EXCHANGE'; Expected=$false },
   @{ Name='unknown mode'; Mode='ACCOUNT_MARGIN_MODE_UNKNOWN'; Expected=$false }
)) {
   $actual = Test-AccountMode $scenario.Mode
   Add-Check "account-mode model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseDedicatedAccountContract = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpAccountWideMaxPositions = '1'
}.GetEnumerator()) {
   Add-Check "account-mode profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC account-mode checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC account-mode checks"
