param([string]$SourcePath = "work\Independent_XAUUSD_Multiscale_Momentum.mq5")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$text = Get-Content -LiteralPath $source -Raw

function Assert-True([bool]$Condition, [string]$Message) {
   if(!$Condition) { throw $Message }
}

foreach($required in @(
   'InpUseRealAccountSafetyLock = true',
   'InpAllowRealAccountTrading = false',
   'InpMomentumTimeframe = PERIOD_D1',
   'InpSignalTimeframe = PERIOD_H1',
   'InpRiskPercent = 0.10',
   'InpMaximumStopPriceDistance = 10.00',
   'InpMaximumDailyLossPercent = 0.75',
   'InpMaximumEquityDrawdownPercent = 5.00',
   'InpMaximumSimultaneousPositions = 1',
   'InpMaximumConsecutiveLosses = 4',
   'InpUseAccountWideExposureGuard = true',
   'InpAccountWideBlockUnprotectedExposure = true',
   'MomentumDirection',
   'ChannelBounds',
   'RiskMoneyForOrder',
   'OrderCalcProfit(orderType, symbol',
   'AccountWideOpenRiskPercent',
   'LotsForRisk',
   'NormalizeVolume',
   'daily momentum plus fresh H1 breakout',
   'OnTradeTransaction',
   'OnTester'
)) {
   Assert-True ($text.Contains($required)) "Required multiscale source contract is missing: $required"
}

Assert-True ($text -notmatch '(?i)martingale|averaging\s+down|grid\s+recovery') "Prohibited recovery-system text was found."
Assert-True ($text -notmatch 'Inp(Allowed|Blocked)(Year|Month)|InpUse.*(Year|Month).*Filter') "Calendar-fitting input was found."
Assert-True ($text -match 'if\(volume < minimum\)\s*\r?\n\s*return 0\.0;') "Broker minimum lot must be skipped rather than forced."
Assert-True ($text -match 'trade\.PositionModify\(ticket, newSl, takeProfit\)') "Protective-stop updates must preserve take profit."

$accountRiskStart = $text.IndexOf('double AccountPositionRiskMoney(')
$accountRiskEnd = $text.IndexOf('double AccountWideOpenRiskPercent(', $accountRiskStart)
Assert-True ($accountRiskStart -ge 0 -and $accountRiskEnd -gt $accountRiskStart) "Account-wide risk helper cannot be isolated."
$accountRiskBlock = $text.Substring($accountRiskStart, $accountRiskEnd - $accountRiskStart)
Assert-True ($accountRiskBlock -notmatch 'POSITION_MAGIC') "Account-wide risk is incorrectly magic-number scoped."

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
   Lines = @(Get-Content -LiteralPath $source).Count
   DateIndependent = $true
   BrokerAccurateSizing = $true
   RealTradingDefault = $false
}
