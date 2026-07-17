param(
   [string]$SourcePath = "work\Professional_XAUUSD_Transferable_Portfolio.mq5",
   [string]$ReleaseSourcePath = "release\transferable-portfolio-v0.1\Professional_XAUUSD_Transferable_Portfolio.mq5"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $source)) { throw "Combined source missing: $source" }
$text = Get-Content -LiteralPath $source -Raw

function Require([string]$Pattern, [string]$Message) {
   if($text -notmatch $Pattern) { throw $Message }
}

function Reject([string]$Pattern, [string]$Message) {
   if($text -match $Pattern) { throw $Message }
}

Require 'input double InpRVRiskPercent = 0\.45;' "Reversion risk default changed."
Require 'input double InpMORiskPercent = 0\.15;' "Momentum risk default changed."
Require 'input double InpMaximumPortfolioOpenRiskPercent = 0\.75;' "Shared open-risk cap changed."
Require 'InpRVRiskPercent \+ InpMORiskPercent > InpMaximumPortfolioOpenRiskPercent' "Requested-risk contract missing."
Require 'OrderCalcProfit\(' "Broker-native risk sizing missing."
Require 'MathFloor\(rawVolume / step' "Round-down volume sizing missing."
Require 'if\(volume < minimum\)\s*return 0\.0;' "No-forced-minimum-lot rule missing."
Require 'ACCOUNT_MARGIN_MODE_RETAIL_HEDGING' "Hedging-account protection missing."
Require 'InpAllowRealAccountTrading = false;' "Real trading is not disabled by default."
Require 'InpRealAccountApprovalCode != "TLP-LIVE-ACK-v1"' "Explicit live approval code missing."
Require 'GlobalVariableSet\(PeakEquityKey\(\), g_peakEquity\)' "Persistent live peak-equity guard missing."
Require 'class CReversionLane' "Reversion module missing."
Require 'class CMomentumLane' "Momentum module missing."
Require 'InpRVMagicNumber = 26071721;' "Reversion magic changed."
Require 'InpMOMagicNumber = 26071761;' "Momentum magic changed."
Require 'InpMOEntryLookbackBars = 20;' "Frozen E20 momentum entry lookback changed."
Require 'InpMOMomentumLookbackBars = 126;' "Frozen momentum lookback changed."
Require 'InpRVUseDIEdgeGate = true;' "Reversion DI gate changed."
Require 'InpRVMinimumDIEdge = -12\.0;' "Reversion DI threshold changed."
Require 'InpBlockUnprotectedAccountExposure = true;' "Unprotected-position block changed."
Require 'InpMaximumPortfolioEquityDrawdownPercent = 5\.00;' "Portfolio drawdown guard changed."

Reject '(?i)martingale|averaging down|recovery sizing' "Prohibited recovery logic found."
Reject 'input\s+(bool|int|double|string)\s+Inp\w*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*' "Calendar-month selector found."
Reject '20\d\d[\.-](0[1-9]|1[0-2])[\.-][0-3]\d' "Hard-coded calendar date found."

$hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$releaseSource = if([IO.Path]::IsPathRooted($ReleaseSourcePath)) { $ReleaseSourcePath } else { Join-Path $repo $ReleaseSourcePath }
$releaseSourceByteMatch = $null
if(Test-Path -LiteralPath $releaseSource -PathType Leaf) {
   $releaseSourceByteMatch = (Get-FileHash -LiteralPath $releaseSource -Algorithm SHA256).Hash -eq $hash
   if(!$releaseSourceByteMatch) { throw "Release source bytes do not match the frozen work source." }
}
[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $hash
   ReleaseSourceByteMatch = $releaseSourceByteMatch
   Lines = (Get-Content -LiteralPath $source).Count
   Modules = 2
   RequestedRiskPercent = 0.60
   OpenRiskCapPercent = 0.75
   DateIndependent = $true
   BrokerAccurateSizing = $true
   RealTradingDefault = $false
}
