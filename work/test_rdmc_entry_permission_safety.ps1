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

function Test-EntryPermissionState(
   [bool]$Tester,
   [bool]$Connected,
   [bool]$TerminalAllowed,
   [bool]$MqlAllowed,
   [bool]$AccountAllowed,
   [bool]$ExpertAllowed,
   [int]$OrderMode,
   [string]$TradeMode,
   [string]$Bias
) {
   if($Bias -notin @('BUY','SELL')) { return $false }
   if(!$Tester -and (!$Connected -or !$TerminalAllowed -or !$MqlAllowed -or !$AccountAllowed -or !$ExpertAllowed)) {
      return $false
   }
   if(($OrderMode -band 1) -eq 0 -or ($OrderMode -band 16) -eq 0) { return $false }
   if($TradeMode -eq 'FULL') { return $true }
   if($Bias -eq 'BUY' -and $TradeMode -eq 'LONGONLY') { return $true }
   if($Bias -eq 'SELL' -and $TradeMode -eq 'SHORTONLY') { return $true }
   return $false
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Entry-permission audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$permissions = Get-Section $source "bool EntryTradePermissionsAllow(" "string InitialRiskKey("
$exposure = Get-Section $source "bool ExposureAllows(const ENUM_TRADE_BIAS bias," "class CTrendFilter"
$closeWrapper = Get-Section $source "bool ExecutePositionClose(CTrade &executor," "bool TradePriceMatches("
$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }

Add-Check "source version is 1.23" ($source.Contains('#property version   "1.23"')) "version"
Add-Check "description advertises permission gate" ($source.Contains('permission-gated XAUUSD research portfolio')) "description"
Add-Check "invalid entry direction fails closed" ($permissions.Contains('bias != BIAS_BUY && bias != BIAS_SELL') -and $permissions.Contains('entry permission invalid direction')) "direction gate"
Add-Check "live-only permission block is explicit" ($permissions.Contains('if(!MQLInfoInteger(MQL_TESTER))')) "tester isolation"
Add-Check "terminal connection is required live" ($permissions.Contains('TerminalInfoInteger(TERMINAL_CONNECTED)') -and $permissions.Contains('terminal disconnected')) "connection"
Add-Check "terminal automated trading is required live" ($permissions.Contains('TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)') -and $permissions.Contains('terminal automated trading disabled')) "terminal permission"
Add-Check "EA automated trading is required live" ($permissions.Contains('MQLInfoInteger(MQL_TRADE_ALLOWED)') -and $permissions.Contains('EA automated trading disabled')) "EA permission"
Add-Check "account trading is required live" ($permissions.Contains('AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)') -and $permissions.Contains('account trading disabled')) "account permission"
Add-Check "account expert trading is required live" ($permissions.Contains('AccountInfoInteger(ACCOUNT_TRADE_EXPERT)') -and $permissions.Contains('account expert trading disabled')) "expert permission"
Add-Check "market-order flag is mandatory" ($permissions.Contains('(orderMode & SYMBOL_ORDER_MARKET) == 0') -and $permissions.Contains('market orders disabled')) "market orders"
Add-Check "protective-stop flag is mandatory" ($permissions.Contains('(orderMode & SYMBOL_ORDER_SL) == 0') -and $permissions.Contains('protective stops disabled')) "stop loss"
Add-Check "full symbol mode permits either direction" ($permissions.Contains('tradeMode == SYMBOL_TRADE_MODE_FULL')) "full mode"
Add-Check "long-only permits buys" ($permissions.Contains('bias == BIAS_BUY && tradeMode == SYMBOL_TRADE_MODE_LONGONLY')) "long-only"
Add-Check "short-only permits sells" ($permissions.Contains('bias == BIAS_SELL && tradeMode == SYMBOL_TRADE_MODE_SHORTONLY')) "short-only"
Add-Check "disabled symbol has precise rejection" ($permissions.Contains('SYMBOL_TRADE_MODE_DISABLED') -and $permissions.Contains('symbol disabled')) "disabled"
Add-Check "close-only symbol has precise rejection" ($permissions.Contains('SYMBOL_TRADE_MODE_CLOSEONLY') -and $permissions.Contains('symbol close-only')) "close-only"
Add-Check "wrong long direction has precise rejection" ($permissions.Contains('long direction disabled')) "long rejection"
Add-Check "wrong short direction has precise rejection" ($permissions.Contains('short direction disabled')) "short rejection"

$permissionIndex = $exposure.IndexOf('EntryTradePermissionsAllow(bias, reason)', [StringComparison]::Ordinal)
$accountGuardIndex = $exposure.IndexOf('InpUseAccountWideExposureGuard', [StringComparison]::Ordinal)
Add-Check "permission gate starts shared exposure approval" ($permissionIndex -ge 0 -and $accountGuardIndex -gt $permissionIndex) "permission=$permissionIndex exposure=$accountGuardIndex"
Add-Check "permission helper has one definition and one call" ([regex]::Matches($source, 'EntryTradePermissionsAllow\(').Count -eq 2) "definition plus shared call"
Add-Check "all four entry lanes still use shared exposure approval" ([regex]::Matches($source, 'riskManager\.ExposureAllows\(').Count -eq 4) "entry calls=4"
Add-Check "close wrapper does not use entry permission gate" (!$closeWrapper.Contains('EntryTradePermissionsAllow')) "protective close preserved"
Add-Check "final OnTick does not globally return on entry permission" (!$onTick.Contains('EntryTradePermissionsAllow')) "management preserved"
$manageIndex = $onTick.IndexOf('positionManager.Manage(signal.bias);', [StringComparison]::Ordinal)
$environmentIndex = $onTick.IndexOf('TradeEnvironmentAllows(environmentReason)', [StringComparison]::Ordinal)
Add-Check "primary management precedes outer entry environment gate" ($manageIndex -ge 0 -and $environmentIndex -gt $manageIndex) "manage=$manageIndex environment=$environmentIndex"
$realtimeIndex = $onTick.IndexOf('RealtimeProtectionLimitHit(realtimeRiskReason)', [StringComparison]::Ordinal)
$newBarIndex = $onTick.IndexOf('bool newBar = IsNewBar();', [StringComparison]::Ordinal)
Add-Check "realtime protection remains before new-bar entry work" ($realtimeIndex -ge 0 -and $newBarIndex -gt $realtimeIndex) "realtime=$realtimeIndex newbar=$newBarIndex"

$base = @{ Tester=$false; Connected=$true; TerminalAllowed=$true; MqlAllowed=$true; AccountAllowed=$true; ExpertAllowed=$true; OrderMode=17; TradeMode='FULL'; Bias='BUY' }
$scenarios = @(
   @{ Name='live full buy'; Expected=$true; Values=@{} },
   @{ Name='tester ignores live permission switches'; Expected=$true; Values=@{Tester=$true;Connected=$false;TerminalAllowed=$false;MqlAllowed=$false;AccountAllowed=$false;ExpertAllowed=$false} },
   @{ Name='terminal disconnected'; Expected=$false; Values=@{Connected=$false} },
   @{ Name='terminal automation disabled'; Expected=$false; Values=@{TerminalAllowed=$false} },
   @{ Name='EA automation disabled'; Expected=$false; Values=@{MqlAllowed=$false} },
   @{ Name='account trading disabled'; Expected=$false; Values=@{AccountAllowed=$false} },
   @{ Name='account expert trading disabled'; Expected=$false; Values=@{ExpertAllowed=$false} },
   @{ Name='market orders unsupported'; Expected=$false; Values=@{OrderMode=16} },
   @{ Name='protective stops unsupported'; Expected=$false; Values=@{OrderMode=1} },
   @{ Name='long-only buy'; Expected=$true; Values=@{TradeMode='LONGONLY';Bias='BUY'} },
   @{ Name='long-only sell'; Expected=$false; Values=@{TradeMode='LONGONLY';Bias='SELL'} },
   @{ Name='short-only sell'; Expected=$true; Values=@{TradeMode='SHORTONLY';Bias='SELL'} },
   @{ Name='short-only buy'; Expected=$false; Values=@{TradeMode='SHORTONLY';Bias='BUY'} },
   @{ Name='close-only symbol'; Expected=$false; Values=@{TradeMode='CLOSEONLY'} },
   @{ Name='disabled symbol'; Expected=$false; Values=@{TradeMode='DISABLED'} },
   @{ Name='invalid direction'; Expected=$false; Values=@{Bias='NONE'} }
)
foreach($scenario in $scenarios) {
   $state = @{} + $base
   foreach($key in $scenario.Values.Keys) { $state[$key] = $scenario.Values[$key] }
   $actual = Test-EntryPermissionState @state
   Add-Check "permission model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseDedicatedAccountContract = 'true'
   InpUseAccountWideExposureGuard = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "permission profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC entry-permission checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC entry-permission checks"
