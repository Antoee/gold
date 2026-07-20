param(
   [string]$SourcePath = "work\Independent_XAUUSD_D1_NR7_H1_Breakout.mq5"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$fullPath = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $fullPath)) { throw "NR7 source missing: $fullPath" }
$source = Get-Content -LiteralPath $fullPath -Raw

function Assert-Contains([string]$Needle, [string]$Message) {
   if(!$source.Contains($Needle)) { throw $Message }
}

Assert-Contains '#property description "Date-independent XAUUSD D1 NR7 compression and H1 breakout research EA"' 'Unexpected strategy identity.'
Assert-Contains 'input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_H1;' 'Signal timeframe must default to H1.'
Assert-Contains 'input int    InpNarrowRangeLookbackDays = 7;' 'NR7 center is missing.'
Assert-Contains 'setupHigh = iHigh(_Symbol, PERIOD_D1, 1);' 'Setup must use the completed D1 bar.'
Assert-Contains 'for(int shift = 2; shift <= lookback; ++shift)' 'Narrow-range comparison must use prior completed D1 bars.'
Assert-Contains 'double close1 = iClose(_Symbol, InpSignalTimeframe, 1);' 'Breakout must use a completed H1 close.'
Assert-Contains 'double close2 = iClose(_Symbol, InpSignalTimeframe, 2);' 'Fresh-breakout check must use completed H1 data.'
Assert-Contains 'OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit)' 'Risk sizing must use broker-native OrderCalcProfit.'
Assert-Contains 'if(volume < minimum)' 'Minimum-lot refusal is missing.'
Assert-Contains 'return 0.0;' 'Minimum-lot refusal must return no volume.'
Assert-Contains 'InpAccountWideBlockUnprotectedExposure = true;' 'Unprotected account exposure must be blocked by default.'
Assert-Contains 'InpAccountWideMaxOpenRiskPercent = 1.00;' 'Account-wide risk cap must default to 1.00%.'
Assert-Contains 'InpMaximumEquityDrawdownPercent = 5.00;' 'Equity drawdown guard must default to 5.00%.'
Assert-Contains 'InpUseRealAccountSafetyLock = true;' 'Real-account safety lock must default on.'
Assert-Contains 'InpAllowRealAccountTrading = false;' 'Real-account trading must default off.'
Assert-Contains 'InpRealAccountApprovalCode != "DNRB-LIVE-ACK"' 'Real-account approval sentinel is missing.'
Assert-Contains 'trade.Buy(lots, _Symbol, 0.0, stopPrice, takeProfit, comment)' 'Buy path must submit its initial stop.'
Assert-Contains 'trade.Sell(lots, _Symbol, 0.0, stopPrice, takeProfit, comment)' 'Sell path must submit its initial stop.'
Assert-Contains 'if(valid && improved)' 'Position management must only tighten stops.'

if(([regex]::Matches($source, '\btrade\.(Buy|Sell)\(')).Count -ne 2) {
   throw 'Expected exactly one buy and one sell order path.'
}
if($source -match 'InpAllowRealAccountTrading\s*=\s*true') { throw 'Real-account default was loosened.' }
if($source -match 'i(?:Open|High|Low|Close|Volume)\(_Symbol,\s*(?:PERIOD_D1|InpSignalTimeframe),\s*0\)') {
   throw 'Entry logic must not inspect an incomplete D1/H1 bar.'
}

[pscustomobject]@{
   Status = 'PASS'
   SourcePath = $fullPath
   SourceSha256 = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
   Checks = 20
}
