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

function Test-EntryResult([bool]$Submitted, [string]$Retcode, [uint64]$Deal) {
   return $Submitted -and $Retcode -in @('DONE', 'DONE_PARTIAL') -and $Deal -gt 0
}

function Test-CloseResult([bool]$Submitted, [string]$Retcode, [bool]$PositionRemains) {
   return $Submitted -and $Retcode -in @('DONE', 'DONE_PARTIAL', 'POSITION_CLOSED') -and !$PositionRemains
}

function Test-ModifyResult([bool]$Submitted, [string]$Retcode, [bool]$PositionExists, [bool]$StateMatches) {
   return $Submitted -and $Retcode -in @('DONE', 'NO_CHANGES') -and $PositionExists -and $StateMatches
}

function Test-PartialResult([bool]$Submitted, [string]$Retcode, [bool]$PositionExists, [double]$Before, [double]$After) {
   return $Submitted -and $Retcode -in @('DONE', 'DONE_PARTIAL') -and (!$PositionExists -or $After -lt $Before)
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Trade-result audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$entry = Get-Section $source "bool ExecuteMarketEntry(CTrade &executor," "bool ExecutePositionClose(CTrade &executor,"
$close = Get-Section $source "bool ExecutePositionClose(CTrade &executor," "bool TradePriceMatches("
$modify = Get-Section $source "bool ExecutePositionModify(CTrade &executor," "bool ExecutePositionClosePartial(CTrade &executor,"
$partial = Get-Section $source "bool ExecutePositionClosePartial(CTrade &executor," "bool IsResearchPortfolioMagic("

Add-Check "entry wrapper checks request submission" ($entry.Contains('if(!submitted)')) "submitted gate"
Add-Check "entry wrapper accepts only completed market execution" ($entry.Contains('TRADE_RETCODE_DONE') -and $entry.Contains('TRADE_RETCODE_DONE_PARTIAL') -and !$entry.Contains('TRADE_RETCODE_PLACED')) "done or partial"
Add-Check "entry wrapper requires a deal ticket" ($entry.Contains('return executor.ResultDeal() > 0;')) "deal required"
Add-Check "close wrapper checks broker retcode" ($close.Contains('TRADE_RETCODE_DONE') -and $close.Contains('TRADE_RETCODE_DONE_PARTIAL') -and $close.Contains('TRADE_RETCODE_POSITION_CLOSED')) "close retcodes"
Add-Check "close wrapper verifies exposure is gone" ($close.Contains('return !PositionSelectByTicket(ticket);')) "position absent"
Add-Check "modify wrapper accepts done or exact no-change" ($modify.Contains('TRADE_RETCODE_DONE') -and $modify.Contains('TRADE_RETCODE_NO_CHANGES')) "modify retcodes"
Add-Check "modify wrapper verifies resulting SL and TP" ($modify.Contains('PositionGetDouble(POSITION_SL)') -and $modify.Contains('PositionGetDouble(POSITION_TP)') -and $modify.Contains('TradePriceMatches')) "state verified"
Add-Check "partial wrapper checks completed retcode" ($partial.Contains('TRADE_RETCODE_DONE') -and $partial.Contains('TRADE_RETCODE_DONE_PARTIAL')) "partial retcodes"
Add-Check "partial wrapper verifies volume reduction" ($partial.Contains('PositionGetDouble(POSITION_VOLUME) < previousVolume - tolerance')) "volume reduced"

$rawTradeCalls = [regex]::Matches($source, '\b(?:trade|m_trade)\.(?:Buy|Sell|PositionClose|PositionClosePartial|PositionModify)\s*\(').Count
Add-Check "no lane bypasses result wrappers" ($rawTradeCalls -eq 0) "raw_calls=$rawTradeCalls"
Add-Check "Buy and Sell exist only in entry wrapper" ([regex]::Matches($source, '\.Buy\s*\(').Count -eq 1 -and [regex]::Matches($source, '\.Sell\s*\(').Count -eq 1) "one each"
Add-Check "full close exists only in close wrapper" ([regex]::Matches($source, '\.PositionClose\s*\(').Count -eq 1) "one call"
Add-Check "partial close exists only in partial wrapper" ([regex]::Matches($source, '\.PositionClosePartial\s*\(').Count -eq 1) "one call"
Add-Check "position modify exists only in modify wrapper" ([regex]::Matches($source, '\.PositionModify\s*\(').Count -eq 1) "one call"
Add-Check "all four entries use the entry wrapper" ([regex]::Matches($source, 'ExecuteMarketEntry\(').Count -eq 5) "definition plus four calls"
Add-Check "successful entry logs use deal tickets" ([regex]::Matches($source, 'logger\.Write\("entry", trade\.ResultDeal\(\)').Count -eq 3 -and $source.Contains('logger.Write("momentum_entry", m_trade.ResultDeal()')) "four deal logs"
Add-Check "successful entry logs use broker-confirmed fills" ([regex]::Matches($source, 'ResultVolume\(\)').Count -ge 8 -and [regex]::Matches($source, 'ResultPrice\(\)').Count -ge 8) "volume and price fallbacks"
Add-Check "trade result evidence includes retcode deal and order" ($source.Contains('executor.ResultRetcodeDescription()') -and $source.Contains('executor.ResultDeal()') -and $source.Contains('executor.ResultOrder()')) "complete evidence"
Add-Check "partial markers require verified completion" ($source.Contains('if(partiallyClosed)') -and $source.Contains('if(PartialCloseAndLog(ticket,')) "markers gated"
Add-Check "both executors force synchronous mode" ([regex]::Matches($source, 'SetAsyncMode\(false\)').Count -eq 2) "sync_count=2"
Add-Check "both executors select symbol filling" ([regex]::Matches($source, 'SetTypeFillingBySymbol\(_Symbol\)').Count -eq 2) "filling_count=2"
Add-Check "both executors set account margin mode" ([regex]::Matches($source, 'SetMarginMode\(\)').Count -eq 2) "margin_count=2"

$entryScenarios = @(
   @{ Name='done with deal'; Expected=$true; Submitted=$true; Retcode='DONE'; Deal=11 },
   @{ Name='partial with deal'; Expected=$true; Submitted=$true; Retcode='DONE_PARTIAL'; Deal=12 },
   @{ Name='done without deal'; Expected=$false; Submitted=$true; Retcode='DONE'; Deal=0 },
   @{ Name='merely placed'; Expected=$false; Submitted=$true; Retcode='PLACED'; Deal=0 },
   @{ Name='rejected'; Expected=$false; Submitted=$true; Retcode='REJECT'; Deal=0 },
   @{ Name='local submission failure'; Expected=$false; Submitted=$false; Retcode='DONE'; Deal=13 }
)
foreach($scenario in $entryScenarios) {
   $actual = Test-EntryResult $scenario.Submitted $scenario.Retcode $scenario.Deal
   Add-Check "entry model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

$closeScenarios = @(
   @{ Name='done and absent'; Expected=$true; Submitted=$true; Retcode='DONE'; Remains=$false },
   @{ Name='already closed and absent'; Expected=$true; Submitted=$true; Retcode='POSITION_CLOSED'; Remains=$false },
   @{ Name='partial still exposed'; Expected=$false; Submitted=$true; Retcode='DONE_PARTIAL'; Remains=$true },
   @{ Name='done but still exposed'; Expected=$false; Submitted=$true; Retcode='DONE'; Remains=$true },
   @{ Name='rejected'; Expected=$false; Submitted=$true; Retcode='REJECT'; Remains=$true }
)
foreach($scenario in $closeScenarios) {
   $actual = Test-CloseResult $scenario.Submitted $scenario.Retcode $scenario.Remains
   Add-Check "close model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

$modifyScenarios = @(
   @{ Name='done and matched'; Expected=$true; Submitted=$true; Retcode='DONE'; Exists=$true; Matches=$true },
   @{ Name='no changes and matched'; Expected=$true; Submitted=$true; Retcode='NO_CHANGES'; Exists=$true; Matches=$true },
   @{ Name='done but mismatched'; Expected=$false; Submitted=$true; Retcode='DONE'; Exists=$true; Matches=$false },
   @{ Name='position vanished'; Expected=$false; Submitted=$true; Retcode='DONE'; Exists=$false; Matches=$false },
   @{ Name='rejected'; Expected=$false; Submitted=$true; Retcode='REJECT'; Exists=$true; Matches=$false }
)
foreach($scenario in $modifyScenarios) {
   $actual = Test-ModifyResult $scenario.Submitted $scenario.Retcode $scenario.Exists $scenario.Matches
   Add-Check "modify model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

$partialScenarios = @(
   @{ Name='done and reduced'; Expected=$true; Submitted=$true; Retcode='DONE'; Exists=$true; Before=0.10; After=0.05 },
   @{ Name='partial and reduced'; Expected=$true; Submitted=$true; Retcode='DONE_PARTIAL'; Exists=$true; Before=0.10; After=0.07 },
   @{ Name='position fully gone'; Expected=$true; Submitted=$true; Retcode='DONE'; Exists=$false; Before=0.10; After=0.00 },
   @{ Name='unchanged volume'; Expected=$false; Submitted=$true; Retcode='DONE'; Exists=$true; Before=0.10; After=0.10 },
   @{ Name='rejected'; Expected=$false; Submitted=$true; Retcode='REJECT'; Exists=$true; Before=0.10; After=0.10 }
)
foreach($scenario in $partialScenarios) {
   $actual = Test-PartialResult $scenario.Submitted $scenario.Retcode $scenario.Exists $scenario.Before $scenario.After
   Add-Check "partial model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
   InpUseAccountWideExposureGuard = 'true'
   InpAccountWideMaxPositions = '1'
   InpClosePositionsOnRiskLimit = 'true'
}.GetEnumerator()) {
   Add-Check "trade-result profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC trade-result checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC trade-result checks"
