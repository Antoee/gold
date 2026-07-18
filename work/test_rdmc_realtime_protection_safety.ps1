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

function Test-CriticalPositionStateModel(
   [bool]$Readable,
   [bool]$ResearchOwned,
   [bool]$LaneEnabled,
   [bool]$IdentifierAvailable,
   [bool]$StatePresent,
   [double]$InitialRisk
) {
   if(!$Readable) { return $false }
   if(!$ResearchOwned) { return $true }
   if(!$LaneEnabled) { return $false }
   if(!$IdentifierAvailable -or !$StatePresent) { return $false }
   return ![double]::IsNaN($InitialRisk) -and ![double]::IsInfinity($InitialRisk) -and $InitialRisk -gt 0.0
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
$criticalState = Get-Section $source "bool CriticalResearchPositionStateAllows(string &reason)" "bool ResearchPositionIdentifierOpen(const ulong positionIdentifier, const long magic)"
$magicContract = Get-Section $source "bool ResearchMagicContractAllows()" "bool IsResearchPortfolioMagic(const long magic)"
$magicOwnership = Get-Section $source "bool IsResearchPortfolioMagic(const long magic)" "int ResearchActiveOrderCount()"
$momentumClass = Get-Section $source "class CMomentumLane" "CMomentumLane g_momentum;"
$momentumInit = Get-Section $momentumClass "bool Init()" "void Deinit()"
$momentumClose = Get-Section $momentumClass "void CloseAll(const string reason)" "void OnTradeTransaction(const MqlTradeTransaction &transaction)"

Add-Check "realtime guard checks lifetime equity drawdown" ($realtime.Contains('CurrentEquityDrawdownPercent() >= InpMaxEquityDrawdownPercent') -and $realtime.Contains('reason = "equity drawdown limit";')) "equity DD"
Add-Check "realtime guard checks missing protective stops" ($realtime.Contains('OpenRiskPercent(hasUnprotectedPosition);') -and $realtime.Contains('hasUnprotectedPosition && InpBlockUnprotectedExposure')) "unprotected exposure"
Add-Check "critical-state guard scans every open position" ($criticalState.Contains('for(int i = PositionsTotal() - 1; i >= 0; --i)')) "full position scan"
Add-Check "critical-state guard fails on unreadable snapshots" ($criticalState.Contains('ticket == 0 || !PositionSelectByTicket(ticket)') -and $criticalState.Contains('critical position snapshot unavailable')) "snapshot"
Add-Check "critical-state guard scopes expert positions on the chart symbol" ($criticalState.Contains('PositionGetString(POSITION_SYMBOL) != _Symbol') -and $criticalState.Contains('PositionGetInteger(POSITION_REASON) != POSITION_REASON_EXPERT')) "ownership scope"
Add-Check "critical-state guard covers both research magics" ($criticalState.Contains('magic == InpMagicNumber') -and $criticalState.Contains('magic == InpMOMagicNumber') -and $criticalState.Contains('statePrefix = "IR";') -and $criticalState.Contains('statePrefix = "MR";')) "primary and momentum"
Add-Check "research ownership does not depend on momentum enable state" ($magicOwnership.Contains('magic == InpMagicNumber || magic == InpMOMagicNumber') -and !$magicOwnership.Contains('InpMOEnabled')) "stable ownership"
Add-Check "research magic contract requires positive distinct identities" ($magicContract.Contains('InpMagicNumber <= 0') -and $magicContract.Contains('InpMOMagicNumber <= 0') -and $magicContract.Contains('InpMagicNumber == InpMOMagicNumber') -and $magicContract.Contains('must be positive and distinct')) "magic contract"
Add-Check "critical-state guard rejects disabled momentum exposure" ($criticalState.Contains('if(!InpMOEnabled)') -and $criticalState.Contains('reason = "disabled momentum exposure";')) "disabled lane"
Add-Check "momentum invalid magic is rejected while disabled" ($momentumInit.Contains('InpMagicNumber <= 0') -and $momentumInit.Contains('InpMOMagicNumber <= 0') -and $momentumInit.IndexOf('InpMOMagicNumber == InpMagicNumber', [StringComparison]::Ordinal) -ge 0 -and $momentumInit.IndexOf('InpMOMagicNumber == InpMagicNumber', [StringComparison]::Ordinal) -lt $momentumInit.IndexOf('if(!InpMOEnabled)', [StringComparison]::Ordinal)) "valid ownership"
Add-Check "momentum close executor is configured while disabled" ($momentumInit.IndexOf('m_trade.SetExpertMagicNumber(InpMOMagicNumber);', [StringComparison]::Ordinal) -ge 0 -and $momentumInit.IndexOf('m_trade.SetTypeFillingBySymbol(_Symbol)', [StringComparison]::Ordinal) -lt $momentumInit.IndexOf('if(!InpMOEnabled)', [StringComparison]::Ordinal)) "close executor ready"
Add-Check "momentum emergency close has no enable-state bypass" (!$momentumClose.Contains('if(!InpMOEnabled)') -and $momentumClose.Contains('ClosePosition(ticket, reason)') -and $momentumClass.Contains('ExecutePositionClose(m_trade, ticket)')) "disabled lane closes"
Add-Check "critical-state guard requires immutable identity" ($criticalState.Contains('POSITION_IDENTIFIER') -and $criticalState.Contains('if(positionIdentifier <= 0)') -and $criticalState.Contains('critical position identity unavailable')) "identity"
Add-Check "critical-state guard builds keys from exact identifiers" ($criticalState.Contains('PositionScopedStateKeyForIdentifier(statePrefix,') -and $criticalState.Contains('(ulong)positionIdentifier')) "identifier key"
Add-Check "critical-state guard rejects missing initial risk" ($criticalState.Contains('if(!GlobalVariableCheck(key))') -and $criticalState.Contains('critical initial-risk state missing')) "missing state"
Add-Check "critical-state guard rejects nonfinite or nonpositive risk" ($criticalState.Contains('!MathIsValidNumber(initialRisk) || initialRisk <= 0.0') -and $criticalState.Contains('critical initial-risk state invalid')) "invalid state"
Add-Check "realtime guard has no history scan" ($realtime -notmatch 'HistorySelect|HistoryDealsTotal|PeriodProfit|RefreshConsecutiveLosses|ClosedProfit|EntriesSince') "lightweight path"
Add-Check "realtime guard has no delay or retry loop" ($realtime -notmatch '\bSleep\s*\(|\bwhile\s*\(') "nonblocking path"
Add-Check "drawdown check persists lifetime peak" ($drawdown.Contains('UpdatePeakEquity(equity);') -and $drawdown.Contains('if(!g_peakEquityPersistenceHealthy)') -and $drawdown.Contains('return DBL_MAX;')) "persistent peak"
Add-Check "missing stop is recognized on research positions" ($positionRisk.Contains('!IsResearchPortfolioMagic(PositionGetInteger(POSITION_MAGIC))') -and $positionRisk.Contains('if(sl <= 0.0 || openPrice <= 0.0 || volume <= 0.0)') -and $positionRisk.Contains('unprotected = true;')) "research magic and SL"
Add-Check "profitable break-even stops are not misclassified" ($positionRisk.Contains('if(sl >= openPrice)') -and $positionRisk.Contains('if(sl <= openPrice)')) "zero remaining risk allowed"

$finalOnTickIndex = $source.LastIndexOf('void OnTick()', [StringComparison]::Ordinal)
$finalTransactionIndex = $source.LastIndexOf('void OnTradeTransaction', [StringComparison]::Ordinal)
$onTick = if($finalOnTickIndex -ge 0 -and $finalTransactionIndex -gt $finalOnTickIndex) { $source.Substring($finalOnTickIndex, $finalTransactionIndex - $finalOnTickIndex) } else { '' }
$onInitStart = $source.LastIndexOf('int OnInit()', [StringComparison]::Ordinal)
$onInit = if($onInitStart -ge 0 -and $finalOnTickIndex -gt $onInitStart) { $source.Substring($onInitStart, $finalOnTickIndex - $onInitStart) } else { '' }
$magicContractIndex = $onInit.IndexOf('ResearchMagicContractAllows()', [StringComparison]::Ordinal)
$capitalContractIndex = $onInit.IndexOf('ResearchCapitalContractAllows()', [StringComparison]::Ordinal)
Add-Check "magic contract runs before capital-state registration" ($magicContractIndex -ge 0 -and $capitalContractIndex -gt $magicContractIndex) "magic=$magicContractIndex capital=$capitalContractIndex"
$realtimeIndex = $onTick.IndexOf('riskManager.RealtimeProtectionLimitHit(realtimeRiskReason)', [StringComparison]::Ordinal)
$newBarIndex = $onTick.IndexOf('bool newBar = IsNewBar();', [StringComparison]::Ordinal)
$momentumIndex = $onTick.IndexOf('g_momentum.OnTick();', [StringComparison]::Ordinal)
$earlyReturnIndex = $onTick.IndexOf('if(InpTradeOnlyNewBar && !newBar)', [StringComparison]::Ordinal)
$primaryCloseIndex = $onTick.IndexOf('positionManager.CloseAll(realtimeRiskReason);', [StringComparison]::Ordinal)
$momentumCloseIndex = $onTick.IndexOf('g_momentum.CloseAll(realtimeRiskReason);', [StringComparison]::Ordinal)
$urgentReturnIndex = $onTick.IndexOf('return;', $momentumCloseIndex, [StringComparison]::Ordinal)
$realtimeCallCount = @([regex]::Matches($onTick, 'RealtimeProtectionLimitHit\(')).Count
$criticalStateIndex = $onTick.IndexOf('CriticalResearchPositionStateAllows(realtimeRiskReason)', [StringComparison]::Ordinal)
$optionalRiskIndex = $onTick.IndexOf('if(!realtimeRiskHit && InpClosePositionsOnRiskLimit)', [StringComparison]::Ordinal)
Add-Check "critical-state guard runs unconditionally on every ready tick" ($criticalStateIndex -ge 0 -and $optionalRiskIndex -gt $criticalStateIndex) "state=$criticalStateIndex optional=$optionalRiskIndex"
Add-Check "optional risk switch cannot bypass critical-state flatten" ($onTick.Contains('bool realtimeRiskHit = !CriticalResearchPositionStateAllows(realtimeRiskReason);') -and $onTick.Contains('if(realtimeRiskHit)')) "unconditional integrity"
Add-Check "realtime guard runs before new-bar calculation" ($realtimeIndex -ge 0 -and $newBarIndex -gt $realtimeIndex) "guard=$realtimeIndex newbar=$newBarIndex"
Add-Check "realtime guard runs before momentum management or entry" ($realtimeIndex -ge 0 -and $momentumIndex -gt $realtimeIndex) "guard=$realtimeIndex momentum=$momentumIndex"
Add-Check "realtime guard runs before ordinary new-bar early return" ($realtimeIndex -ge 0 -and $earlyReturnIndex -gt $realtimeIndex) "guard=$realtimeIndex return_gate=$earlyReturnIndex"
Add-Check "realtime exit closes primary and momentum lanes" ($primaryCloseIndex -gt $realtimeIndex -and $momentumCloseIndex -gt $primaryCloseIndex) "primary=$primaryCloseIndex momentum=$momentumCloseIndex"
Add-Check "urgent close returns before later entry logic" ($urgentReturnIndex -gt $momentumCloseIndex -and $urgentReturnIndex -lt $newBarIndex) "return=$urgentReturnIndex"
Add-Check "realtime guard is called exactly once" ($realtimeCallCount -eq 1) "calls=$realtimeCallCount"
Add-Check "full bar-based risk gate remains present" ($onTick.Contains('riskManager.RiskLimitHit(riskExitReason)') -and $onTick.IndexOf('riskManager.RiskLimitHit(riskExitReason)', [StringComparison]::Ordinal) -gt $earlyReturnIndex) "full gate retained"

$positionManager = Get-Section $source "class CPositionManager" "CPositionManager positionManager;"
$primaryClose = Get-Section $positionManager "void CloseAll(const string reason)" "void Manage(const ENUM_TRADE_BIAS currentSignalBias)"
Add-Check "primary emergency close owns primary magic" ($primaryClose.Contains('PositionGetInteger(POSITION_MAGIC) != InpMagicNumber') -and $primaryClose.Contains('CloseAndLog(ticket,')) "primary close"
Add-Check "primary emergency close logs broker rejection" ($positionManager.Contains('ReportTradeFailure("position close", ticket, reason)') -and $positionManager.Contains('TradeResultEvidence(trade)')) "primary failure visible"
Add-Check "momentum emergency close owns momentum magic" ($momentumClose.Contains('PositionGetInteger(POSITION_MAGIC) != InpMOMagicNumber') -and $momentumClose.Contains('ClosePosition(ticket, reason)') -and $momentumClass.Contains('ExecutePositionClose(m_trade, ticket)')) "momentum close"

$criticalStateScenarios = @(
   @{ Name='valid primary state'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=12.5; Expected=$true },
   @{ Name='valid momentum state'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=4.25; Expected=$true },
   @{ Name='disabled momentum exposure'; Readable=$true; ResearchOwned=$true; LaneEnabled=$false; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=4.25; Expected=$false },
   @{ Name='foreign position ignored'; Readable=$true; ResearchOwned=$false; LaneEnabled=$false; IdentifierAvailable=$false; StatePresent=$false; InitialRisk=0.0; Expected=$true },
   @{ Name='unreadable snapshot'; Readable=$false; ResearchOwned=$false; LaneEnabled=$true; IdentifierAvailable=$false; StatePresent=$false; InitialRisk=0.0; Expected=$false },
   @{ Name='missing immutable identifier'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$false; StatePresent=$true; InitialRisk=12.5; Expected=$false },
   @{ Name='missing initial-risk key'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$false; InitialRisk=12.5; Expected=$false },
   @{ Name='zero initial risk'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=0.0; Expected=$false },
   @{ Name='negative initial risk'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=-1.0; Expected=$false },
   @{ Name='NaN initial risk'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=[double]::NaN; Expected=$false },
   @{ Name='infinite initial risk'; Readable=$true; ResearchOwned=$true; LaneEnabled=$true; IdentifierAvailable=$true; StatePresent=$true; InitialRisk=[double]::PositiveInfinity; Expected=$false }
)
foreach($scenario in $criticalStateScenarios) {
   $actual = Test-CriticalPositionStateModel -Readable $scenario.Readable -ResearchOwned $scenario.ResearchOwned -LaneEnabled $scenario.LaneEnabled -IdentifierAvailable $scenario.IdentifierAvailable -StatePresent $scenario.StatePresent -InitialRisk $scenario.InitialRisk
   Add-Check "critical-state model: $($scenario.Name)" ($actual -eq $scenario.Expected) "actual=$actual"
}

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
