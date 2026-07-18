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

function Test-PostFillModel(
   [bool]$Found,
   [bool]$Owned,
   [bool]$Protected,
   [bool]$TargetMatched,
   [bool]$VolumeMatched,
   [double]$PlannedRisk,
   [double]$ActualRisk,
   [double]$AllowancePercent,
   [double]$Equity,
   [double]$IndividualCapPercent,
   [bool]$AccountRiskAvailable,
   [double]$AccountRisk,
   [double]$AccountCapPercent,
   [int]$AccountPositionCount,
   [int]$AccountPositionCap
) {
   if(!$Found -or !$Owned -or !$Protected -or !$TargetMatched -or !$VolumeMatched) { return $false }
   if($PlannedRisk -le 0.0 -or $ActualRisk -le 0.0 -or $Equity -le 0.0) { return $false }
   if($ActualRisk -gt $PlannedRisk * (1.0 + [Math]::Max(0.0, $AllowancePercent) / 100.0) + 0.01) { return $false }
   if($IndividualCapPercent -gt 0.0 -and 100.0 * $ActualRisk / $Equity -gt $IndividualCapPercent + 0.000001) { return $false }
   if(!$AccountRiskAvailable -or $AccountRisk -lt 0.0) { return $false }
   if($AccountPositionCap -le 0 -or $AccountPositionCount -le 0 -or $AccountPositionCount -gt $AccountPositionCap) { return $false }
   if($AccountCapPercent -gt 0.0 -and 100.0 * $AccountRisk / $Equity -gt $AccountCapPercent + 0.000001) { return $false }
   return $true
}

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Post-fill audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$validatedTrade = Get-Section $source "class CValidatedTrade : public CTrade" "CValidatedTrade trade;"
$entry = Get-Section $source "bool ExecuteMarketEntry(CValidatedTrade &executor," "bool ExecutePositionClose(CTrade &executor,"
$risk = Get-Section $source "double CalculatedOrderRiskMoney(" "string PostFillForcedCloseKey("
$realtime = Get-Section $source "bool RealtimeProtectionLimitHit(string &reason)" "double NormalizeLots(const double lots)"
$closeMatch = [regex]::Match($source, 'bool ExecutePositionClose\(CTrade &executor, const ulong ticket\)\s*\{')
$closeEnd = if($closeMatch.Success) { $source.IndexOf('bool TradePriceMatches(', $closeMatch.Index, [StringComparison]::Ordinal) } else { -1 }
$close = if($closeMatch.Success -and $closeEnd -gt $closeMatch.Index) { $source.Substring($closeMatch.Index, $closeEnd - $closeMatch.Index) } else { '' }

Add-Check "source version is 1.25" ($source.Contains('#property version   "1.25"')) "version"
Add-Check "description advertises scoped ownership-checked execution" ($source.Contains('verified account-scoped') -and $source.Contains('ownership-checked execution')) "description"
Add-Check "post-fill risk tolerance is configurable" ($source.Contains('input double InpMaxPostFillRiskIncreasePercent = 5.00;')) "input"
Add-Check "cash-risk helper validates side and geometry" ($risk.Contains('ORDER_TYPE_BUY') -and $risk.Contains('ORDER_TYPE_SELL') -and $risk.Contains('entryPrice <= 0.0') -and $risk.Contains('stopPrice <= 0.0') -and $risk.Contains('lots <= 0.0')) "risk inputs"
Add-Check "cash-risk helper uses broker calculation" ($risk.Contains('OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit)') -and $risk.Contains('return MathAbs(stopProfit);')) "OrderCalcProfit"
Add-Check "position-risk helper fails closed when selection is unreadable" ($risk.Contains('CalculatedPositionRiskMoney(const ulong ticket, bool &unprotected)') -and $risk.Contains('ticket == 0 || !PositionSelectByTicket(ticket)') -and $risk.Contains('return -1.0;')) "position snapshot"
Add-Check "position-risk helper distinguishes protected profit" ($risk.Contains('if(stopPrice >= openPrice)') -and $risk.Contains('if(stopPrice <= openPrice)') -and $risk.Contains('return 0.0;')) "zero downside"
Add-Check "account-risk helper scans every open position" ($risk.Contains('CalculatedAccountOpenRiskPercent') -and $risk.Contains('for(int i = PositionsTotal() - 1; i >= 0; --i)') -and $risk.Contains('positionCount++;')) "full account scan"
Add-Check "account-risk helper fails closed on incomplete valuation" ($risk.Contains('if(unprotected || positionRiskMoney < 0.0)') -and $risk.Contains('hasUnprotectedPosition = true;')) "incomplete valuation"
Add-Check "validated executor stores exact filled ticket" ($validatedTrade.Contains('ulong m_lastFilledPositionTicket;') -and $validatedTrade.Contains('LastFilledPositionTicket() const')) "ticket"
Add-Check "validated executor stores actual risk distance" ($validatedTrade.Contains('double m_lastFilledRiskDistance;') -and $validatedTrade.Contains('LastFilledRiskDistance() const')) "risk distance"
Add-Check "preflight clears stale fill identity" ($validatedTrade.Contains('m_lastFilledPositionTicket = 0;') -and $validatedTrade.Contains('m_lastFilledRiskDistance = 0.0;')) "reset"
Add-Check "result-order ticket is preferred" ($validatedTrade.Contains('ulong orderTicket = ResultOrder();') -and $validatedTrade.Contains('PositionSelectByTicket(orderTicket)')) "order link"
Add-Check "deal position identifier is fallback" ($validatedTrade.Contains('ulong dealTicket = ResultDeal();') -and $validatedTrade.Contains('DEAL_POSITION_ID')) "deal link"
Add-Check "fallback matches immutable position identifier" ($validatedTrade.Contains('POSITION_IDENTIFIER') -and $validatedTrade.Contains('positionId > 0')) "position identity"
Add-Check "unlinked fallback still requires magic" ($validatedTrade.Contains('positionId <= 0 && PositionGetInteger(POSITION_MAGIC) != magic')) "ownership fallback"
Add-Check "fallback requires exactly one position" ($validatedTrade.Contains('if(matches != 1 || !PositionSelectByTicket(matchedTicket))')) "unique match"
Add-Check "selected position validates symbol and side" ($validatedTrade.Contains('SelectedPositionGeometryMatches') -and $validatedTrade.Contains('POSITION_SYMBOL') -and $validatedTrade.Contains('POSITION_TYPE')) "geometry"
Add-Check "selected position validates magic and expert reason" ($validatedTrade.Contains('POSITION_MAGIC') -and $validatedTrade.Contains('POSITION_REASON_EXPERT') -and $validatedTrade.Contains('post-fill ownership mismatch')) "ownership"
Add-Check "post-fill reads broker position state" (@('POSITION_PRICE_OPEN','POSITION_VOLUME','POSITION_SL','POSITION_TP').Where({ $validatedTrade.Contains($_) }).Count -eq 4) "position state"
Add-Check "missing protective state fails closed" ($validatedTrade.Contains('post-fill missing price volume or protective stop')) "missing state"
Add-Check "stop direction is verified" ($validatedTrade.Contains('post-fill invalid protective-stop direction')) "stop geometry"
Add-Check "requested target state is verified" ($validatedTrade.Contains('requestedTP > 0.0') -and $validatedTrade.Contains('post-fill take-profit state mismatch')) "target state"
Add-Check "filled volume cannot exceed request" ($validatedTrade.Contains('positionVolume > requestedVolume + volumeTolerance')) "request volume"
Add-Check "position volume matches broker result" ($validatedTrade.Contains('MathAbs(positionVolume - reportedVolume) > volumeTolerance')) "result volume"
Add-Check "planned cash risk uses sent request" ($validatedTrade.Contains('requestedPrice') -and $validatedTrade.Contains('requestedSL') -and $validatedTrade.Contains('requestedVolume')) "planned risk"
Add-Check "actual cash risk uses broker position" ($validatedTrade.Contains('openPrice') -and $validatedTrade.Contains('actualSL') -and $validatedTrade.Contains('positionVolume')) "actual risk"
Add-Check "unavailable cash risk fails closed" ($validatedTrade.Contains('post-fill cash risk unavailable')) "cash risk"
Add-Check "risk increase uses configured tolerance" ($validatedTrade.Contains('InpMaxPostFillRiskIncreasePercent') -and $validatedTrade.Contains('maximumActualRisk')) "tolerance"
Add-Check "excess fill risk fails closed" ($validatedTrade.Contains('post-fill cash risk exceeds planned allowance')) "risk excess"
Add-Check "individual open-risk cap uses actual filled risk" ($validatedTrade.Contains('actualRiskPercent') -and $validatedTrade.Contains('post-fill individual open-risk cap')) "individual cap"
Add-Check "account-wide risk is recomputed after fill" ($validatedTrade.Contains('CalculatedAccountOpenRiskPercent(hasUnprotectedPosition,') -and $validatedTrade.Contains('accountPositionCount')) "aggregate snapshot"
Add-Check "account-wide unreadable risk fails closed" ($validatedTrade.Contains('accountOpenRiskPercent < 0.0') -and $validatedTrade.Contains('post-fill account-wide risk unavailable')) "aggregate unavailable"
Add-Check "account-wide position ceiling is rechecked after fill" ($validatedTrade.Contains('accountPositionCount > InpAccountWideMaxPositions') -and $validatedTrade.Contains('post-fill account-wide position cap')) "position cap"
Add-Check "account-wide aggregate cap is enforced" ($validatedTrade.Contains('accountOpenRiskPercent > InpAccountWideMaxOpenRiskPercent') -and $validatedTrade.Contains('post-fill account-wide open-risk cap')) "aggregate cap"
Add-Check "shared risk manager uses fail-closed account helper" ($source.Contains('return CalculatedAccountOpenRiskPercent(hasUnprotectedPosition, positionCount);')) "shared helper"
Add-Check "post-fill risk caps use current equity" ($validatedTrade.Contains('ACCOUNT_EQUITY') -and $validatedTrade.Contains('post-fill equity unavailable')) "equity cap"
Add-Check "actual risk distance comes from fill and attached stop" ($validatedTrade.Contains('m_lastFilledRiskDistance = MathAbs(openPrice - actualSL);')) "actual distance"
Add-Check "entry wrapper reconciles after deal verification" ($entry.IndexOf('if(executor.ResultDeal() <= 0)', [StringComparison]::Ordinal) -lt $entry.IndexOf('PostFillPositionAllows(', [StringComparison]::Ordinal)) "call order"
Add-Check "reconciliation failure logs precise reason" ($entry.Contains('Post-fill reconciliation failed:') -and $entry.Contains('reconciliationReason')) "diagnostic"
Add-Check "forced-close marker is account magic and position scoped" ($source.Contains('PostFillForcedCloseKey(const ulong ticket, const long magic)') -and $source.Contains('PositionScopedStateKeyForTicket("PF", magic, ticket)') -and $source.Contains('PostFillForcedCloseIdentifierKey(const ulong positionIdentifier, const long magic)') -and $source.Contains('PositionScopedStateKeyForIdentifier("PF", magic, positionIdentifier)') -and $source.Contains('AccountInfoInteger(ACCOUNT_LOGIN)')) "account/magic/position"
Add-Check "failed reconciliation marks exact ticket" ($entry.Contains('SetCriticalPersistentState(PostFillForcedCloseKey(ticket, (long)executor.RequestMagic()),') -and $entry.Contains('TimeCurrent()')) "persistent marker"
Add-Check "failed reconciliation closes through verified wrapper" ($entry.Contains('ExecutePositionClose(executor, ticket)')) "verified close"
Add-Check "failed emergency close remains visible" ($entry.Contains('Post-fill emergency close failed:')) "close evidence"
Add-Check "successful close clears forced marker" ($close.Contains('string forcedCloseKey = PostFillForcedCloseKey(ticket, magic);') -and $close.Contains('DeleteCriticalPersistentState(forcedCloseKey);')) "marker cleanup"
Add-Check "realtime protection retries marked position" ($realtime.Contains('GlobalVariableCheck(PostFillForcedCloseKey(ticket, magic))') -and $realtime.Contains('post-fill reconciliation forced close')) "retry path"
Add-Check "realtime retry has no history scan or sleep" (!$realtime.Contains('HistorySelect') -and !$realtime.Contains('Sleep(')) "lightweight retry"
Add-Check "momentum stores exact reconciled risk" ($source.Contains('filledTicket = m_trade.LastFilledPositionTicket()') -and $source.Contains('filledRiskDistance = m_trade.LastFilledRiskDistance()') -and $source.Contains('SetCriticalPersistentState(MomentumRiskKey(filledTicket), filledRiskDistance)')) "momentum risk"
Add-Check "three primary entries require exact reconciled risk persistence" ([regex]::Matches($source, 'PersistPrimaryInitialRiskOrClose\(trade\)').Count -eq 3 -and $source.Contains('StoreInitialRisk(ticket, executor.LastFilledRiskDistance())')) "primary calls=3"
Add-Check "newest-position risk guessing is removed" (!$source.Contains('RegisterInitialRiskForNewestPosition') -and !$source.Contains('RegisterRiskForNewestPosition')) "exact identity only"
Add-Check "all four entries still use shared wrapper" ([regex]::Matches($source, 'ExecuteMarketEntry\(').Count -eq 5) "definition plus four calls"

$base = @{ Found=$true; Owned=$true; Protected=$true; TargetMatched=$true; VolumeMatched=$true; PlannedRisk=50.0; ActualRisk=50.0; AllowancePercent=5.0; Equity=10000.0; IndividualCapPercent=0.75; AccountRiskAvailable=$true; AccountRisk=50.0; AccountCapPercent=0.75; AccountPositionCount=1; AccountPositionCap=1 }
$scenarios = @(
   @{ Name='exact fill'; Expected=$true; Values=@{} },
   @{ Name='five percent tolerated'; Expected=$true; Values=@{ActualRisk=52.5;AccountRisk=52.5} },
   @{ Name='risk allowance exceeded'; Expected=$false; Values=@{ActualRisk=52.52;AccountRisk=52.52} },
   @{ Name='individual cap exceeded'; Expected=$false; Values=@{PlannedRisk=80.0;ActualRisk=80.0;AccountRisk=80.0} },
   @{ Name='aggregate cap exceeded'; Expected=$false; Values=@{AccountRisk=80.0} },
   @{ Name='aggregate risk unavailable'; Expected=$false; Values=@{AccountRiskAvailable=$false} },
   @{ Name='post-fill position cap exceeded'; Expected=$false; Values=@{AccountPositionCount=2} },
   @{ Name='position not found'; Expected=$false; Values=@{Found=$false} },
   @{ Name='ownership mismatch'; Expected=$false; Values=@{Owned=$false} },
   @{ Name='missing stop'; Expected=$false; Values=@{Protected=$false} },
   @{ Name='target mismatch'; Expected=$false; Values=@{TargetMatched=$false} },
   @{ Name='volume mismatch'; Expected=$false; Values=@{VolumeMatched=$false} },
   @{ Name='planned risk unavailable'; Expected=$false; Values=@{PlannedRisk=0.0} },
   @{ Name='actual risk unavailable'; Expected=$false; Values=@{ActualRisk=0.0} },
   @{ Name='equity unavailable'; Expected=$false; Values=@{Equity=0.0} }
)
foreach($scenario in $scenarios) {
   $state = @{} + $base
   foreach($key in $scenario.Values.Keys) { $state[$key] = $scenario.Values[$key] }
   $actual = Test-PostFillModel @state
   Add-Check "post-fill model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

foreach($contract in @{
   InpMaxPostFillRiskIncreasePercent = '5.00'
   InpMaxOpenRiskPercent = '0.75'
   InpAccountWideMaxOpenRiskPercent = '0.75'
   InpUseAccountWideExposureGuard = 'true'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "post-fill profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC post-fill reconciliation checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC post-fill reconciliation checks"
