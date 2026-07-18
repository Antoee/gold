param(
   [string]$CandidateSourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$CandidateBinaryPath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.ex5",
   [string]$CandidateProfilePath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set",
   [string]$SentinelSourcePath = "work\Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5",
   [string]$SentinelBinaryPath = "work\Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.ex5",
   [string]$SentinelProfilePath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_PROFILE.set",
   [string]$CandidateRegistrationPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_REGISTRATION_DRAFT.json",
   [string]$SentinelRegistrationPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_REGISTRATION_DRAFT.json",
   [string]$MarkdownPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PACKAGE.md",
   [string]$ManifestPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PACKAGE_MANIFEST.csv"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedCandidateSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$expectedCandidateBinaryHash = "710C20730933E6EB2AE1AD14079C67E33C592881E1471BF0110E045335153EE5"
$expectedCandidateProfileHash = "8B3A06E9776EA99C1DDE02A14F098B0837653B34B0AAD56491D0FE0248FEEC57"
$expectedSentinelSourceHash = "801229B267FB126878B40F12BE1C833C7A4F381017040726B342CED27F7E46BF"
$expectedSentinelBinaryHash = "6E7067BD1DFE9CDC96F012D7FDABE379B2149FDA075C0B7FD12A8DE2CB06B3C0"
$runLabel = "operational_hardening_rc2_forward_frozen"

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

function Assert-Hash {
   param(
      [Parameter(Mandatory=$true)][string]$Path,
      [Parameter(Mandatory=$true)][string]$Expected,
      [Parameter(Mandatory=$true)][string]$Label
   )
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Label missing: $Path" }
   $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
   if($actual -ne $Expected) { throw "$Label identity changed: $actual" }
}

function Write-JsonNoBom {
   param([Parameter(Mandatory=$true)][object]$Value, [Parameter(Mandatory=$true)][string]$Path)
   $json = ($Value | ConvertTo-Json -Depth 8) + [Environment]::NewLine
   [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

& (Join-Path $PSScriptRoot "build_operational_hardening_rc2_forward_profile.ps1") | Out-Null
& (Join-Path $PSScriptRoot "test_operational_hardening_rc2_forward_sentinel_source.ps1") | Out-Null

$candidateSource = Resolve-RepoPath $CandidateSourcePath
$candidateBinary = Resolve-RepoPath $CandidateBinaryPath
$candidateProfile = Resolve-RepoPath $CandidateProfilePath
$sentinelSource = Resolve-RepoPath $SentinelSourcePath
$sentinelBinary = Resolve-RepoPath $SentinelBinaryPath
$sentinelProfile = Resolve-RepoPath $SentinelProfilePath
$candidateRegistration = Resolve-RepoPath $CandidateRegistrationPath
$sentinelRegistration = Resolve-RepoPath $SentinelRegistrationPath
$markdown = Resolve-RepoPath $MarkdownPath
$manifest = Resolve-RepoPath $ManifestPath

Assert-Hash $candidateSource $expectedCandidateSourceHash "Candidate source"
Assert-Hash $candidateBinary $expectedCandidateBinaryHash "Candidate binary"
Assert-Hash $candidateProfile $expectedCandidateProfileHash "Candidate forward profile"
Assert-Hash $sentinelSource $expectedSentinelSourceHash "Sentinel source"
Assert-Hash $sentinelBinary $expectedSentinelBinaryHash "Sentinel binary"

@(
   "InpExpectedSymbol=XAUUSD",
   "InpExpectedCurrency=USD",
   "InpPortfolioMagic=26071781",
   "InpRVMagicNumber=26071721",
   "InpMOMagicNumber=26071761",
   "InpRunLabel=$runLabel",
   "InpEvidenceSourceHash=$expectedCandidateSourceHash",
   "InpEvidenceProfileHash=$expectedCandidateProfileHash",
   "InpHeartbeatFileName=OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL.csv",
   "InpHeartbeatSeconds=60"
) | Set-Content -LiteralPath $sentinelProfile -Encoding ASCII
$sentinelProfileHash = (Get-FileHash -LiteralPath $sentinelProfile -Algorithm SHA256).Hash

$candidateDraft = [ordered]@{
   schemaVersion = 2
   activationStatus = "PREPARED_NOT_REGISTERED"
   registeredAtLocal = $null
   registeredAtUtc = $null
   accountIdentifierPublished = $false
   expectedAccountMode = "demo-hedging"
   expectedCurrency = "USD"
   expectedStartingBalance = 10000.0
   startingBalanceTolerance = 1.0
   expectedSymbol = "XAUUSD"
   chartTimeframe = "M15"
   signalTimeframe = "H1"
   sourcePath = $CandidateSourcePath.Replace('\', '/')
   sourceSha256 = $expectedCandidateSourceHash
   binaryPath = $CandidateBinaryPath.Replace('\', '/')
   binarySha256 = $expectedCandidateBinaryHash
   profilePath = $CandidateProfilePath.Replace('\', '/')
   profileSha256 = $expectedCandidateProfileHash
   runLabel = $runLabel
   portfolioMagic = 26071781
   reversionMagic = 26071721
   momentumMagic = 26071761
   reversionLogFile = "OPERATIONAL_HARDENING_RC2_FORWARD_RV_EVENTS.csv"
   momentumLogFile = "OPERATIONAL_HARDENING_RC2_FORWARD_MO_EVENTS.csv"
   initialFundingAdjustmentCount = $null
   requiredForeignTradeCount = 0
   minimumCalendarDays = 90
   minimumClosedTrades = 30
   minimumProfitFactor = 1.10
   maximumClosedTradeDrawdownPercent = 5.0
   maximumConsecutiveLosses = 12
   maximumPortfolioOpenRiskPercent = 0.75
   realAccountTradingAllowed = $false
   notes = "Prepared identity only. It is not a registration and contributes zero forward days or trades. Freeze the funding-history baseline only after the activation preflight passes on a fresh USD 10000 demo hedging account with trading disabled."
}
Write-JsonNoBom $candidateDraft $candidateRegistration

$sentinelDraft = [ordered]@{
   schemaVersion = 2
   activationStatus = "PREPARED_NOT_REGISTERED"
   registeredAtLocal = $null
   accountIdentifierPublished = $false
   attachedChart = "auxiliary-chart"
   sourcePath = $SentinelSourcePath.Replace('\', '/')
   sourceSha256 = $expectedSentinelSourceHash
   binaryPath = $SentinelBinaryPath.Replace('\', '/')
   binarySha256 = $expectedSentinelBinaryHash
   profilePath = $SentinelProfilePath.Replace('\', '/')
   profileSha256 = $sentinelProfileHash
   heartbeatFile = "OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL.csv"
   maximumHeartbeatAgeSeconds = 180
   runLabel = $runLabel
   candidateSourceSha256 = $expectedCandidateSourceHash
   candidateProfileSha256 = $expectedCandidateProfileHash
   expectedSymbol = "XAUUSD"
   expectedCurrency = "USD"
   nonTrading = $true
   notes = "Read-only activation heartbeat. No account identifier, order send, close, or modify path is permitted."
}
Write-JsonNoBom $sentinelDraft $sentinelRegistration

@(
   "# Operational-Hardening rc2 Forward Package", "",
   "## State", "",
   "**PREPARED, NOT REGISTERED, AND NOT LIVE-READY.** This package contributes zero forward days and zero forward trades. It does not alter the frozen v0.1 registration or evidence.", "",
   "The currently attached `$100,000 demo account violates the required `$10,000 starting-capital contract and must be rejected before registration. The profile, source, run label, and evidence files must never be amended to make that account pass.", "",
   "## Frozen identity", "",
   "- Candidate source SHA-256: ``$expectedCandidateSourceHash``",
   "- Candidate binary SHA-256: ``$expectedCandidateBinaryHash``",
   "- Candidate forward profile SHA-256: ``$expectedCandidateProfileHash``",
   "- Sentinel source SHA-256: ``$expectedSentinelSourceHash``",
   "- Sentinel binary SHA-256: ``$expectedSentinelBinaryHash``",
   "- Sentinel profile SHA-256: ``$sentinelProfileHash``",
   "- Run label: ``$runLabel``", "",
   "## Activation contract", "",
   "Registration may be created only after the read-only preflight proves: demo hedging mode; USD currency; `$10,000 balance and equity within `$1; clean accessible account history; zero foreign trades; zero positions and open risk; fresh exact-identity sentinel heartbeat; empty dedicated evidence logs; and terminal/MQL algorithmic trading disabled.", "",
   "The funding-history count measured at that moment becomes the immutable account baseline. Any later funding-count change or unrelated trading locks the candidate. Real-account trading remains disabled.", "",
   "## Evidence status", "",
   'The strategy result is unchanged: Model4 real ticks 2015-2026 net `+$1,615.36`, profit factor `1.58`, `362` trades, and `2.83%` maximum drawdown. This package improves operational controls; it is not a new profit best and has no valid forward evidence yet.'
) | Set-Content -LiteralPath $markdown -Encoding ASCII

$artifactPaths = @(
   $candidateSource,
   $sentinelSource,
   $candidateProfile,
   $sentinelProfile,
   (Resolve-RepoPath "outputs\OPERATIONAL_HARDENING_RC2_COMPILE.log"),
   (Resolve-RepoPath "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_COMPILE.log"),
   $candidateRegistration,
   $sentinelRegistration,
   $markdown
)
$rows = foreach($path in $artifactPaths) {
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Manifest artifact missing: $path" }
   $resolvedPath = (Resolve-Path -LiteralPath $path).Path
   if(!$resolvedPath.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
      throw "Manifest artifact is outside the workspace: $resolvedPath"
   }
   $relative = $resolvedPath.Substring($repo.Length + 1).Replace('\', '/')
   [pscustomobject]@{
      Path = $relative
      Bytes = (Get-Item -LiteralPath $path).Length
      Sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
   }
}
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   Status = "PREPARED_NOT_REGISTERED"
   CandidateSourceSha256 = $expectedCandidateSourceHash
   CandidateProfileSha256 = $expectedCandidateProfileHash
   SentinelSourceSha256 = $expectedSentinelSourceHash
   SentinelProfileSha256 = $sentinelProfileHash
   ManifestArtifacts = $rows.Count
   ForwardDays = 0
   ForwardTrades = 0
}
