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

Add-Check "restart-safe source exists" (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check "restart-safe profile exists" (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(@($checks | Where-Object { !$_.Pass }).Count -gt 0) {
   $checks | Format-Table -AutoSize
   throw "Realtime-protection audit inputs are missing."
}

$source = Get-Content -LiteralPath $sourcePath -Raw
$profile = Read-Profile $profilePath
$realtime = Get-Section $source "bool RealtimeProtectionLimitHit(string &reason)" "double NormalizeLots(const double lots)"
$drawdown = Get-Section $source "double CurrentEquityDrawdownPercent()" "void RefreshConsecutiveLosses()"
$positionRisk = Get-Section $source "double PositionRiskMoney(const ulong ticket, bool &unprotected)" "double OpenRiskPercent(bool &hasUnprotectedPosition)"

Add-Check "realtime guard checks lifetime equity drawdown" ($realtime.Contains('CurrentEquityDrawdownPercent() >= InpMaxEquityDrawdownPercent') -and $realtime.Contains('reason = "equity drawdown limit";')) "equity DD"
Add-Check "realtime guard checks missing protective stops" ($realtime.Contains('OpenRiskPercent(hasUnprotectedPosition);') -and $realtime.Contains('hasUnprotectedPosition && InpBlockUnprotectedExposure')) "unprotected exposure"
Add-Check "realtime guard has no history scan" ($realtime -notmatch 'HistorySelect|HistoryDealsTotal|PeriodProfit|RefreshConsecutiveLosses|ClosedProfit|EntriesSince') "lightweight path"
Add-Check "realtime guard has no delay or retry loop" ($realtime -notmatch '\bSleep\s*\(|\bwhile\s*\(') "nonblocking path"
Add-Check "drawdown check persists lifetime peak" ($drawdown.Contains('UpdatePeakEquity(equity);') -and $drawdown.Contains('if(!g_peakEquityPersistenceHealthy)') -and $drawdown.Contains('return DBL_MAX;')) "persistent peak"
Add-Check "missing stop is recognized on research positions" ($positionRisk.Contains('!IsResearchPortfolioMagic(PositionGetInteger(POSITION_MAGIC))') -and $positionRisk.Contains('if(sl <= 0.0 || openPrice <= 0.0 || volume <= 0.0)') -and $positionRisk.Contains('unprotected = true;')) "research magic and SL"
Add-Check "profitable break-even stops are not misclassified" ($positionRisk.Contains('if(sl >= openPrice)') -and $positionRisk.Contains('if(sl <= openPrice)')) "zero remaining risk allowed"

$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }
$realtimeIndex = $onTick.IndexOf('riskManager.RealtimeProtectionLimitHit(realtimeRiskReason)', [StringComparison]::Ordinal)
$newBarIndex = $onTick.IndexOf('bool newBar = IsNewBar();', [StringComparison]::Ordinal)
$momentumIndex = $onTick.IndexOf('g_momentum.OnTick();', [StringComparison]::Ordinal)
$earlyReturnIndex = $onTick.IndexOf('if(InpTradeOnlyNewBar && !newBar)', [StringComparison]::Ordinal)
$primaryCloseIndex = $onTick.IndexOf('positionManager.CloseAll(realtimeRiskReason);', [StringComparison]::Ordinal)
$momentumCloseIndex = $onTick.IndexOf('g_momentum.CloseAll(realtimeRiskReason);', [StringComparison]::Ordinal)
$urgentReturnIndex = $onTick.IndexOf('return;', $momentumCloseIndex, [StringComparison]::Ordinal)
$realtimeCallCount = @([regex]::Matches($onTick, 'RealtimeProtectionLimitHit\(')).Count
Add-Check "realtime guard runs before new-bar calculation" ($realtimeIndex -ge 0 -and $newBarIndex -gt $realtimeIndex) "guard=$realtimeIndex newbar=$newBarIndex"
Add-Check "realtime guard runs before momentum management or entry" ($realtimeIndex -ge 0 -and $momentumIndex -gt $realtimeIndex) "guard=$realtimeIndex momentum=$momentumIndex"
Add-Check "realtime guard runs before ordinary new-bar early return" ($realtimeIndex -ge 0 -and $earlyReturnIndex -gt $realtimeIndex) "guard=$realtimeIndex return_gate=$earlyReturnIndex"
Add-Check "realtime exit closes primary and momentum lanes" ($primaryCloseIndex -gt $realtimeIndex -and $momentumCloseIndex -gt $primaryCloseIndex) "primary=$primaryCloseIndex momentum=$momentumCloseIndex"
Add-Check "urgent close returns before later entry logic" ($urgentReturnIndex -gt $momentumCloseIndex -and $urgentReturnIndex -lt $newBarIndex) "return=$urgentReturnIndex"
Add-Check "realtime guard is called exactly once" ($realtimeCallCount -eq 1) "calls=$realtimeCallCount"
Add-Check "full bar-based risk gate remains present" ($onTick.Contains('riskManager.RiskLimitHit(riskExitReason)') -and $onTick.IndexOf('riskManager.RiskLimitHit(riskExitReason)', [StringComparison]::Ordinal) -gt $earlyReturnIndex) "full gate retained"

$positionManager = Get-Section $source "class CPositionManager" "CPositionManager positionManager;"
$primaryClose = Get-Section $positionManager "void CloseAll(const string reason)" "void Manage(const ENUM_TRADE_BIAS currentSignalBias)"
$momentumClass = Get-Section $source "class CMomentumLane" "CMomentumLane g_momentum;"
$momentumClose = Get-Section $momentumClass "void CloseAll(const string reason)" "void OnTradeTransaction(const MqlTradeTransaction &transaction)"
Add-Check "primary emergency close owns primary magic" ($primaryClose.Contains('PositionGetInteger(POSITION_MAGIC) != InpMagicNumber') -and $primaryClose.Contains('CloseAndLog(ticket,')) "primary close"
Add-Check "primary emergency close logs broker rejection" ($positionManager.Contains('ReportTradeFailure("position close", ticket, reason)') -and $positionManager.Contains('TradeResultEvidence(trade)')) "primary failure visible"
Add-Check "momentum emergency close owns momentum magic" ($momentumClose.Contains('PositionGetInteger(POSITION_MAGIC) != InpMOMagicNumber') -and $momentumClose.Contains('ClosePosition(ticket, reason)') -and $momentumClass.Contains('ExecutePositionClose(m_trade, ticket)')) "momentum close"

foreach($contract in @{
   InpTradeOnlyNewBar = 'true'
   InpManageOnlyNewBar = 'true'
   InpClosePositionsOnRiskLimit = 'true'
   InpMaxEquityDrawdownPercent = '5.00'
   InpBlockUnprotectedExposure = 'true'
   InpAccountWideBlockUnprotectedExposure = 'true'
   InpAccountWideMaxPositions = '1'
   InpUseResearchTesterOnlyLock = 'true'
   InpUseRealAccountSafetyLock = 'true'
   InpAllowRealAccountTrading = 'false'
}.GetEnumerator()) {
   Add-Check "realtime profile: $($contract.Key)" ($profile[$contract.Key] -eq $contract.Value) "$($profile[$contract.Key])"
}

Add-Check "source contains no account identifier" ($source -notmatch '(?i)account.?id\s*[:=]\s*\d{5,}' -and $source -notmatch '(?i)login\s*[:=]\s*\d{5,}') "source clean"
Add-Check "source contains no GitHub token" ($source -notmatch 'github_pat_|gh[pousr]_[A-Za-z0-9]{20,}') "source clean"

$failed = @($checks | Where-Object { !$_.Pass })
$checks | Format-Table -AutoSize
if($failed.Count -gt 0) {
   throw "FAIL: $($failed.Count) RDMC realtime-protection checks failed."
}
Write-Host ""
Write-Host "PASS: $($checks.Count) RDMC realtime-protection checks"
