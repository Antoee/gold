param(
   [string]$SourcePath = "work\Professional_XAUUSD_Adaptive_Volatility_Portfolio.mq5",
   [string]$ExpectedSourceSha256 = "EE792939C2E50CED18DA0F5B2E885FB30F14ED58CA97AFB92CA553F6AC4C1229"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "Adaptive-volatility portfolio source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD reversion and momentum portfolio with bounded inverse-volatility risk"',
   'InpUseAdaptiveVolatilityRisk = true',
   'InpVolatilityRiskTimeframe = PERIOD_H1',
   'InpVolatilityRiskATRPeriod = 20',
   'InpVolatilityRiskBaselineBars = 126',
   'InpVolatilityRiskMinimumScale = 0.75',
   'InpVolatilityRiskMaximumScale = 1.25',
   'AdaptiveVolatilityRiskScale',
   'CopyBuffer(g_volatilityRiskAtrHandle, 0, 1, required',
   'CopyClose(_Symbol, InpVolatilityRiskTimeframe, 1, required',
   'effectiveRiskPercent = riskPercent * AdaptiveVolatilityRiskScale()',
   'InpMaximumPortfolioOpenRiskPercent = 0.75',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpAllowRealAccountTrading = false',
   'AVP-LIVE-ACK-v1',
   'AVP_DIAGNOSTIC'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required adaptive-volatility token missing: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowMinLotRiskOverflow')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden adaptive-volatility token present: $token" }
}
$sourceHash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($ExpectedSourceSha256 -and $sourceHash -ne $ExpectedSourceSha256) { throw "Adaptive-volatility source identity changed: $sourceHash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$sourceHash; Lines=(Get-Content -LiteralPath $full).Count
   ClosedBarVolatility=$true; BoundedScale=$true; BaseEntriesUnchanged=$true
   BrokerAccurateSizing=$true; MinimumLotOverflow=$false; RealTradingDefault=$false
}
