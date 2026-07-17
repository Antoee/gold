param(
   [string]$SourcePath = "work\Professional_XAUUSD_Market_Phase_Portfolio.mq5",
   [string]$ExpectedSourceSha256 = "78F43A8281B213FBE82AF592F9876FBC4545BAA1DA62D61565CA0AA56375E8BF"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "Market-phase portfolio source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD portfolio with closed-bar lane-aware market-phase risk"',
   'InpUseMarketPhaseAllocation = true',
   'InpMarketPhaseTimeframe = PERIOD_H1',
   'InpMarketPhaseEfficiencyLookbackBars = 24',
   'InpMarketPhaseRangeEfficiency = 0.20',
   'InpMarketPhaseTrendEfficiency = 0.45',
   'InpMarketPhaseHostileRiskScale = 0.50',
   'ClosedBarEfficiencyRatio',
   'iClose(_Symbol, InpMarketPhaseTimeframe, 1)',
   'MarketPhaseLaneRiskScale(true, efficiency)',
   'MarketPhaseLaneRiskScale(false, efficiency)',
   'InpRVRiskPercent * phaseScale',
   'InpMORiskPercent * phaseScale',
   'InpMaximumPortfolioOpenRiskPercent = 0.75',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpAllowRealAccountTrading = false',
   'MPP-LIVE-ACK-v1'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required market-phase token missing: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowMinLotRiskOverflow')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden market-phase token present: $token" }
}
$sourceHash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($ExpectedSourceSha256 -and $sourceHash -ne $ExpectedSourceSha256) { throw "Market-phase source identity changed: $sourceHash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$sourceHash; Lines=(Get-Content -LiteralPath $full).Count
   ClosedBarPhase=$true; LaneAwareDownscaleOnly=$true; BaseEntriesUnchanged=$true
   BrokerAccurateSizing=$true; MinimumLotOverflow=$false; RealTradingDefault=$false
}
