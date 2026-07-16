param([string]$SourcePath = "work\Independent_XAUUSD_H4_Channel_Trend.mq5")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$text = Get-Content -LiteralPath $source -Raw
function Assert-True([bool]$Condition, [string]$Message) { if(!$Condition) { throw $Message } }

foreach($required in @(
   'InpUseRealAccountSafetyLock = true',
   'InpAllowRealAccountTrading = false',
   'InpRiskPercent = 0.10',
   'InpMaximumDailyLossPercent = 0.75',
   'InpMaximumEquityDrawdownPercent = 5.00',
   'InpMaximumSimultaneousPositions = 1',
   'InpMaximumConsecutiveLosses = 4',
   'InpMaximumSpreadPoints = 50.0',
   'InpUseAccountWideExposureGuard = true',
   'InpAccountWideBlockUnprotectedExposure = true',
   'ChannelBounds',
   'RegimeAllows',
   'RiskMoneyForOrder',
   'OrderCalcProfit(orderType, symbol',
   'AccountWideOpenRiskPercent',
   'LotsForRisk',
   'TryChannelExit',
   'ImproveProtectiveStop',
   'OnTradeTransaction',
   'OnTester'
)) {
   Assert-True ($text.Contains($required)) "Required H4 channel source contract is missing: $required"
}

Assert-True ($text -notmatch '(?i)martingale|averaging\s+down|grid\s+recovery') "Prohibited recovery-system text was found."
Assert-True (([regex]::Matches($text, 'InpAllowRealAccountTrading')).Count -ge 2) "Real-account permission must be declared and enforced."

$accountRiskStart = $text.IndexOf('double AccountPositionRiskMoney(')
$accountRiskEnd = $text.IndexOf('double AccountWideOpenRiskPercent(', $accountRiskStart)
Assert-True ($accountRiskStart -ge 0 -and $accountRiskEnd -gt $accountRiskStart) "Account-wide risk helper cannot be isolated."
$accountRiskBlock = $text.Substring($accountRiskStart, $accountRiskEnd - $accountRiskStart)
Assert-True ($accountRiskBlock -notmatch 'POSITION_MAGIC') "Account-wide risk is incorrectly magic-number scoped."

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
   Lines = @(Get-Content -LiteralPath $source).Count
   BrokerAccurateSizing = $true
   AccountWideGuardDefault = $true
   RealTradingDefault = $false
}
