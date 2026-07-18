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

function Normalize-VolumeDown([double]$Volume, [double]$Step) {
   if($Volume -le 0.0 -or $Step -le 0.0) { return 0.0 }
   return [Math]::Floor($Volume / $Step + 0.00000001) * $Step
}

function Test-FullCloseModel(
   [bool]$Selected,
   [bool]$MagicOwned,
   [bool]$ExpertOwned,
   [bool]$Submitted,
   [bool]$RetcodeAccepted,
   [bool]$PositionGone
) {
   return $Selected -and $MagicOwned -and $ExpertOwned -and
          $Submitted -and $RetcodeAccepted -and $PositionGone
}

function Test-PartialCloseModel(
   [bool]$Selected,
   [bool]$MagicOwned,
   [bool]$ExpertOwned,
   [double]$CurrentVolume,
   [double]$PreviousVolume,
   [double]$CloseVolume,
   [double]$Step,
   [double]$Minimum,
   [bool]$Submitted,
   [bool]$RetcodeAccepted,
   [bool]$PositionRemains,
   [double]$ResultingVolume
) {
   if(!$Selected -or !$MagicOwned -or !$ExpertOwned -or !$Submitted -or !$RetcodeAccepted -or !$PositionRemains) { return $false }
   if($CurrentVolume -le 0.0 -or $PreviousVolume -le 0.0 -or $CloseVolume -le 0.0 -or $Step -le 0.0 -or $Minimum -le 0.0) { return $false }
   $stateTolerance = [Math]::Max($Step * 0.5, 0.00000001)
   $alignmentTolerance = [Math]::Max($Step * 0.000001, 0.00000001)
   $normalizedClose = Normalize-VolumeDown $CloseVolume $Step
   $expected = Normalize-VolumeDown ($PreviousVolume - $CloseVolume) $Step
   if([Math]::Abs($CurrentVolume - $PreviousVolume) -gt $stateTolerance) { return $false }
   if([Math]::Abs($normalizedClose - $CloseVolume) -gt $alignmentTolerance) { return $false }
   if($normalizedClose -lt $Minimum - $alignmentTolerance) { return $false }
   if($CloseVolume -ge $CurrentVolume - $stateTolerance) { return $false }
   if($expected -lt $Minimum - $alignmentTolerance) { return $false }
   return $ResultingVolume -lt $PreviousVolume - $stateTolerance -and
          [Math]::Abs($ResultingVolume - $expected) -le $stateTolerance
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Close-ownership audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$ownership = Get-Section $source "bool SelectOwnedExpertPosition(CTrade &executor," "bool ExecutePositionClose(CTrade &executor, const ulong ticket);"
$closeMatch = [regex]::Match($source, 'bool ExecutePositionClose\(CTrade &executor, const ulong ticket\)\s*\{')
$closeEnd = if($closeMatch.Success) { $source.IndexOf('bool TradePriceMatches(', $closeMatch.Index, [StringComparison]::Ordinal) } else { -1 }
$close = if($closeMatch.Success -and $closeEnd -gt $closeMatch.Index) { $source.Substring($closeMatch.Index, $closeEnd - $closeMatch.Index) } else { '' }
$partial = Get-Section $source "bool ExecutePositionClosePartial(CTrade &executor," "bool ExecuteOrderDelete(CTrade &executor,"

Add-Check "source version is 1.21" ($source.Contains('#property version   "1.21"')) "version"
Add-Check "description advertises ownership-checked closes" ($source.Contains('ownership-checked closes')) "description"
Add-Check "one raw full-close send site remains" ([regex]::Matches($source, '\.PositionClose\(').Count -eq 1) "raw full close=1"
Add-Check "one raw partial-close send site remains" ([regex]::Matches($source, '\.PositionClosePartial\(').Count -eq 1) "raw partial close=1"
Add-Check "shared ownership helper selects exact ticket" ($ownership.Contains('ticket == 0 || !PositionSelectByTicket(ticket)')) "exact ticket"
Add-Check "shared ownership helper requires symbol" ($ownership.Contains('POSITION_SYMBOL') -and $ownership.Contains('StringLen(symbol) > 0')) "symbol"
Add-Check "shared ownership helper requires executor magic" ($ownership.Contains('POSITION_MAGIC') -and $ownership.Contains('executor.RequestMagic()')) "magic"
Add-Check "shared ownership helper requires expert reason" ($ownership.Contains('POSITION_REASON_EXPERT')) "expert reason"
Add-Check "ownership helper covers full partial and modify paths" ([regex]::Matches($source, 'SelectOwnedExpertPosition\(').Count -eq 6) "definition plus five checks"

Add-Check "full close verifies ownership before send" ($close.IndexOf('SelectOwnedExpertPosition(', [StringComparison]::Ordinal) -lt $close.IndexOf('executor.PositionClose(', [StringComparison]::Ordinal)) "call order"
Add-Check "full close uses exact ticket" ($close.Contains('executor.PositionClose(ticket)')) "ticket request"
Add-Check "full close accepts completed broker retcodes" (@('TRADE_RETCODE_DONE','TRADE_RETCODE_DONE_PARTIAL','TRADE_RETCODE_POSITION_CLOSED').Where({ $close.Contains($_) }).Count -eq 3) "retcodes"
Add-Check "full close requires position disappearance" ($close.Contains('bool closed = !PositionSelectByTicket(ticket);') -and $close.Contains('return closed;')) "closed state"
Add-Check "forced-close marker clears only after disappearance" ($close.IndexOf('if(closed)', [StringComparison]::Ordinal) -lt $close.IndexOf('GlobalVariableDel(PostFillForcedCloseKey(ticket, magic));', [StringComparison]::Ordinal)) "marker cleanup"
Add-Check "post-fill failure uses verified close wrapper" ($source.Contains('if(!ExecutePositionClose(executor, ticket))')) "post-fill close"
Add-Check "primary manager uses verified close wrapper" ($source.Contains('if(!ExecutePositionClose(trade, ticket))')) "primary close"
Add-Check "momentum manager uses verified close wrapper" ($source.Contains('if(ExecutePositionClose(m_trade, ticket))')) "momentum close"

Add-Check "partial close verifies ownership before send" ($partial.IndexOf('SelectOwnedExpertPosition(', [StringComparison]::Ordinal) -lt $partial.IndexOf('executor.PositionClosePartial(', [StringComparison]::Ordinal)) "call order"
Add-Check "partial close reads symbol-native volume geometry" ($partial.Contains('SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP)') -and $partial.Contains('SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)')) "volume geometry"
Add-Check "partial close rejects unavailable geometry and volume" ($partial.Contains('currentVolume <= 0.0') -and $partial.Contains('volumeStep <= 0.0') -and $partial.Contains('minLot <= 0.0')) "fail closed"
Add-Check "partial close uses strict alignment tolerance" ($partial.Contains('volumeStep * 0.000001') -and $partial.Contains('MathAbs(normalizedClose - closeVolume) > alignmentTolerance')) "step alignment"
Add-Check "partial close rejects stale volume snapshot" ($partial.Contains('MathAbs(currentVolume - previousVolume) > tolerance')) "snapshot"
Add-Check "partial close requires minimum close size" ($partial.Contains('normalizedClose < minLot - alignmentTolerance')) "minimum close"
Add-Check "partial close cannot become a full close" ($partial.Contains('closeVolume >= currentVolume - tolerance')) "strict partial"
Add-Check "partial close preserves minimum remainder" ($partial.Contains('expectedVolume < minLot - alignmentTolerance')) "minimum remainder"
Add-Check "partial close uses exact ticket and volume" ($partial.Contains('executor.PositionClosePartial(ticket, closeVolume)')) "request"
Add-Check "partial close accepts only completed retcodes" ($partial.Contains('TRADE_RETCODE_DONE') -and $partial.Contains('TRADE_RETCODE_DONE_PARTIAL')) "retcodes"
Add-Check "partial close requires position to remain owned" ([regex]::Matches($partial, 'SelectOwnedExpertPosition\(').Count -eq 2 -and $partial.Contains('resultingSymbol != symbol')) "post state ownership"
Add-Check "partial close verifies exact requested remainder" ($partial.Contains('MathAbs(resultingVolume - expectedVolume) <= tolerance')) "remaining volume"
Add-Check "partial close verifies a material reduction" ($partial.Contains('resultingVolume < previousVolume - tolerance')) "volume reduction"

$fullBase = @{ Selected=$true;MagicOwned=$true;ExpertOwned=$true;Submitted=$true;RetcodeAccepted=$true;PositionGone=$true }
$fullScenarios = @(
   @{ Name='verified full close';Expected=$true;Values=@{} },
   @{ Name='selection failure';Expected=$false;Values=@{Selected=$false} },
   @{ Name='magic mismatch';Expected=$false;Values=@{MagicOwned=$false} },
   @{ Name='non-expert position';Expected=$false;Values=@{ExpertOwned=$false} },
   @{ Name='broker send failure';Expected=$false;Values=@{Submitted=$false} },
   @{ Name='broker retcode failure';Expected=$false;Values=@{RetcodeAccepted=$false} },
   @{ Name='position still open';Expected=$false;Values=@{PositionGone=$false} }
)
foreach($scenario in $fullScenarios) {
   $state = @{} + $fullBase
   foreach($key in $scenario.Values.Keys) { $state[$key] = $scenario.Values[$key] }
   $actual = Test-FullCloseModel @state
   Add-Check "full-close model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

$partialBase = @{ Selected=$true;MagicOwned=$true;ExpertOwned=$true;CurrentVolume=0.02;PreviousVolume=0.02;CloseVolume=0.01;Step=0.01;Minimum=0.01;Submitted=$true;RetcodeAccepted=$true;PositionRemains=$true;ResultingVolume=0.01 }
$partialScenarios = @(
   @{ Name='verified partial close';Expected=$true;Values=@{} },
   @{ Name='stale previous volume';Expected=$false;Values=@{PreviousVolume=0.03} },
   @{ Name='off-step close volume';Expected=$false;Values=@{CurrentVolume=0.03;PreviousVolume=0.03;CloseVolume=0.015;ResultingVolume=0.015} },
   @{ Name='below minimum close';Expected=$false;Values=@{CurrentVolume=0.03;PreviousVolume=0.03;CloseVolume=0.01;Minimum=0.02;ResultingVolume=0.02} },
   @{ Name='full close request';Expected=$false;Values=@{CloseVolume=0.02;PositionRemains=$false;ResultingVolume=0.0} },
   @{ Name='below minimum remainder';Expected=$false;Values=@{CurrentVolume=0.03;PreviousVolume=0.03;CloseVolume=0.02;Minimum=0.02;ResultingVolume=0.01} },
   @{ Name='position disappeared';Expected=$false;Values=@{PositionRemains=$false;ResultingVolume=0.0} },
   @{ Name='wrong resulting volume';Expected=$false;Values=@{ResultingVolume=0.02} },
   @{ Name='magic mismatch';Expected=$false;Values=@{MagicOwned=$false} },
   @{ Name='non-expert position';Expected=$false;Values=@{ExpertOwned=$false} },
   @{ Name='broker failure';Expected=$false;Values=@{Submitted=$false} }
)
foreach($scenario in $partialScenarios) {
   $state = @{} + $partialBase
   foreach($key in $scenario.Values.Keys) { $state[$key] = $scenario.Values[$key] }
   $actual = Test-PartialCloseModel @state
   Add-Check "partial-close model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpAccountWideMaxPositions = '1'
   InpUseDedicatedAccountContract = 'true'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "close profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC close-ownership checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC close-ownership checks"
