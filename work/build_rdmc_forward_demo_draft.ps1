[CmdletBinding()]
param(
   [string]$SourcePath = 'outputs\rdmc_diversified_repair_executable_gate_package\source\Professional_XAUUSD_EA.mq5',
   [string]$BaseProfilePath = 'outputs\rdmc_diversified_repair_executable_gate_package\profiles\rdmc_diversified_repair_restart_safe_v2.set',
   [string]$ForwardProfilePath = 'outputs\RDMC_FORWARD_DEMO_DRAFT_PROFILE.set',
   [string]$RegistrationPath = 'outputs\RDMC_FORWARD_DEMO_DRAFT_REGISTRATION.json',
   [string]$SentinelProfilePath = 'outputs\RDMC_FORWARD_DEMO_SENTINEL_PROFILE.set',
   [string]$ContractPath = 'outputs\RDMC_FORWARD_DEMO_DRAFT_CONTRACT.md',
   [string]$ManifestPath = 'outputs\RDMC_FORWARD_DEMO_DRAFT_MANIFEST.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceHash = 'EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F'
$expectedBaseProfileHash = '746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883'
$sentinelSourcePath = 'work\Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5'
$expectedSentinelSourceHash = '801229B267FB126878B40F12BE1C833C7A4F381017040726B342CED27F7E46BF'
$runLabel = 'rdmc_diversified_repair_forward_demo_draft_v1'
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
if((Get-FileHash -LiteralPath $sentinelSource -Algorithm SHA256).Hash -ne $expectedSentinelSourceHash) { throw 'Read-only sentinel source identity changed.' }

$base = Import-SetInputs -Path $baseProfile
if($base.Keys.Count -ne 589) { throw "Expected 589 frozen inputs, found $($base.Keys.Count)." }
$draft = @{}
foreach($key in $base.Keys) { $draft[$key] = $base[$key] }
Set-InputLine $draft 'InpUseResearchTesterOnlyLock' 'false'
Set-InputLine $draft 'InpUseTradeReadinessSafetyGate' 'true'
Set-InputLine $draft 'InpLogLevel' '2'
Set-InputLine $draft 'InpLogFileName' 'RDMC_FORWARD_DEMO_TRADES.csv'
Set-InputLine $draft 'InpEvidenceProfileId' 'rdmc_diversified_repair_forward_demo_draft_v1'
Set-InputLine $draft 'InpEvidenceRunLabel' $runLabel
@($draft.Keys | Sort-Object | ForEach-Object { $draft[$_] }) | Set-Content -LiteralPath $forwardProfile -Encoding ASCII

$changed = @($base.Keys | Where-Object { $base[$_] -ne $draft[$_] } | Sort-Object)
if(Compare-Object -ReferenceObject $allowedDifferences -DifferenceObject $changed) {
   throw "Forward draft changed fields outside the operational/evidence allowlist: $($changed -join ', ')"
}
$forwardProfileHash = (Get-FileHash -LiteralPath $forwardProfile -Algorithm SHA256).Hash

$staticCsvPath = 'outputs\RDMC_FORWARD_DEMO_STATIC_READINESS.csv'
$staticMarkdownPath = 'outputs\RDMC_FORWARD_DEMO_STATIC_READINESS.md'
$static = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') `
   -ProfilePath $ForwardProfilePath -StatusCsvPath $staticCsvPath -StatusMarkdownPath $staticMarkdownPath

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
   'InpHeartbeatFileName=RDMC_FORWARD_DEMO_SENTINEL.csv',
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
   heartbeatFile = 'RDMC_FORWARD_DEMO_SENTINEL.csv'
   maximumHeartbeatAgeSeconds = 180
   evidenceLogFile = 'RDMC_FORWARD_DEMO_TRADES.csv'
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
   notes = 'Draft identity only. It contributes zero forward evidence and cannot be registered while any static, executable, stress, broker, binary, account, sentinel, or evidence-log gate fails.'
}
Write-JsonNoBom $draftRegistration $registration

@(
   '# RDMC Forward-Demo Draft Contract', '',
   '**PREPARED, NOT REGISTERED, NOT FORWARD-READY, AND NOT REAL-MONEY APPROVED.**', '',
   'This package derives a demo-only profile from the exact frozen combined-candidate profile. It changes six operational or evidence fields and changes zero strategy or risk fields. It does not modify the currently registered forward candidate.', '',
   '## Frozen identity', '',
   "- Source SHA-256: ``$expectedSourceHash``",
   "- Research profile SHA-256: ``$expectedBaseProfileHash``",
   "- Demo-draft profile SHA-256: ``$forwardProfileHash``",
   "- Run label: ``$runLabel``", '',
   '## Current blockers', '',
   "- Static readiness: ``$($static.Status)``",
   "- Failed static rules: ``$($static.FailedRules)``",
   '- Candidate compiled binary: pending the locked executable gate.',
   '- Primary executable gate: not passed.',
   '- Executable ledger cost and order-aware stress: not passed.',
   '- Distinct-broker gate: not passed.',
   '- Valid clean `$10,000` demo heartbeat: not supplied.', '',
   'The enabled source gate currently rejects the frozen strategy because `InpMaxConsecutiveLosses=4` exceeds its limit of two and `InpUseBandVWAPReversionLane=true` is still classified as experimental. Neither value is changed here because doing so would create a new unvalidated trading path.', '',
   '## Activation boundary', '',
   'Registration remains impossible until the exact compiled candidate passes every executable, stress, and distinct-broker prerequisite; the static source gate reports zero blockers; and a fresh read-only heartbeat proves a clean USD `$10,000` demo hedging account with no positions, foreign trades, or prior evidence events while terminal and MQL algorithmic trading are disabled.', '',
   'No account identifier is stored or published. Real-account trading remains disabled.'
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
