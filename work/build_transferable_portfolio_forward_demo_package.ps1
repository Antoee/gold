param(
   [string]$SourcePath = "work\Professional_XAUUSD_Transferable_Portfolio.mq5",
   [string]$BaseProfilePath = "outputs\TRANSFERABLE_PORTFOLIO_BASE_PROFILE.set",
   [string]$ForwardProfilePath = "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set",
   [string]$MarkdownPath = "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$baseFull = (Resolve-Path -LiteralPath (Join-Path $repo $BaseProfilePath)).Path
$forwardFull = Join-Path $repo $ForwardProfilePath
$expectedSourceHash = "5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3"
$expectedBaseHash = "ECBD1693D09AF6A04CB92F2756442DF8BF0B604118834D1C5E0F50CC57FFEC3E"

$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$baseHash = (Get-FileHash -LiteralPath $baseFull -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Frozen source changed: $sourceHash" }
if($baseHash -ne $expectedBaseHash) { throw "Frozen base profile changed: $baseHash" }

$inputs = Import-SetInputs -Path $baseFull
if($inputs.Keys.Count -ne 92) { throw "Frozen input contract changed: $($inputs.Keys.Count)" }
$inputs["InpLogTrades"] = "InpLogTrades=true||true||0||0||N"
$inputs["InpRVLogFileName"] = "InpRVLogFileName=TRANSFERABLE_FORWARD_RV_EVENTS.csv"
$inputs["InpMOLogFileName"] = "InpMOLogFileName=TRANSFERABLE_FORWARD_MO_EVENTS.csv"
$inputs["InpEvidenceRunLabel"] = "InpEvidenceRunLabel=frozen_forward_20260717"
$inputs["InpShowDashboard"] = "InpShowDashboard=true||true||0||0||N"
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $forwardFull -Encoding ASCII
$profileHash = (Get-FileHash -LiteralPath $forwardFull -Algorithm SHA256).Hash

@(
   "# Transferable Portfolio Forward Demo Package", "",
   "Prepared for a frozen MetaQuotes-Demo hedging-account forward observation beginning after the 2026-07-16 research cutoff.", "",
   '**Current observation status: invalid before first trade.** The read-only sentinel measured a `$100,000` demo balance while the frozen registration requires `$10,000`. The unchanged candidate must be moved to a correctly capitalized demo account and newly preregistered before the forward clock starts.', "",
   "- Source SHA-256: $sourceHash",
   "- Base profile SHA-256: $baseHash",
   "- Forward profile SHA-256: $profileHash",
   "- EA filename: Professional_XAUUSD_Transferable_Portfolio.ex5",
   "- Attached chart: XAUUSD M15 (both strategy lanes calculate signals on H1)",
   "- Forward event logs: TRANSFERABLE_FORWARD_RV_EVENTS.csv and TRANSFERABLE_FORWARD_MO_EVENTS.csv",
   "- Required starting balance: `$10,000 (+/- `$1 before any trade)",
   "- Shared maximum open risk: 0.75%",
   "- Read-only sentinel: Professional_XAUUSD_Forward_Sentinel.ex5 on an auxiliary chart",
   "- Sentinel heartbeat: TRANSFERABLE_FORWARD_SENTINEL.csv (account identifier excluded)",
   "- Real-account trading remains disabled and the real-account safety lock remains enabled.",
   "- Trading rules and risk inputs are identical to the released v0.1 profile; only logging, dashboard, and run-label fields differ."
) | Set-Content -LiteralPath (Join-Path $repo $MarkdownPath) -Encoding ASCII

[pscustomobject]@{Status="READY";Inputs=$inputs.Keys.Count;SourceSha256=$sourceHash;BaseProfileSha256=$baseHash;ForwardProfileSha256=$profileHash}
