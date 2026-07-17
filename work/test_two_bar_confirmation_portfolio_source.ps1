param(
   [string]$SourcePath = "work\Professional_XAUUSD_Two_Bar_Confirmation_Portfolio.mq5",
   [string]$ExpectedSourceSha256 = "A5462DA021E57A8FB42BA6344D89BE366204130DE1A47957F5EF988861DAD133"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$full = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "Two-bar confirmation source missing: $full" }
$text = Get-Content -LiteralPath $full -Raw
$required = @(
   '#property description "Date-independent XAUUSD portfolio with closed-bar two-step entry confirmation"',
   'InpRVUseTwoBarReclaimConfirmation = true',
   'InpRVRequirePriorCloseOutsideBand = false',
   'InpRVRequireConfirmationProgress = true',
   'InpMOUseTwoCloseBreakoutConfirmation = true',
   'InpMORequireConfirmationProgress = false',
   'BufferValue(m_bandsHandle, 1, 2, upper2)',
   'priorBuyExtension = low2 <= lower2 - penetration',
   'priorSellExtension = high2 >= upper2 + penetration',
   'ChannelBounds(3, InpMOEntryLookbackBars, channelHigh, channelLow)',
   'close2 > channelHigh + buffer && close1 > channelHigh + buffer',
   'close2 < channelLow - buffer && close1 < channelLow - buffer',
   'InpMaximumPortfolioOpenRiskPercent = 0.75',
   'InpMaximumPortfolioEquityDrawdownPercent = 5.00',
   'OrderCalcProfit',
   'if(volume < minimum)',
   'InpAllowRealAccountTrading = false',
   'TBC-LIVE-ACK-v1'
)
foreach($token in $required) {
   if($text.IndexOf($token, [StringComparison]::Ordinal) -lt 0) { throw "Required two-bar confirmation token missing: $token" }
}
foreach($token in @('martingale','averaging down','grid recovery','InpAllowMinLotRiskOverflow')) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "Forbidden two-bar confirmation token present: $token" }
}
$sourceHash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
if($ExpectedSourceSha256 -and $sourceHash -ne $ExpectedSourceSha256) { throw "Two-bar confirmation source identity changed: $sourceHash" }
[pscustomobject]@{
   Status="PASS"; SourceSha256=$sourceHash; Lines=(Get-Content -LiteralPath $full).Count
   ClosedBarConfirmation=$true; BaseRiskUnchanged=$true; BrokerAccurateSizing=$true
   MinimumLotOverflow=$false; RealTradingDefault=$false
}
