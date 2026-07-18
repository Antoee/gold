[CmdletBinding()]
param(
   [string]$SourcePath = 'outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5',
   [string]$BaseProfilePath = 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_v1.set',
   [string]$ForwardProfilePath = 'outputs\rdmc_money_ready_gate_repair_package\profiles\rdmc_money_ready_gate_repair_forward_demo_v1.set',
   [string]$RegistrationPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_DRAFT_REGISTRATION.json',
   [string]$SentinelProfilePath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_SENTINEL_PROFILE.set',
   [string]$ContractPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_DRAFT_CONTRACT.md',
   [string]$ManifestPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_DRAFT_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedBaseProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedForwardProfileHash = '816F0FAC4141AB0930A058317C9B5501DC180825B7D8B568BBCE8248D030FA7B'
$expectedPrimaryManifestHash = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'
$expectedSecondBrokerManifestHash = '30A508459E0C408BFF9A905F5C9AEB01AF9D411C39165734F197CC2928CE6CB5'
$sentinelSourcePath = 'work\Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5'
$expectedSentinelSourceHash = '801229B267FB126878B40F12BE1C833C7A4F381017040726B342CED27F7E46BF'
$runLabel = 'rdmc_money_ready_gate_repair_forward_demo_v1'
$allowedDifferences = @(
   'InpEvidenceProfileId', 'InpEvidenceRunLabel', 'InpLogFileName',
   'InpLogLevel', 'InpUseResearchTesterOnlyLock', 'InpUseTradeReadinessSafetyGate'
)

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

function Write-JsonNoBom {
   param([object]$Value, [string]$Path)
   [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
}

$source = Resolve-RepoPath $SourcePath
$baseProfile = Resolve-RepoPath $BaseProfilePath
$forwardProfile = Resolve-RepoPath $ForwardProfilePath
$registration = Resolve-RepoPath $RegistrationPath
$sentinelSource = Resolve-RepoPath $sentinelSourcePath
$sentinelProfile = Resolve-RepoPath $SentinelProfilePath
$contract = Resolve-RepoPath $ContractPath
$manifest = Resolve-RepoPath $ManifestPath

if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $expectedSourceHash) { throw 'Frozen RDMC source identity changed.' }
if((Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash -ne $expectedBaseProfileHash) { throw 'Frozen RDMC profile identity changed.' }
if((Get-FileHash -LiteralPath $forwardProfile -Algorithm SHA256).Hash -ne $expectedForwardProfileHash) { throw 'Frozen RDMC forward profile identity changed.' }
if((Get-FileHash -LiteralPath $sentinelSource -Algorithm SHA256).Hash -ne $expectedSentinelSourceHash) { throw 'Read-only sentinel source identity changed.' }

$base = Import-SetInputs -Path $baseProfile
$draft = Import-SetInputs -Path $forwardProfile
if($base.Keys.Count -ne 589 -or $draft.Keys.Count -ne 589) { throw 'Expected 589 frozen inputs in both successor profiles.' }

$changed = @($base.Keys | Where-Object { !$draft.ContainsKey($_) -or $base[$_] -ne $draft[$_] } | Sort-Object)
$extra = @($draft.Keys | Where-Object { !$base.ContainsKey($_) })
if(Compare-Object -ReferenceObject $allowedDifferences -DifferenceObject $changed) {
   throw "Forward draft changed fields outside the operational/evidence allowlist: $($changed -join ', ')"
}
if($extra.Count -ne 0) { throw "Forward draft added inputs: $($extra -join ', ')" }
$forwardProfileHash = (Get-FileHash -LiteralPath $forwardProfile -Algorithm SHA256).Hash

$staticCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_STATIC_READINESS.csv'
$staticMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_STATIC_READINESS.md'
$static = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') `
   -ProfilePath $ForwardProfilePath -StatusCsvPath $staticCsvPath -StatusMarkdownPath $staticMarkdownPath `
   -AllowValidatedBandVWAPReversion
if(!$static.Pass -or $static.Blockers -ne 0) { throw "Successor static readiness failed: $($static.FailedRules)" }

$magicLine = [string]$draft['InpMagicNumber']
$magic = ($magicLine.Substring($magicLine.IndexOf('=') + 1) -split '\|\|')[0]
@(
   'InpExpectedSymbol=XAUUSD',
   'InpExpectedCurrency=USD',
   "InpPortfolioMagic=$magic",
   "InpRVMagicNumber=$magic",
   "InpMOMagicNumber=$magic",
   "InpRunLabel=$runLabel",
   "InpEvidenceSourceHash=$expectedSourceHash",
   "InpEvidenceProfileHash=$forwardProfileHash",
   'InpHeartbeatFileName=RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_SENTINEL.csv',
   'InpHeartbeatSeconds=60'
) | Set-Content -LiteralPath $sentinelProfile -Encoding ASCII
$sentinelProfileHash = (Get-FileHash -LiteralPath $sentinelProfile -Algorithm SHA256).Hash

$draftRegistration = [ordered]@{
   schemaVersion = 1
   activationStatus = 'PREPARED_NOT_REGISTERED'
   registeredAtLocal = $null
   registeredAtUtc = $null
   initialFundingAdjustmentCount = $null
   accountIdentifierPublished = $false
   expectedAccountMode = 'demo-hedging'
   expectedCurrency = 'USD'
   expectedStartingBalance = 10000.0
   startingBalanceTolerance = 1.0
   expectedSymbol = 'XAUUSD'
   chartTimeframe = 'M15'
   sourcePath = $SourcePath.Replace('\', '/')
   sourceSha256 = $expectedSourceHash
   researchProfilePath = $BaseProfilePath.Replace('\', '/')
   researchProfileSha256 = $expectedBaseProfileHash
   forwardProfilePath = $ForwardProfilePath.Replace('\', '/')
   forwardProfileSha256 = $forwardProfileHash
   primaryExecutableManifestSha256 = $expectedPrimaryManifestHash
   secondBrokerManifestSha256 = $expectedSecondBrokerManifestHash
   runLabel = $runLabel
   candidateBinaryStatus = 'PENDING_EXECUTABLE_GATE'
   candidateBinaryPath = $null
   candidateBinarySha256 = $null
   sentinelSourcePath = $sentinelSourcePath.Replace('\', '/')
   sentinelSourceSha256 = $expectedSentinelSourceHash
   sentinelBinaryStatus = 'PENDING_LOCKED_COMPILE'
   sentinelBinaryPath = $null
   sentinelBinarySha256 = $null
   sentinelProfilePath = $SentinelProfilePath.Replace('\', '/')
   sentinelProfileSha256 = $sentinelProfileHash
   heartbeatFile = 'RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_SENTINEL.csv'
   maximumHeartbeatAgeSeconds = 180
   evidenceLogFile = 'RDMC_MONEY_READY_GATE_REPAIR_FORWARD_TRADES.csv'
   allowedOperationalDifferences = $allowedDifferences
   strategyRiskInputsChanged = 0
   staticReadinessStatus = [string]$static.Status
   staticReadinessBlockers = @(([string]$static.FailedRules -split ';') | Where-Object { $_ })
   prerequisitePrimaryExecutableGate = $false
   prerequisiteExecutableLedgerStress = $false
   prerequisiteDistinctBrokerGate = $false
   minimumCalendarDays = 90
   minimumClosedTrades = 30
   minimumProfitFactor = 1.10
   maximumClosedTradeDrawdownPercent = 5.0
   realAccountTradingAllowed = $false
   notes = 'Successor draft identity only. It contributes zero forward evidence and cannot be registered while any executable, stress, broker, binary, account, sentinel, or evidence-log gate fails.'
}
Write-JsonNoBom $draftRegistration $registration

@(
   '# RDMC Money-Ready Gate-Repair Forward-Demo Draft Contract', '',
   '**PREPARED, NOT REGISTERED, NOT FORWARD-READY, AND NOT REAL-MONEY APPROVED.**', '',
   'This package binds the exact successor source and its already-frozen demo-only profile. It verifies six operational/evidence differences and zero strategy/risk differences. It does not modify or replace the currently registered forward candidate.', '',
   '## Frozen identity', '',
   "- Source SHA-256: ``$expectedSourceHash``",
   "- Research profile SHA-256: ``$expectedBaseProfileHash``",
   "- Demo-draft profile SHA-256: ``$forwardProfileHash``",
   "- Primary executable manifest SHA-256: ``$expectedPrimaryManifestHash``",
   "- Second-broker manifest SHA-256: ``$expectedSecondBrokerManifestHash``",
   "- Run label: ``$runLabel``", '',
   '## Current blockers', '',
   "- Static readiness: ``$($static.Status)``",
   '- Failed static rules: `none`',
   '- Candidate compiled binary: pending the locked executable gate.',
   '- Primary executable gate: not passed.',
   '- Executable ledger cost and order-aware stress: not passed.',
   '- Distinct-broker gate: not passed.',
   '- Valid clean `$10,000` demo heartbeat: not supplied.', '',
   '## Activation boundary', '',
   'Registration remains impossible until the exact compiled candidate passes every executable, stress, and distinct-broker prerequisite; the static source gate reports zero blockers; and a fresh read-only heartbeat proves a clean USD `$10,000` demo hedging account with no positions, foreign trades, or prior evidence events while terminal and MQL algorithmic trading are disabled.', '',
   'The currently attached `$100,000` demo is invalid before its first trade and contributes zero forward days, trades, or P/L. No account identifier is stored or published. Real-account trading remains disabled.'
) | Set-Content -LiteralPath $contract -Encoding ASCII

$artifacts = @(
   $source, $baseProfile, $forwardProfile, $sentinelSource, $sentinelProfile,
   (Resolve-RepoPath $staticCsvPath), (Resolve-RepoPath $staticMarkdownPath),
   $registration, $contract
)
$rows = foreach($path in $artifacts) {
   $resolved = (Resolve-Path -LiteralPath $path).Path
   if(!$resolved.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Artifact outside repository: $resolved" }
   [pscustomobject]@{
      Path = $resolved.Substring($repo.Length + 1).Replace('\', '/')
      Bytes = (Get-Item -LiteralPath $resolved).Length
      Sha256 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = 'PREPARED_NOT_REGISTERED'
   SourceSha256 = $expectedSourceHash
   ResearchProfileSha256 = $expectedBaseProfileHash
   ForwardProfileSha256 = $forwardProfileHash
   ChangedFields = $changed -join ';'
   StrategyRiskInputsChanged = 0
   StaticReadinessStatus = [string]$static.Status
   StaticReadinessBlockers = [string]$static.FailedRules
   CandidateBinaryStatus = 'PENDING_EXECUTABLE_GATE'
   ForwardDays = 0
   ForwardTrades = 0
}
