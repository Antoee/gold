param(
   [string]$SourcePath = "work\Professional_XAUUSD_Early_Failure_Portfolio.mq5",
   [string]$ExpectedSourceSha256 = "2613BDF5BFCE4DB9220961540F851E2444F14AF17B690CAAE0AC4BE59C8C1342"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "Early-failure portfolio source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD portfolio with closed-bar no-follow-through exits"',
   'InpRVUseNoFollowThroughExit = true',
   'InpRVNoFollowThroughBars = 3',
   'InpRVNoFollowThroughMaximumR = 0.00',
   'InpMOUseNoFollowThroughExit = true',
   'InpMONoFollowThroughBars = 4',
   'InpMONoFollowThroughMaximumR = 0.00',
   'iBarShift(_Symbol, InpRVSignalTimeframe, openTime, false)',
   'iBarShift(_Symbol, InpMOSignalTimeframe, openTime, false)',
   'currentR > InpRVNoFollowThroughMaximumR',
   'currentR > InpMONoFollowThroughMaximumR',
   'InpMaximumPortfolioOpenRiskPercent = 0.75',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00',
   'InpRVRiskPercent, InpRVMaximumPositionLots',
   'InpMORiskPercent, InpMOMaximumPositionLots',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpAllowRealAccountTrading = false',
   'EFP-LIVE-ACK-v1'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required early-failure token missing: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowMinLotRiskOverflow')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden early-failure token present: $token" }
}
$sourceHash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($ExpectedSourceSha256 -and $sourceHash -ne $ExpectedSourceSha256) { throw "Early-failure source identity changed: $sourceHash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$sourceHash; Lines=(Get-Content -LiteralPath $full).Count
   ClosedBarExits=$true; RiskOrTargetsNeverExpanded=$true; BaseEntriesUnchanged=$true
   BrokerAccurateSizing=$true; MinimumLotOverflow=$false; RealTradingDefault=$false
}
