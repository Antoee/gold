$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_operational_hardening_rc2_forward_demo_package.ps1") | Out-Null

$candidateDraftPath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_REGISTRATION_DRAFT.json"
$sentinelDraftPath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_REGISTRATION_DRAFT.json"
$manifestPath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PACKAGE_MANIFEST.csv"
$packagePath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PACKAGE.md"
$preflightTestCsvPath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.csv"
$preflightTestMarkdownPath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT_TEST.md"
$forwardProfilePath = Join-Path $repo "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set"
$baseProfilePath = Join-Path $repo "outputs\operational_hardening_rc2_model4_package\profiles\operational_hardening_rc2_rv045_mo015_model4.set"

$candidateDraftBefore = Get-Content -Raw -LiteralPath $candidateDraftPath
$sentinelDraftBefore = Get-Content -Raw -LiteralPath $sentinelDraftPath
$candidateDraft = $candidateDraftBefore | ConvertFrom-Json
$sentinelDraft = $sentinelDraftBefore | ConvertFrom-Json
if($candidateDraft.activationStatus -ne "PREPARED_NOT_REGISTERED" -or $null -ne $candidateDraft.registeredAtLocal -or $null -ne $candidateDraft.initialFundingAdjustmentCount) {
   throw "Candidate draft is already registered or has a funding baseline."
}
if($sentinelDraft.activationStatus -ne "PREPARED_NOT_REGISTERED" -or $null -ne $sentinelDraft.registeredAtLocal) {
   throw "Sentinel draft is already registered."
}
if($candidateDraft.accountIdentifierPublished -or $sentinelDraft.accountIdentifierPublished) {
   throw "Account identifier publication flag changed."
}
foreach($draft in @($candidateDraft, $sentinelDraft)) {
   foreach($forbiddenProperty in @("accountLogin", "accountNumber", "accountId", "brokerServer")) {
      if($draft.PSObject.Properties.Name -contains $forbiddenProperty) { throw "Forbidden identifier property: $forbiddenProperty" }
   }
}

$base = Import-SetInputs -Path $baseProfilePath
$forward = Import-SetInputs -Path $forwardProfilePath
if($base.Keys.Count -ne 105 -or $forward.Keys.Count -ne 105) { throw "RC2 forward input contract changed." }
$allowedDifferences = @("InpEvidenceRunLabel", "InpMOLogFileName", "InpRVLogFileName", "InpShowDashboard")
$changed = @($base.Keys | Where-Object { $base[$_] -ne $forward[$_] } | Sort-Object)
if(Compare-Object -ReferenceObject $allowedDifferences -DifferenceObject $changed) {
   throw "Trading or risk inputs changed: $($changed -join ', ')"
}
if((Get-FileHash -LiteralPath $forwardProfilePath -Algorithm SHA256).Hash -ne $candidateDraft.profileSha256) {
   throw "Candidate forward profile hash mismatch."
}

$manifest = @(Import-Csv -LiteralPath $manifestPath)
if($manifest.Count -ne 9) { throw "Expected 9 forward package artifacts, found $($manifest.Count)." }
foreach($row in $manifest) {
   if([IO.Path]::IsPathRooted($row.Path) -or $row.Path.Contains("..")) { throw "Unsafe manifest path: $($row.Path)" }
   $file = Join-Path $repo ($row.Path -replace '/', '\')
   if(!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Manifest artifact missing: $($row.Path)" }
   if((Get-Item -LiteralPath $file).Length -ne [long]$row.Bytes) { throw "Manifest byte mismatch: $($row.Path)" }
   if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $row.Sha256) { throw "Manifest hash mismatch: $($row.Path)" }
}

$testDir = Join-Path $repo "outputs\operational_hardening_rc2_forward_preflight_test"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
$heartbeatPath = Join-Path $testDir "heartbeat.csv"
$validCsvPath = Join-Path $testDir "valid_gates.csv"
$validMarkdownPath = Join-Path $testDir "valid_preflight.md"
$invalidCsvPath = Join-Path $testDir "wrong_capital_gates.csv"
$invalidMarkdownPath = Join-Path $testDir "wrong_capital_preflight.md"
$missingRVPath = Join-Path $testDir "missing_rv.csv"
$missingMOPath = Join-Path $testDir "missing_mo.csv"

function Write-HeartbeatFixture {
   param([Parameter(Mandatory=$true)][double]$Balance, [Parameter(Mandatory=$true)][double]$Equity)
   $header = @(
      "local_time", "server_time", "run_label", "source_sha256", "profile_sha256",
      "account_trade_mode", "margin_mode", "account_currency", "history_available",
      "funding_adjustment_count", "foreign_trade_count", "connected",
      "terminal_trade_allowed", "account_trade_allowed", "account_expert_allowed",
      "mql_trade_allowed", "expected_symbol", "balance", "equity", "all_positions",
      "candidate_positions", "all_unprotected_positions", "candidate_unprotected_positions",
      "candidate_open_risk_percent"
   )
   $now = Get-Date
   $values = @(
      $now.ToString("yyyy.MM.dd HH:mm:ss"), $now.ToString("yyyy.MM.dd HH:mm:ss"),
      $candidateDraft.runLabel, $candidateDraft.sourceSha256, $candidateDraft.profileSha256,
      "demo", "hedging", "USD", "true", "1", "0", "true",
      "false", "true", "true", "false", "XAUUSD",
      $Balance.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture),
      $Equity.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture),
      "0", "0", "0", "0", "0.0000"
   )
   [IO.File]::WriteAllLines($heartbeatPath, @(($header -join "`t"), ($values -join "`t")), [Text.Encoding]::ASCII)
}

Write-HeartbeatFixture -Balance 10000.0 -Equity 10000.0
$valid = & (Join-Path $PSScriptRoot "check_operational_hardening_rc2_forward_activation.ps1") `
   -HeartbeatPath $heartbeatPath -ReversionLogPath $missingRVPath -MomentumLogPath $missingMOPath `
   -StatusCsvPath $validCsvPath -StatusMarkdownPath $validMarkdownPath
if(!$valid.ReadyToRegister -or $valid.Status -ne "READY_TO_REGISTER") { throw "Valid `$10,000 activation fixture was rejected: $($valid.FailedGates)" }
if([int]$valid.ObservedFundingAdjustmentCount -ne 1) { throw "Valid funding baseline observation mismatch." }

Write-HeartbeatFixture -Balance 100000.0 -Equity 100000.0
$invalid = & (Join-Path $PSScriptRoot "check_operational_hardening_rc2_forward_activation.ps1") `
   -HeartbeatPath $heartbeatPath -ReversionLogPath $missingRVPath -MomentumLogPath $missingMOPath `
   -StatusCsvPath $invalidCsvPath -StatusMarkdownPath $invalidMarkdownPath
if($invalid.ReadyToRegister -or $invalid.Status -ne "REFUSED") { throw "Wrong-capital fixture was not refused." }
if($invalid.FailedGates -notmatch 'starting-balance' -or $invalid.FailedGates -notmatch 'starting-equity') {
   throw "Wrong-capital refusal did not identify balance and equity."
}
if([double]$invalid.ObservedBalance -ne 100000.0) { throw "Wrong-capital observation mismatch." }

@(
   [pscustomobject]@{
      Scenario = "valid_capital_contract"
      Balance = 10000.0
      Equity = 10000.0
      ReadyToRegister = [bool]$valid.ReadyToRegister
      ExpectedReady = $true
      FailedGates = $valid.FailedGates
      RegistrationMutated = $false
      AccountIdentifierPublished = $false
   },
   [pscustomobject]@{
      Scenario = "wrong_capital_contract"
      Balance = 100000.0
      Equity = 100000.0
      ReadyToRegister = [bool]$invalid.ReadyToRegister
      ExpectedReady = $false
      FailedGates = $invalid.FailedGates
      RegistrationMutated = $false
      AccountIdentifierPublished = $false
   }
) | Export-Csv -LiteralPath $preflightTestCsvPath -NoTypeInformation -Encoding ASCII
@(
   "# Operational-Hardening rc2 Forward Preflight Test", "",
   "**PASS.** The deterministic `$10,000 contract fixture passed, while the `$100,000 capital-mismatch fixture was refused before registration.", "",
   "| Scenario | Balance | Equity | Ready to register | Expected | Failed gates |", "|---|---:|---:|---:|---:|---|",
   "| Valid capital | `$10,000 | `$10,000 | $($valid.ReadyToRegister) | True | none |",
   "| Wrong capital | `$100,000 | `$100,000 | $($invalid.ReadyToRegister) | False | $($invalid.FailedGates) |", "",
   "The wrong-capital fixture matches the balance and equity condition measured on the currently attached invalid demo. The test contains no account identifier, creates no registration, freezes no funding-history baseline, and changes no strategy or risk input. It does not count as forward evidence."
) | Set-Content -LiteralPath $preflightTestMarkdownPath -Encoding ASCII

if((Get-Content -Raw -LiteralPath $candidateDraftPath) -ne $candidateDraftBefore) { throw "Test mutated candidate draft." }
if((Get-Content -Raw -LiteralPath $sentinelDraftPath) -ne $sentinelDraftBefore) { throw "Test mutated sentinel draft." }
$publishedText = (Get-Content -Raw -LiteralPath $packagePath) +
   (Get-Content -Raw -LiteralPath $validMarkdownPath) +
   (Get-Content -Raw -LiteralPath $invalidMarkdownPath)
if($publishedText -match '\bACCOUNT_LOGIN\b') { throw "Account login marker leaked into package evidence." }

[pscustomobject]@{
   Status = "PASS"
   ManifestArtifacts = $manifest.Count
   Inputs = $forward.Keys.Count
   TradingRiskInputsChanged = 0
   SentinelTradingPaths = 0
   ValidCapitalReady = [bool]$valid.ReadyToRegister
   WrongCapitalReady = [bool]$invalid.ReadyToRegister
   WrongCapitalFailedGates = $invalid.FailedGates
   RegistrationMutated = $false
   AccountIdentifierPublished = $false
}
