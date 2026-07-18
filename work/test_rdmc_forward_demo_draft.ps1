$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'build_rdmc_forward_demo_draft.ps1') | Out-Null

$baseProfilePath = Join-Path $repo 'outputs\rdmc_diversified_repair_executable_gate_package\profiles\rdmc_diversified_repair_restart_safe_v2.set'
$forwardProfilePath = Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_DRAFT_PROFILE.set'
$registrationPath = Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_DRAFT_REGISTRATION.json'
$staticCsvPath = Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_STATIC_READINESS.csv'
$manifestPath = Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_DRAFT_MANIFEST.csv'
$testsCsvPath = Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_DRAFT_TESTS.csv'
$testsMarkdownPath = Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_DRAFT_TESTS.md'
$registrationBefore = Get-Content -Raw -LiteralPath $registrationPath
$registration = $registrationBefore | ConvertFrom-Json

if($registration.activationStatus -ne 'PREPARED_NOT_REGISTERED' -or $null -ne $registration.registeredAtLocal -or $null -ne $registration.registeredAtUtc -or $null -ne $registration.initialFundingAdjustmentCount) {
   throw 'The RDMC forward identity is registered or has a funding baseline.'
}
if($registration.accountIdentifierPublished -or $registration.realAccountTradingAllowed) { throw 'A public identifier or real-account permission was enabled.' }
foreach($forbidden in @('accountLogin','accountNumber','accountId','brokerServer','serverName')) {
   if($registration.PSObject.Properties.Name -contains $forbidden) { throw "Forbidden registration property: $forbidden" }
}
if($null -ne $registration.candidateBinaryPath -or $null -ne $registration.candidateBinarySha256) { throw 'An unvalidated candidate binary was frozen.' }

$base = Import-SetInputs -Path $baseProfilePath
$forward = Import-SetInputs -Path $forwardProfilePath
if($base.Keys.Count -ne 589 -or $forward.Keys.Count -ne 589) { throw 'The 589-input profile contract changed.' }
$changed = @($base.Keys | Where-Object { $base[$_] -ne $forward[$_] } | Sort-Object)
$allowed = @('InpEvidenceProfileId','InpEvidenceRunLabel','InpLogFileName','InpLogLevel','InpUseResearchTesterOnlyLock','InpUseTradeReadinessSafetyGate')
if(Compare-Object -ReferenceObject $allowed -DifferenceObject $changed) { throw "Trading or risk inputs changed: $($changed -join ', ')" }
if([int]$registration.strategyRiskInputsChanged -ne 0) { throw 'Strategy/risk change count is not zero.' }

$failedStatic = @(Import-Csv -LiteralPath $staticCsvPath | Where-Object { $_.Pass -eq 'False' } | Select-Object -ExpandProperty Rule | Sort-Object)
$expectedStatic = @('band-vwap-reversion-disabled','consecutive-loss-cap')
if(Compare-Object -ReferenceObject $expectedStatic -DifferenceObject $failedStatic) { throw "Unexpected static blockers: $($failedStatic -join ', ')" }

$manifest = @(Import-Csv -LiteralPath $manifestPath)
if($manifest.Count -ne 9) { throw "Expected 9 manifest artifacts, found $($manifest.Count)." }
foreach($row in $manifest) {
   if([IO.Path]::IsPathRooted($row.Path) -or $row.Path.Contains('..')) { throw "Unsafe manifest path: $($row.Path)" }
   $path = Join-Path $repo ($row.Path -replace '/', '\')
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Manifest artifact missing: $($row.Path)" }
   if((Get-Item -LiteralPath $path).Length -ne [long]$row.Bytes) { throw "Manifest byte mismatch: $($row.Path)" }
   if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $row.Sha256) { throw "Manifest hash mismatch: $($row.Path)" }
}

$testDir = Join-Path ([IO.Path]::GetTempPath()) 'rdmc-forward-demo-draft-tests'
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
$heartbeatPath = Join-Path $testDir 'heartbeat.csv'
$missingEvidencePath = Join-Path $testDir 'missing-evidence.csv'
$statusCsvPath = Join-Path $testDir 'preflight.csv'
$statusMarkdownPath = Join-Path $testDir 'preflight.md'

function Write-HeartbeatFixture {
   param(
      [double]$Balance,
      [double]$Equity,
      [string]$SourceHash = $registration.sourceSha256,
      [datetime]$LocalTime = (Get-Date)
   )
   $header = @(
      'local_time','server_time','run_label','source_sha256','profile_sha256',
      'account_trade_mode','margin_mode','account_currency','history_available',
      'funding_adjustment_count','foreign_trade_count','connected',
      'terminal_trade_allowed','account_trade_allowed','account_expert_allowed',
      'mql_trade_allowed','expected_symbol','balance','equity','all_positions',
      'candidate_positions','all_unprotected_positions','candidate_unprotected_positions',
      'candidate_open_risk_percent'
   )
   $timeText = $LocalTime.ToString('yyyy.MM.dd HH:mm:ss')
   $values = @(
      $timeText,$timeText,$registration.runLabel,$SourceHash,$registration.forwardProfileSha256,
      'demo','hedging','USD','true','1','0','true',
      'false','true','true','false','XAUUSD',
      $Balance.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture),
      $Equity.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture),
      '0','0','0','0','0.0000'
   )
   [IO.File]::WriteAllLines($heartbeatPath, @(($header -join "`t"), ($values -join "`t")), [Text.Encoding]::ASCII)
}

function Invoke-TestPreflight {
   return & (Join-Path $PSScriptRoot 'check_rdmc_forward_demo_activation.ps1') `
      -HeartbeatPath $heartbeatPath -EvidenceLogPath $missingEvidencePath `
      -StatusCsvPath $statusCsvPath -StatusMarkdownPath $statusMarkdownPath
}

Write-HeartbeatFixture -Balance 10000.0 -Equity 10000.0
$validAccount = Invoke-TestPreflight
if($validAccount.ReadyToRegister -or $validAccount.Status -ne 'REFUSED') { throw 'The valid-account fixture bypassed unresolved prerequisites.' }
if($validAccount.FailedGates -match 'starting-balance|starting-equity|heartbeat-identity') { throw "The valid-account fixture failed an unexpected account gate: $($validAccount.FailedGates)" }
foreach($requiredBlock in @('static-trade-readiness','primary-executable-gate','executable-ledger-stress','distinct-broker-gate','candidate-compiled-binary','sentinel-compiled-binary')) {
   if($validAccount.FailedGates -notmatch [regex]::Escape($requiredBlock)) { throw "Unresolved prerequisite was not enforced: $requiredBlock" }
}

Write-HeartbeatFixture -Balance 100000.0 -Equity 100000.0
$wrongCapital = Invoke-TestPreflight
if($wrongCapital.ReadyToRegister -or $wrongCapital.FailedGates -notmatch 'starting-balance' -or $wrongCapital.FailedGates -notmatch 'starting-equity') {
   throw 'The wrong-capital fixture was not refused by both capital gates.'
}

Write-HeartbeatFixture -Balance 10000.0 -Equity 10000.0 -SourceHash ('0' * 64)
$wrongIdentity = Invoke-TestPreflight
if($wrongIdentity.ReadyToRegister -or $wrongIdentity.FailedGates -notmatch 'heartbeat-identity') { throw 'The wrong-identity fixture was not refused.' }

Write-HeartbeatFixture -Balance 10000.0 -Equity 10000.0 -LocalTime ((Get-Date).AddHours(-1))
$staleHeartbeat = Invoke-TestPreflight
if($staleHeartbeat.ReadyToRegister -or $staleHeartbeat.FailedGates -notmatch 'heartbeat-fresh') { throw 'The stale-heartbeat fixture was not refused.' }

$scenarios = @(
   [pscustomobject]@{Scenario='clean_10000_but_prerequisites_pending';ReadyToRegister=[bool]$validAccount.ReadyToRegister;ExpectedReady=$false;RequiredFailure='static/executable/stress/broker/binaries';Pass=$true},
   [pscustomobject]@{Scenario='wrong_100000_capital';ReadyToRegister=[bool]$wrongCapital.ReadyToRegister;ExpectedReady=$false;RequiredFailure='starting-balance;starting-equity';Pass=$true},
   [pscustomobject]@{Scenario='wrong_candidate_identity';ReadyToRegister=[bool]$wrongIdentity.ReadyToRegister;ExpectedReady=$false;RequiredFailure='heartbeat-identity';Pass=$true},
   [pscustomobject]@{Scenario='stale_sentinel_heartbeat';ReadyToRegister=[bool]$staleHeartbeat.ReadyToRegister;ExpectedReady=$false;RequiredFailure='heartbeat-fresh';Pass=$true}
)
$scenarios | Export-Csv -LiteralPath $testsCsvPath -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Forward-Demo Draft Tests', '',
   '**PASS.** Four deterministic activation scenarios were refused for the intended reasons, and the draft changed zero strategy/risk inputs.', '',
   "- Frozen profile inputs: ``$($forward.Keys.Count)``",
   "- Allowed operational/evidence differences: ``$($changed.Count)``",
   '- Strategy/risk differences: `0`',
   "- Static readiness blockers: ``$($failedStatic -join ', ')``",
   "- Manifest artifacts verified: ``$($manifest.Count)``", '',
   '| Scenario | Ready | Expected | Required refusal | Pass |', '|---|---:|---:|---|---:|'
) + @($scenarios | ForEach-Object { "| $($_.Scenario) | $($_.ReadyToRegister) | $($_.ExpectedReady) | $($_.RequiredFailure) | $($_.Pass) |" }) + @('',
   'The clean `$10,000` fixture remains refused because research, binary, stress, broker, and static-readiness prerequisites are incomplete. The `$100,000` fixture also fails both capital gates. No registration, funding baseline, account identifier, forward day, or forward trade was created.'
) | Set-Content -LiteralPath $testsMarkdownPath -Encoding ASCII

if((Get-Content -Raw -LiteralPath $registrationPath) -ne $registrationBefore) { throw 'Tests mutated the registration draft.' }

[pscustomobject]@{
   Status = 'PASS'
   Scenarios = $scenarios.Count
   Inputs = $forward.Keys.Count
   OperationalEvidenceDifferences = $changed.Count
   StrategyRiskInputsChanged = 0
   StaticReadinessBlockers = $failedStatic -join ';'
   ManifestArtifacts = $manifest.Count
   RegistrationMutated = $false
   AccountIdentifierPublished = $false
   ForwardDays = 0
   ForwardTrades = 0
}
