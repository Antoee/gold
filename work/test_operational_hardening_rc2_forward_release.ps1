param(
   [string]$ReleasePath = "release\operational-hardening-rc2-forward-prep"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$release = if([IO.Path]::IsPathRooted($ReleasePath)) { $ReleasePath } else { Join-Path $repo $ReleasePath }
if(!(Test-Path -LiteralPath $release -PathType Container)) { throw "Forward release missing: $release" }
$release = (Resolve-Path -LiteralPath $release).Path
$manifest = @(Import-Csv -LiteralPath (Join-Path $release "MANIFEST.csv"))
if($manifest.Count -ne 12) { throw "Expected 12 forward release artifacts, found $($manifest.Count)." }
foreach($row in $manifest) {
   if([IO.Path]::IsPathRooted($row.Path) -or $row.Path.Contains("..")) { throw "Unsafe release path: $($row.Path)" }
   $file = Join-Path $release ($row.Path -replace '/', '\')
   if(!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Release artifact missing: $($row.Path)" }
   if((Get-Item -LiteralPath $file).Length -ne [long]$row.Bytes) { throw "Release byte mismatch: $($row.Path)" }
   if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $row.Sha256) { throw "Release hash mismatch: $($row.Path)" }
}

$candidateSourceHash = (Get-FileHash -LiteralPath (Join-Path $release "Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5") -Algorithm SHA256).Hash
$sentinelSourcePath = Join-Path $release "Professional_XAUUSD_Operational_Hardening_RC2_Forward_Sentinel.mq5"
$sentinelSourceHash = (Get-FileHash -LiteralPath $sentinelSourcePath -Algorithm SHA256).Hash
$candidateProfileHash = (Get-FileHash -LiteralPath (Join-Path $release "OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set") -Algorithm SHA256).Hash
$sentinelProfileHash = (Get-FileHash -LiteralPath (Join-Path $release "OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_PROFILE.set") -Algorithm SHA256).Hash
if($candidateSourceHash -ne "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302") { throw "Candidate source identity mismatch." }
if($sentinelSourceHash -ne "801229B267FB126878B40F12BE1C833C7A4F381017040726B342CED27F7E46BF") { throw "Sentinel source identity mismatch." }
if($candidateProfileHash -ne "8B3A06E9776EA99C1DDE02A14F098B0837653B34B0AAD56491D0FE0248FEEC57") { throw "Candidate profile identity mismatch." }
if($sentinelProfileHash -ne "C89606F2234B786B2C15142BED7BA40AF8EB32A9378CBF8AA35E22EDBBE5C825") { throw "Sentinel profile identity mismatch." }

$candidateDraft = Get-Content -Raw -LiteralPath (Join-Path $release "OPERATIONAL_HARDENING_RC2_FORWARD_REGISTRATION_DRAFT.json") | ConvertFrom-Json
$sentinelDraft = Get-Content -Raw -LiteralPath (Join-Path $release "OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_REGISTRATION_DRAFT.json") | ConvertFrom-Json
if($candidateDraft.activationStatus -ne "PREPARED_NOT_REGISTERED" -or $null -ne $candidateDraft.registeredAtLocal -or $null -ne $candidateDraft.initialFundingAdjustmentCount) {
   throw "Released candidate draft is not pristine."
}
if($sentinelDraft.activationStatus -ne "PREPARED_NOT_REGISTERED" -or $null -ne $sentinelDraft.registeredAtLocal) {
   throw "Released sentinel draft is not pristine."
}
if($candidateDraft.accountIdentifierPublished -or $sentinelDraft.accountIdentifierPublished) { throw "Account identifier publication flag changed." }

$sentinelText = Get-Content -Raw -LiteralPath $sentinelSourcePath
foreach($pattern in @('#include\s+<Trade', '\bCTrade\b', '\bOrderSend(?:Async)?\s*\(', '\.Buy\s*\(', '\.Sell\s*\(', '\bPositionClose\s*\(', '\bPositionModify\s*\(', '\bACCOUNT_LOGIN\b')) {
   if($sentinelText -match $pattern) { throw "Forbidden sentinel pattern: $pattern" }
}
$canary = @(Import-Csv -LiteralPath (Join-Path $release "evidence\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.csv"))
if($canary.Count -ne 2) { throw "Expected two activation canary rows." }
$valid = $canary | Where-Object Scenario -eq "valid_capital_contract"
$wrong = $canary | Where-Object Scenario -eq "wrong_capital_contract"
if($valid.ReadyToRegister -ne "True" -or $wrong.ReadyToRegister -ne "False" -or $wrong.FailedGates -notmatch "starting-balance;starting-equity") {
   throw "Activation canary evidence mismatch."
}
$readme = Get-Content -Raw -LiteralPath (Join-Path $release "README.md")
foreach($marker in @("PREPARED, NOT REGISTERED, AND NOT LIVE-READY", "zero forward days", "not a new profit best", "no valid forward evidence")) {
   if($readme -notmatch [regex]::Escape($marker)) { throw "Forward release safety marker missing: $marker" }
}

[pscustomobject]@{
   Status = "PASS"
   ManifestArtifacts = $manifest.Count
   CandidateSourceSha256 = $candidateSourceHash
   CandidateProfileSha256 = $candidateProfileHash
   SentinelSourceSha256 = $sentinelSourceHash
   SentinelProfileSha256 = $sentinelProfileHash
   WrongCapitalRejected = $true
   RegistrationMutated = $false
   AccountIdentifierPublished = $false
   LiveReady = $false
}
