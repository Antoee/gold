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

function Test-StopModificationModel(
   [ValidateSet('buy','sell','unknown')][string]$Side,
   [double]$CurrentStop,
   [double]$RequestedStop,
   [double]$Tolerance,
   [bool]$TicketSelected,
   [bool]$MagicOwned,
   [bool]$ExpertOwned
) {
   if(!$TicketSelected -or !$MagicOwned -or !$ExpertOwned) { return $false }
   if($CurrentStop -le 0.0 -or $RequestedStop -le 0.0 -or $Tolerance -le 0.0) { return $false }
   if($Side -eq 'buy') { return $RequestedStop -ge $CurrentStop - $Tolerance }
   if($Side -eq 'sell') { return $RequestedStop -le $CurrentStop + $Tolerance }
   return $false
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Stop-modification audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$ownership = Get-Section $source "bool SelectOwnedExpertPosition(" "bool ExecutePositionClose(CTrade &executor,"
$matcher = Get-Section $source "bool TradePriceMatches(" "bool ExecutePositionModify(CTrade &executor,"
$modify = Get-Section $source "bool ExecutePositionModify(CTrade &executor," "bool ExecutePositionClosePartial(CTrade &executor,"

Add-Check "source version is 1.29" ($source.Contains('#property version   "1.29"')) "version"
Add-Check "description advertises ownership-checked execution" ($source.Contains('ownership-checked execution')) "description"
Add-Check "one raw PositionModify send site remains" ([regex]::Matches($source, '\.PositionModify\(').Count -eq 1) "raw sends=1"
Add-Check "all stop changes use the shared wrapper" ([regex]::Matches($source, 'ExecutePositionModify\(').Count -eq 4) "definition plus three callers"
Add-Check "wrapper selects exact owned ticket before request" ($modify.IndexOf('SelectOwnedExpertPosition(executor, ticket, symbol)', [StringComparison]::Ordinal) -ge 0 -and $modify.IndexOf('SelectOwnedExpertPosition(executor, ticket, symbol)', [StringComparison]::Ordinal) -lt $modify.IndexOf('executor.PositionModify(', [StringComparison]::Ordinal)) "preselect"
Add-Check "wrapper reads position type and current stop" (@('POSITION_TYPE','POSITION_SL').Where({ $modify.Contains($_) }).Count -eq 2) "position state"
Add-Check "wrapper requires existing and requested stops" ($modify.Contains('currentSL <= 0.0 || sl <= 0.0')) "nonzero protection"
Add-Check "shared selector requires executor magic ownership" ($ownership.Contains('POSITION_MAGIC') -and $ownership.Contains('executor.RequestMagic()')) "magic"
Add-Check "shared selector requires expert-owned position" ($ownership.Contains('POSITION_REASON_EXPERT')) "expert reason"
Add-Check "wrapper uses symbol-native point and tick size" ($modify.Contains('SymbolInfoDouble(symbol, SYMBOL_POINT)') -and $modify.Contains('SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE)')) "symbol geometry"
Add-Check "wrapper rejects unavailable symbol geometry" ($modify.Contains('if(point <= 0.0 || tickSize <= 0.0)')) "geometry fail closed"
Add-Check "wrapper derives bounded price tolerance" ($modify.Contains('MathMax(MathMax(point, tickSize) * 0.5, 0.00000001)')) "tolerance"
Add-Check "buy stop cannot move lower" ($modify.Contains('positionType == POSITION_TYPE_BUY && sl < currentSL - tolerance')) "buy no-widen"
Add-Check "sell stop cannot move higher" ($modify.Contains('positionType == POSITION_TYPE_SELL && sl > currentSL + tolerance')) "sell no-widen"
Add-Check "unknown position type fails closed" ($modify.Contains('positionType != POSITION_TYPE_BUY && positionType != POSITION_TYPE_SELL')) "type gate"
Add-Check "risk checks occur before broker send" ($modify.IndexOf('currentSL <= 0.0', [StringComparison]::Ordinal) -lt $modify.IndexOf('executor.PositionModify(', [StringComparison]::Ordinal) -and $modify.IndexOf('sl < currentSL - tolerance', [StringComparison]::Ordinal) -lt $modify.IndexOf('executor.PositionModify(', [StringComparison]::Ordinal)) "call order"
Add-Check "broker request uses exact ticket and requested state" ($modify.Contains('executor.PositionModify(ticket, sl, tp)')) "request"
Add-Check "failed local or broker request returns false" ($modify.Contains('if(!executor.PositionModify(ticket, sl, tp))') -and $modify.Contains('return false;')) "send failure"
Add-Check "modify accepts only done or no-changes retcodes" ($modify.Contains('TRADE_RETCODE_DONE') -and $modify.Contains('TRADE_RETCODE_NO_CHANGES')) "retcode"
Add-Check "wrapper reselects owned ticket after request" ([regex]::Matches($modify, 'SelectOwnedExpertPosition\(executor, ticket,').Count -eq 2) "before and after"
Add-Check "resulting stop is verified" ($modify.Contains('TradePriceMatches(symbol, PositionGetDouble(POSITION_SL), sl)')) "SL state"
Add-Check "resulting target is verified" ($modify.Contains('TradePriceMatches(symbol, PositionGetDouble(POSITION_TP), tp)')) "TP state"
Add-Check "price matcher uses selected symbol" ($matcher.Contains('const string symbol') -and $matcher.Contains('SymbolInfoDouble(symbol, SYMBOL_POINT)') -and $matcher.Contains('SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE)')) "symbol matcher"
Add-Check "price matcher rejects unavailable symbol geometry" ($matcher.Contains('StringLen(symbol) <= 0') -and $matcher.Contains('if(point <= 0.0 || tickSize <= 0.0)')) "matcher fail closed"
Add-Check "price matcher supports an intentionally absent target" ($matcher.Contains('if(requested <= 0.0)') -and $matcher.Contains('MathAbs(actual) <= tolerance')) "zero TP"

$base = @{ Side='buy'; CurrentStop=2300.0; RequestedStop=2301.0; Tolerance=0.005; TicketSelected=$true; MagicOwned=$true; ExpertOwned=$true }
$scenarios = @(
   @{ Name='buy tightens'; Expected=$true; Values=@{} },
   @{ Name='buy keeps stop for TP-only change'; Expected=$true; Values=@{RequestedStop=2300.0} },
   @{ Name='buy sub-tick drift allowed'; Expected=$true; Values=@{RequestedStop=2299.996} },
   @{ Name='buy widening rejected'; Expected=$false; Values=@{RequestedStop=2299.99} },
   @{ Name='sell tightens'; Expected=$true; Values=@{Side='sell';CurrentStop=2300.0;RequestedStop=2299.0} },
   @{ Name='sell keeps stop for TP-only change'; Expected=$true; Values=@{Side='sell';CurrentStop=2300.0;RequestedStop=2300.0} },
   @{ Name='sell sub-tick drift allowed'; Expected=$true; Values=@{Side='sell';CurrentStop=2300.0;RequestedStop=2300.004} },
   @{ Name='sell widening rejected'; Expected=$false; Values=@{Side='sell';CurrentStop=2300.0;RequestedStop=2300.01} },
   @{ Name='missing existing stop rejected'; Expected=$false; Values=@{CurrentStop=0.0} },
   @{ Name='stop removal rejected'; Expected=$false; Values=@{RequestedStop=0.0} },
   @{ Name='ticket selection failure rejected'; Expected=$false; Values=@{TicketSelected=$false} },
   @{ Name='magic mismatch rejected'; Expected=$false; Values=@{MagicOwned=$false} },
   @{ Name='non-expert position rejected'; Expected=$false; Values=@{ExpertOwned=$false} },
   @{ Name='unknown position type rejected'; Expected=$false; Values=@{Side='unknown'} }
)
foreach($scenario in $scenarios) {
   $state = @{} + $base
   foreach($key in $scenario.Values.Keys) { $state[$key] = $scenario.Values[$key] }
   $actual = Test-StopModificationModel @state
   Add-Check "stop model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpBlockUnprotectedExposure = 'true'
   InpAccountWideBlockUnprotectedExposure = 'true'
   InpUseAccountWideExposureGuard = 'true'
   InpAccountWideMaxPositions = '1'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "stop profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC stop-modification checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC stop-modification checks"
