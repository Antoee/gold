param([string]$SourcePath = "work\Independent_XAUUSD_Opening_Range_Breakout.mq5")

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
   'InpMaximumConsecutiveLosses = 3',
   'InpMaximumSpreadPoints = 50.0',
   'GetSessionRange',
   'TrendAllows',
   'VolumeAllows',
   'LotsForRisk',
   'ManagePositions',
   'OnTradeTransaction',
   'OnTester'
)) {
   Assert-True ($text.Contains($required)) "Required ORB source contract is missing: $required"
}
Assert-True ($text -notmatch '(?i)martingale|averaging\s+down|grid\s+recovery') "Prohibited recovery-system text was found."
Assert-True (([regex]::Matches($text, 'InpAllowRealAccountTrading')).Count -ge 2) "Real-account permission must be declared and enforced."

[pscustomobject]@{
   Status = 'PASS'
   SourceSha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
   Lines = @(Get-Content -LiteralPath $source).Count
   DefaultRiskPercent = 0.10
   RealTradingDefault = $false
}
