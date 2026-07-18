param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$ReleaseSourcePath = "release\transferable-portfolio-v0.2-rc2\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$source = if([IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $repo $SourcePath }
if(!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Hardened source missing: $source" }
$text = Get-Content -LiteralPath $source -Raw

function Require([string]$Pattern, [string]$Message) {
   if($text -notmatch $Pattern) { throw $Message }
}

function Reject([string]$Pattern, [string]$Message) {
   if($text -match $Pattern) { throw $Message }
}

Require '#property version\s+"1\.20"' "Operational version marker changed."
Require 'InpPortfolioMagic = 26071781;' "RC2 portfolio identity changed."
Require 'input double InpRVRiskPercent = 0\.45;' "Reversion risk default changed."
Require 'input double InpMORiskPercent = 0\.15;' "Momentum risk default changed."
Require 'input double InpMaximumPortfolioOpenRiskPercent = 0\.75;' "Open-risk cap changed."
Require 'InpMaximumPortfolioWeeklyLossPercent = 1\.25;' "Weekly loss limit changed."
Require 'InpMaximumPortfolioMonthlyLossPercent = 1\.50;' "Monthly loss limit changed."
Require 'InpMaximumPortfolioConsecutiveLosses = 9;' "Portfolio loss-streak limit changed."
Require 'InpPortfolioLossCooldownHours = 48;' "Portfolio cooldown changed."
Require 'InpMinimumMarginLevelPercent = 300\.0;' "Margin floor changed."
Require 'InpUseInitialBalanceContract = true;' "Starting-capital contract is not enabled."
Require 'InpExpectedInitialBalance = 10000\.0;' "Starting-capital contract changed."
Require 'InpUseAccountCurrencyLock = true;' "Currency lock is not enabled."
Require 'InpRequiredAccountCurrency = "USD";' "Currency contract changed."
Require 'InpUseDedicatedAccountContract = true;' "Dedicated-account contract is not enabled."
Require 'InpRejectFundingChangesAfterRegistration = true;' "Funding-drift contract is not enabled."
Require 'AccountHistoryContractSnapshot\(fundingCount, foreignTradeCount\)' "Account-history snapshot is not enforced."
Require 'dealSymbol != InpAllowedSymbol \|\| !IsPortfolioMagic\(dealMagic\)' "Cross-symbol magic reuse is not rejected."
Require 'account funding changed after registration' "Funding-change lock is missing."
Require 'dedicated-account history contract' "Foreign-trading lock is missing."
Require 'g_accountHistoryStateDirty = true;' "Account-history cache invalidation is missing."
Require 'dealType == DEAL_TYPE_BALANCE' "Balance-operation detection is missing."
Require 'dealType == DEAL_TYPE_COMMISSION_MONTHLY' "Standalone commission detection is missing."
Require 'InpCloseUnprotectedManagedPositions = true;' "Fail-close position protection is not enabled."
Require 'InitialAccountContractAllows\(accountReason\)' "Initialization account contract is not enforced."
Require 'AuditManagedPositionProtection\(\);' "Managed-position protection audit is not called."
Require 'portfolio weekly loss limit' "Weekly safety gate is missing."
Require 'portfolio monthly loss limit' "Monthly safety gate is missing."
Require 'portfolio loss-streak cooldown' "Portfolio loss-streak safety gate is missing."
Require 'minimum margin level' "Margin-level safety gate is missing."
Require 'InpAllowRealAccountTrading = false;' "Real trading is not disabled by default."
Require 'InpRealAccountApprovalCode != "TLP-LIVE-ACK-v1"' "Explicit live approval code is missing."
Require 'ACCOUNT_MARGIN_MODE_RETAIL_HEDGING' "Hedging-account protection is missing."
Require 'OrderCalcProfit\(' "Broker-native risk sizing is missing."

Reject '(?i)martingale|averaging down|recovery sizing' "Prohibited recovery logic found."
Reject 'input\s+(bool|int|double|string)\s+Inp\w*(January|February|March|April|May|June|July|August|September|October|November|December)\w*' "Calendar-month selector found."
Reject '20\d\d[\.-](0[1-9]|1[0-2])[\.-][0-3]\d' "Hard-coded calendar date found."

$hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($hash -ne $expectedHash) { throw "Hardened source identity changed: $hash" }
$releaseSource = if([IO.Path]::IsPathRooted($ReleaseSourcePath)) { $ReleaseSourcePath } else { Join-Path $repo $ReleaseSourcePath }
$releaseSourceByteMatch = $null
if(Test-Path -LiteralPath $releaseSource -PathType Leaf) {
   $releaseSourceByteMatch = (Get-FileHash -LiteralPath $releaseSource -Algorithm SHA256).Hash -eq $hash
   if(!$releaseSourceByteMatch) { throw "Release source bytes do not match the validated work source." }
}

[pscustomobject]@{
   Status = "PASS"
   SourceSha256 = $hash
   ReleaseSourceByteMatch = $releaseSourceByteMatch
   Lines = (Get-Content -LiteralPath $source).Count
   SignalModules = 2
   RequestedRiskPercent = 0.60
   OpenRiskCapPercent = 0.75
   RealTradingDefault = $false
   StartingCapitalContract = 10000
}
