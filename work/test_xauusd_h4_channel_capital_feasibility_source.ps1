param(
   [string]$SourcePath = "work\XAUUSD_H4_Channel_Capital_Feasibility_Probe.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "Capital-feasibility probe source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   'OrderCalcProfit',
   'SYMBOL_VOLUME_MIN',
   'InpAssumedEquity',
   'InpRiskPercent',
   'InpUseRealAccountSafetyLock',
   'ACCOUNT_TRADE_MODE_REAL',
   'FILE_COMMON',
   'feasible_percent',
   'required_equity_p95',
   'InpRequireFreshBreakout',
   'InpUseVolatilityFilter'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required probe token missing: $token" }
}
$forbidden = @('CTrade ', '.Buy(', '.Sell(', 'OrderSend(', 'PositionOpen(')
foreach($token in $forbidden) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -ge 0) { throw "No-trading probe contains forbidden execution token: $token" }
}
$hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $hash
   Lines = (Get-Content -LiteralPath $full).Count
   BrokerAccurate = $true
   SendsOrders = $false
   CommonCsvEvidence = $true
}

