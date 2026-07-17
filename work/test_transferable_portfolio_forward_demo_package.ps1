$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_transferable_portfolio_forward_demo_package.ps1") | Out-Null
$source = Join-Path $repo "work\Professional_XAUUSD_Transferable_Portfolio.mq5"
$basePath = Join-Path $repo "outputs\TRANSFERABLE_PORTFOLIO_BASE_PROFILE.set"
$forwardPath = Join-Path $repo "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set"
$base = Import-SetInputs -Path $basePath
$forward = Import-SetInputs -Path $forwardPath
if($base.Keys.Count -ne 92 -or $forward.Keys.Count -ne 92) { throw "Forward input contract changed." }
$allowedDifferences = @("InpLogTrades", "InpRVLogFileName", "InpMOLogFileName", "InpEvidenceRunLabel", "InpShowDashboard")
foreach($key in $base.Keys) {
   if($allowedDifferences -contains $key) { continue }
   if($forward[$key] -ne $base[$key]) { throw "Trading/risk input changed for forward demo: $key" }
}
if($forward["InpLogTrades"] -notmatch '=true\|\|') { throw "Forward logging disabled." }
if($forward["InpShowDashboard"] -notmatch '=true\|\|') { throw "Forward dashboard disabled." }
if($forward["InpAllowRealAccountTrading"] -match '=true') { throw "Real-account trading enabled." }
if($forward["InpUseRealAccountSafetyLock"] -notmatch '=true\|\|') { throw "Real-account safety lock disabled." }
if($forward["InpRequireHedgingAccount"] -notmatch '=true\|\|') { throw "Hedging-account requirement disabled." }
if($forward["InpEvidenceSourceHash"] -notmatch '5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3') { throw "Evidence source identity changed." }
if($forward["InpEvidenceRunLabel"] -ne "InpEvidenceRunLabel=frozen_forward_20260717") { throw "Forward run label changed." }

[pscustomobject]@{
   Status="PASS";Inputs=$forward.Keys.Count;TradingInputsChanged=0
   SourceSha256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
   ForwardProfileSha256=(Get-FileHash -LiteralPath $forwardPath -Algorithm SHA256).Hash
   RealTradingDefault=$false;HedgingRequired=$true
}
