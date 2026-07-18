[CmdletBinding()]
param(
   [string]$ProfilePath = "outputs\RDMC_FORWARD_DEMO_DRAFT_PROFILE.set",
   [string]$StatusCsvPath = "outputs\RDMC_FORWARD_DEMO_STATIC_READINESS.csv",
   [string]$StatusMarkdownPath = "outputs\RDMC_FORWARD_DEMO_STATIC_READINESS.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

function Get-InputValue {
   param([hashtable]$Inputs, [string]$Name)
   if(!$Inputs.ContainsKey($Name)) { throw "Required profile input missing: $Name" }
   $line = [string]$Inputs[$Name]
   $value = $line.Substring($line.IndexOf('=') + 1)
   $optimizationSeparator = $value.IndexOf('||')
   if($optimizationSeparator -ge 0) { $value = $value.Substring(0, $optimizationSeparator) }
   return $value.Trim()
}

function Get-BoolValue {
   param([hashtable]$Inputs, [string]$Name)
   return (Get-InputValue $Inputs $Name).ToLowerInvariant() -eq 'true'
}

function Get-DoubleValue {
   param([hashtable]$Inputs, [string]$Name)
   return [double]::Parse((Get-InputValue $Inputs $Name), [Globalization.CultureInfo]::InvariantCulture)
}

function Get-IntValue {
   param([hashtable]$Inputs, [string]$Name)
   return [int]::Parse((Get-InputValue $Inputs $Name), [Globalization.CultureInfo]::InvariantCulture)
}

function Add-Rule {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Rule,
      [bool]$Pass,
      [string]$Detail
   )
   [void]$Rows.Add([pscustomobject]@{Rule=$Rule;Pass=$Pass;Detail=$Detail})
}

$profile = Resolve-RepoPath $ProfilePath
$statusCsv = Resolve-RepoPath $StatusCsvPath
$statusMarkdown = Resolve-RepoPath $StatusMarkdownPath
$inputs = Import-SetInputs -Path $profile
if($inputs.Keys.Count -ne 589) { throw "Expected 589 frozen inputs, found $($inputs.Keys.Count)." }

$rows = [System.Collections.Generic.List[object]]::new()
$maxRisk = [math]::Max(0.01, (Get-DoubleValue $inputs 'InpTradeReadyMaxRiskPercent'))
$maxOpenRisk = [math]::Max($maxRisk, (Get-DoubleValue $inputs 'InpTradeReadyMaxOpenRiskPercent'))
$maxLots = [math]::Max(0.01, (Get-DoubleValue $inputs 'InpTradeReadyMaxPositionLots'))
$maxPositions = [math]::Max(1, (Get-IntValue $inputs 'InpTradeReadyMaxSimultaneousPositions'))

Add-Rule $rows 'trade-readiness-gate-enabled' (Get-BoolValue $inputs 'InpUseTradeReadinessSafetyGate') 'The source-level trade-readiness gate must be enabled.'
Add-Rule $rows 'tester-only-lock-released-for-demo' (!(Get-BoolValue $inputs 'InpUseResearchTesterOnlyLock')) 'The tester-only lock may be released only for this nonregistered demo draft.'
Add-Rule $rows 'real-account-trading-disabled' (!(Get-BoolValue $inputs 'InpAllowRealAccountTrading')) 'Real-account trading must remain disabled.'
Add-Rule $rows 'symbol-safety-lock' ((Get-BoolValue $inputs 'InpUseSymbolSafetyLock') -and (Get-InputValue $inputs 'InpAllowedSymbol').Length -gt 0) 'Symbol lock and allowed symbol are required.'
Add-Rule $rows 'starting-capital-contract' ((Get-BoolValue $inputs 'InpUseInitialBalanceContract') -and (Get-DoubleValue $inputs 'InpExpectedInitialBalance') -gt 0.0) 'Starting-capital contract is required.'
Add-Rule $rows 'currency-contract' ((Get-BoolValue $inputs 'InpUseAccountCurrencyLock') -and (Get-InputValue $inputs 'InpRequiredAccountCurrency').Length -gt 0) 'Account-currency contract is required.'
Add-Rule $rows 'dedicated-account-contract' (Get-BoolValue $inputs 'InpUseDedicatedAccountContract') 'Dedicated-account contract is required.'
Add-Rule $rows 'funding-drift-contract' (Get-BoolValue $inputs 'InpRejectFundingChangesAfterRegistration') 'Funding-drift contract is required.'
Add-Rule $rows 'real-account-safety-lock' (Get-BoolValue $inputs 'InpUseRealAccountSafetyLock') 'Real-account safety lock is required.'
Add-Rule $rows 'trade-environment-guard' (Get-BoolValue $inputs 'InpUseTradeEnvironmentGuard') 'Trade-environment guard is required.'
Add-Rule $rows 'trade-environment-history' ((Get-IntValue $inputs 'InpTradeEnvMinSignalBars') -ge 250) 'At least 250 signal bars are required.'
$quoteAge = Get-IntValue $inputs 'InpTradeEnvMaxQuoteAgeSeconds'
Add-Rule $rows 'trade-environment-quote-age' ($quoteAge -gt 0 -and $quoteAge -le 60) 'Quote-age cap must be 1-60 seconds.'
$stopsLevel = Get-DoubleValue $inputs 'InpTradeEnvMaxStopsLevelPoints'
Add-Rule $rows 'trade-environment-stop-level' ($stopsLevel -gt 0.0 -and $stopsLevel -le 300.0) 'Stop-level cap must be positive and no more than 300 points.'
$freezeLevel = Get-DoubleValue $inputs 'InpTradeEnvMaxFreezeLevelPoints'
Add-Rule $rows 'trade-environment-freeze-level' ($freezeLevel -gt 0.0 -and $freezeLevel -le 300.0) 'Freeze-level cap must be positive and no more than 300 points.'
Add-Rule $rows 'trade-environment-tick-value' (Get-BoolValue $inputs 'InpTradeEnvRequireTickValue') 'Tick-value validation is required.'

$risk = Get-DoubleValue $inputs 'InpRiskPercent'
Add-Rule $rows 'risk-percent-cap' ($risk -gt 0.0 -and $risk -le $maxRisk) "Risk $risk% must not exceed $maxRisk%."
$effectiveRisk = Get-DoubleValue $inputs 'InpMaxEffectiveRiskPercent'
Add-Rule $rows 'effective-risk-cap' ($effectiveRisk -gt 0.0 -and $effectiveRisk -le $maxRisk) "Effective risk $effectiveRisk% must not exceed $maxRisk%."
$openRisk = Get-DoubleValue $inputs 'InpMaxOpenRiskPercent'
Add-Rule $rows 'open-risk-cap' ($openRisk -gt 0.0 -and $openRisk -le $maxOpenRisk) "Open risk $openRisk% must not exceed $maxOpenRisk%."
$lots = Get-DoubleValue $inputs 'InpMaxPositionLots'
Add-Rule $rows 'position-lot-cap' ($lots -gt 0.0 -and $lots -le $maxLots) "Position cap $lots lots must not exceed $maxLots."
Add-Rule $rows 'simultaneous-position-cap' ((Get-IntValue $inputs 'InpMaxSimultaneousPositions') -le $maxPositions) "Simultaneous positions must not exceed $maxPositions."
Add-Rule $rows 'minimum-lot-overflow-disabled' (!(Get-BoolValue $inputs 'InpAllowMinLotRiskOverflow')) 'Minimum-lot risk overflow must be disabled.'
Add-Rule $rows 'unprotected-exposure-block' (Get-BoolValue $inputs 'InpBlockUnprotectedExposure') 'Unprotected exposure must be blocked.'
Add-Rule $rows 'account-wide-exposure-guard' (Get-BoolValue $inputs 'InpUseAccountWideExposureGuard') 'Account-wide exposure guard is required.'
$accountRisk = Get-DoubleValue $inputs 'InpAccountWideMaxOpenRiskPercent'
Add-Rule $rows 'account-wide-open-risk-cap' ($accountRisk -gt 0.0 -and $accountRisk -le $maxOpenRisk) "Account-wide risk $accountRisk% must not exceed $maxOpenRisk%."
$accountPositions = Get-IntValue $inputs 'InpAccountWideMaxPositions'
Add-Rule $rows 'account-wide-position-cap' ($accountPositions -gt 0 -and $accountPositions -le $maxPositions) "Account-wide positions must be 1-$maxPositions."
Add-Rule $rows 'account-wide-unprotected-block' (Get-BoolValue $inputs 'InpAccountWideBlockUnprotectedExposure') 'Account-wide unprotected exposure must be blocked.'

$dailyLoss = Get-DoubleValue $inputs 'InpMaxDailyLossPercent'
Add-Rule $rows 'daily-loss-cap' ($dailyLoss -gt 0.0 -and $dailyLoss -le (Get-DoubleValue $inputs 'InpTradeReadyMaxDailyLossPercent')) 'Daily loss cap is missing or too high.'
$weeklyLoss = Get-DoubleValue $inputs 'InpMaxWeeklyLossPercent'
Add-Rule $rows 'weekly-loss-cap' ($weeklyLoss -gt 0.0 -and $weeklyLoss -le (Get-DoubleValue $inputs 'InpTradeReadyMaxWeeklyLossPercent')) 'Weekly loss cap is missing or too high.'
$monthlyLoss = Get-DoubleValue $inputs 'InpMaxMonthlyLossPercent'
Add-Rule $rows 'monthly-loss-cap' ($monthlyLoss -gt 0.0 -and $monthlyLoss -le (Get-DoubleValue $inputs 'InpTradeReadyMaxMonthlyLossPercent')) 'Monthly loss cap is missing or too high.'
$drawdown = Get-DoubleValue $inputs 'InpMaxEquityDrawdownPercent'
Add-Rule $rows 'equity-drawdown-cap' ($drawdown -gt 0.0 -and $drawdown -le (Get-DoubleValue $inputs 'InpTradeReadyMaxEquityDrawdownPercent')) 'Equity drawdown cap is missing or too high.'
Add-Rule $rows 'risk-limit-close' (Get-BoolValue $inputs 'InpClosePositionsOnRiskLimit') 'Positions must close on a risk-limit breach.'
Add-Rule $rows 'daily-loss-count-cap' ((Get-IntValue $inputs 'InpMaxDailyLossCount') -le 1) 'Daily loss-count cap must not exceed one.'
Add-Rule $rows 'consecutive-loss-cap' ((Get-IntValue $inputs 'InpMaxConsecutiveLosses') -le 2) 'Consecutive-loss cap must not exceed two.'
Add-Rule $rows 'loss-cooldown' ((Get-IntValue $inputs 'InpCooldownMinutesAfterLoss') -ge 120) 'Loss cooldown must be at least 120 minutes.'
Add-Rule $rows 'loss-streak-risk-reduction' (Get-BoolValue $inputs 'InpUseLossStreakRiskReduction') 'Loss-streak risk reduction is required.'
Add-Rule $rows 'drawdown-risk-reduction' (Get-BoolValue $inputs 'InpUseDrawdownRiskReduction') 'Drawdown risk reduction is required.'
Add-Rule $rows 'drawdown-quality-gate' (Get-BoolValue $inputs 'InpUseDrawdownQualityGate') 'Drawdown quality gate is required.'
Add-Rule $rows 'loss-risk-scaling' ((Get-BoolValue $inputs 'InpUseDailyLossRiskScaling') -and (Get-BoolValue $inputs 'InpUseWeeklyLossRiskScaling') -and (Get-BoolValue $inputs 'InpUseMonthlyLossRiskScaling')) 'Daily, weekly, and monthly loss scaling are required.'
Add-Rule $rows 'profit-locks' ((Get-BoolValue $inputs 'InpUseDailyProfitLock') -and (Get-BoolValue $inputs 'InpUseWeeklyProfitLock') -and (Get-BoolValue $inputs 'InpUseMonthlyProfitLock')) 'Daily, weekly, and monthly profit locks are required.'
Add-Rule $rows 'profit-giveback-guard' (Get-BoolValue $inputs 'InpUseProfitGivebackGuard') 'Profit-giveback guard is required.'

$spreadPoints = Get-DoubleValue $inputs 'InpMaxSpreadPoints'
Add-Rule $rows 'spread-points-cap' ($spreadPoints -gt 0.0 -and $spreadPoints -le (Get-DoubleValue $inputs 'InpTradeReadyMaxSpreadPoints')) 'Spread-points cap is missing or too high.'
$spreadAtr = Get-DoubleValue $inputs 'InpMaxSpreadATRPercent'
Add-Rule $rows 'spread-atr-cap' ($spreadAtr -gt 0.0 -and $spreadAtr -le (Get-DoubleValue $inputs 'InpTradeReadyMaxSpreadATRPercent')) 'Spread-to-ATR cap is missing or too high.'
Add-Rule $rows 'deviation-cap' ((Get-DoubleValue $inputs 'InpDeviationPoints') -le (Get-DoubleValue $inputs 'InpTradeReadyMaxDeviationPoints')) 'Slippage/deviation cap is too high.'
Add-Rule $rows 'spread-adjusted-rr' (Get-BoolValue $inputs 'InpUseSpreadAdjustedRRFilter') 'Spread-adjusted RR filter is required.'
Add-Rule $rows 'spread-guards' ((Get-BoolValue $inputs 'InpUseSpreadRegimeGuard') -and (Get-BoolValue $inputs 'InpUseM1SpreadShockGuard') -and (Get-BoolValue $inputs 'InpUseSpreadRiskScaling')) 'Spread regime, shock, and scaling guards are required.'
Add-Rule $rows 'trading-cost-guard' (Get-BoolValue $inputs 'InpUseTradingCostGuard') 'Trading-cost guard is required.'
Add-Rule $rows 'margin-guards' ((Get-BoolValue $inputs 'InpUseMarginGuard') -and (Get-BoolValue $inputs 'InpUseMarginAwareLotCap') -and (Get-BoolValue $inputs 'InpUseMarginPressureRiskScaling') -and (Get-BoolValue $inputs 'InpUseTradeMarginRiskScaling')) 'All four margin guards are required.'
Add-Rule $rows 'minimum-margin-level' ((Get-DoubleValue $inputs 'InpMinMarginLevelPercent') -ge 500.0) 'Minimum margin level must be at least 500%.'

Add-Rule $rows 'take-profit-enabled' (Get-BoolValue $inputs 'InpUseTakeProfit') 'Take profit is required.'
Add-Rule $rows 'structure-stop-enabled' (Get-BoolValue $inputs 'InpUseStructureStop') 'Structure stop is required.'
Add-Rule $rows 'liquidity-structure-stop' (Get-BoolValue $inputs 'InpUseLiquidityAwareStructureStop') 'Liquidity-aware structure stop is required.'
Add-Rule $rows 'liquidity-stop-conflict' (Get-BoolValue $inputs 'InpUseLiquidityStopConflictGuard') 'Liquidity stop-conflict guard is required.'
Add-Rule $rows 'break-even-enabled' (Get-BoolValue $inputs 'InpUseBreakEven') 'Break-even protection is required.'
Add-Rule $rows 'atr-trailing-enabled' (Get-BoolValue $inputs 'InpUseATRTrailing') 'ATR trailing is required.'
Add-Rule $rows 'mfe-profit-lock' (Get-BoolValue $inputs 'InpUseMFEProfitLockStop') 'MFE profit-lock stop is required.'
Add-Rule $rows 'mfe-giveback-exit' (Get-BoolValue $inputs 'InpUseMFEGivebackExit') 'MFE giveback exit is required.'

Add-Rule $rows 'adaptive-reverse-disabled' (!(Get-BoolValue $inputs 'InpUseAdaptiveReverse')) 'Adaptive Reverse must remain disabled.'
Add-Rule $rows 'scale-in-disabled' (!(Get-BoolValue $inputs 'InpUseWinnerScaleIn') -and !(Get-BoolValue $inputs 'InpUseHouseMoneyScaleInRiskRamp')) 'Scale-in behavior must remain disabled.'
$riskBoost = (Get-BoolValue $inputs 'InpUseProfitOnlyRiskBoost') -or (Get-BoolValue $inputs 'InpUseClosedProfitOpportunityRiskBoost') -or (Get-BoolValue $inputs 'InpUseHouseMoneyAccelerationGate') -or (Get-BoolValue $inputs 'InpUseHouseMoneyOpenRiskExpansion') -or (Get-BoolValue $inputs 'InpUseHotStreakRiskBoost') -or (Get-BoolValue $inputs 'InpUseRecentProfitFactorRiskBoost') -or (Get-BoolValue $inputs 'InpUseProtectedCushionRiskBoost')
Add-Rule $rows 'risk-boosts-disabled' (!$riskBoost) 'Profit- and streak-based risk boosts must remain disabled.'
Add-Rule $rows 'unlimited-runners-disabled' (!(Get-BoolValue $inputs 'InpUseProtectedCushionUnlimitedRunner') -and !(Get-BoolValue $inputs 'InpUseEliteContinuationUnlimitedRunner')) 'Unlimited runners must remain disabled.'
Add-Rule $rows 'fmlr-lane-disabled' (!(Get-BoolValue $inputs 'InpUseFlatMonthLiquidityReclaimLane') -and !(Get-BoolValue $inputs 'InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter')) 'Experimental FMLR behavior must remain disabled.'
Add-Rule $rows 'band-vwap-reversion-disabled' (!(Get-BoolValue $inputs 'InpUseBandVWAPReversionLane')) 'The source gate classifies Band/VWAP reversion as experimental.'
Add-Rule $rows 'tick-speed-impulse-disabled' (!(Get-BoolValue $inputs 'InpUseTickSpeedImpulse')) 'Tick-speed impulse must remain disabled.'

$failed = @($rows | Where-Object { !$_.Pass })
$rows | Export-Csv -LiteralPath $statusCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Forward-Demo Static Readiness Audit', '',
   "**Status: $(if($failed.Count -eq 0){'PASS'}else{'BLOCKED'}).** This mirrors the frozen source's trade-readiness rules and adds the demo-only operational locks.", '',
   "- Profile SHA-256: ``$((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash)``",
   "- Checks: ``$($rows.Count)``",
   "- Blockers: ``$($failed.Count)``",
   "- Failed rules: ``$(if($failed.Count -eq 0){'none'}else{$failed.Rule -join ', '})``", '',
   '| Rule | Pass | Detail |', '|---|---:|---|'
) + @($rows | ForEach-Object { "| $($_.Rule) | $($_.Pass) | $($_.Detail) |" }) |
   Set-Content -LiteralPath $statusMarkdown -Encoding ASCII

[pscustomobject]@{
   Status = if($failed.Count -eq 0) { 'PASS' } else { 'BLOCKED' }
   Pass = $failed.Count -eq 0
   Checks = $rows.Count
   Blockers = $failed.Count
   FailedRules = @($failed | Select-Object -ExpandProperty Rule) -join ';'
   ProfileSha256 = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
}
