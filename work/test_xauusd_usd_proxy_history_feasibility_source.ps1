param(
   [string]$SourcePath = "work\XAUUSD_USD_Proxy_History_Feasibility_Probe.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full)) { throw "USD-proxy history-feasibility source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "No-trading pre-2021 XAUUSD/USD-proxy M15 history-alignment feasibility probe"',
   'InpReferenceSymbol = "EURUSD";',
   'InpSignalTimeframe = PERIOD_M15;',
   'InpUseRealAccountSafetyLock = true;',
   'ACCOUNT_TRADE_MODE_REAL',
   'SymbolSelect(InpReferenceSymbol, true)',
   'iBarShift(InpReferenceSymbol, InpSignalTimeframe, xauTime, false)',
   'FILE_COMMON',
   'alignment_percent',
   'lookback_ready_percent',
   'broker_reference_bars'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) {
      throw "Required USD-proxy feasibility token missing: $token"
   }
}
foreach($token in @('CTrade ', '.Buy(', '.Sell(', 'OrderSend(', 'PositionOpen(', 'OrderCalcMargin(')) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -ge 0) {
      throw "No-trading USD-proxy probe contains forbidden execution token: $token"
   }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
   Lines = (Get-Content -LiteralPath $full).Count
   TradeSymbol = "XAUUSD"
   ReferenceSymbols = "EURUSD;USDJPY"
   Timeframe = "M15"
   SendsOrders = $false
   RealAccountLocked = $true
}
