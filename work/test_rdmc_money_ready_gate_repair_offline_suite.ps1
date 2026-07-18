[CmdletBinding()]
param(
   [switch]$SkipCleanWorktreeCheck
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedWork = Split-Path -Parent $repo
$summaryCsv = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_OFFLINE_AUDIT.csv'
$summaryMarkdown = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_OFFLINE_AUDIT.md'
$expectedSourceHash = '104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8'
$expectedProfileHash = '8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E'
$expectedForwardProfileHash = '816F0FAC4141AB0930A058317C9B5501DC180825B7D8B568BBCE8248D030FA7B'
$expectedManifestHash = 'EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972'
$expectedSecondBrokerManifestHash = '30A508459E0C408BFF9A905F5C9AEB01AF9D411C39165734F197CC2928CE6CB5'

function Get-WorktreeStatus {
   $status = @(& git -C $repo status --porcelain=v1 --untracked-files=all)
   if($LASTEXITCODE -ne 0) { throw 'Unable to inspect the Git worktree.' }
   return $status
}

function Import-OneCsvRow {
   param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)][string]$Label)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Label is missing: $Path" }
   $rows = @(Import-Csv -LiteralPath $Path)
   if($rows.Count -ne 1) { throw "$Label must contain exactly one row." }
   return $rows[0]
}

function ConvertTo-BoolStrict {
   param([object]$Value)
   return ([string]$Value).Trim().ToLowerInvariant() -eq 'true'
}

function Invoke-PowerShellTest {
   param([Parameter(Mandatory=$true)][string]$Name, [Parameter(Mandatory=$true)][string]$File)
   $path = Join-Path $PSScriptRoot $File
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "$Name test is missing: $path" }
   & $path | Out-Host
   if(!$?) { throw "$Name test failed." }
}

function Assert-FrozenIdentity {
   param([object]$Row, [string]$Label, [string]$ManifestHash = $expectedManifestHash)
   if($Row.SourceSha256 -ne $expectedSourceHash -or $Row.ProfileSha256 -ne $expectedProfileHash -or $Row.ManifestSha256 -ne $ManifestHash) {
      throw "$Label identity does not match the frozen successor."
   }
}

$initialStatus = @(Get-WorktreeStatus)
if(!$SkipCleanWorktreeCheck -and $initialStatus.Count -ne 0) {
   throw "Offline audit requires a clean worktree. Existing changes: $($initialStatus -join '; ')"
}

$repoLock = Join-Path $PSScriptRoot 'MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock = Join-Path $sharedWork 'MT5_LOCAL_LAUNCH_DISABLED.lock'
if(!(Test-Path -LiteralPath $repoLock -PathType Leaf) -or !(Test-Path -LiteralPath $outerLock -PathType Leaf)) {
   throw 'Both local MT5 launch locks are required for the offline audit.'
}
$beforeProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($beforeProcesses.Count -ne 0) { throw 'An MT5-family process is running before the offline audit.' }

$tests = @(
   @('static gate repair', 'test_rdmc_money_ready_gate_repair.ps1'),
   @('24-row executable queue', 'test_rdmc_money_ready_gate_repair_executable_queue.ps1'),
   @('identity-bound execution harness', 'test_rdmc_money_ready_gate_repair_execution_harness.ps1'),
   @('compile-once wave runner', 'test_rdmc_money_ready_gate_repair_executable_wave_runner.ps1'),
   @('hard-locked source staging', 'test_rdmc_money_ready_gate_repair_source_staging.ps1'),
   @('identity-bound collector', 'test_rdmc_money_ready_gate_repair_executable_collector.ps1'),
   @('executable ledger stress', 'test_rdmc_money_ready_gate_repair_ledger_package.ps1'),
   @('distinct-broker gate', 'test_rdmc_money_ready_gate_repair_second_broker_harness.ps1'),
   @('legacy forward-draft compatibility', 'test_rdmc_forward_demo_draft.ps1'),
   @('successor forward preflight', 'test_rdmc_money_ready_gate_repair_forward_demo_draft.ps1')
)
foreach($test in $tests) { Invoke-PowerShellTest -Name $test[0] -File $test[1] }

$evaluatorTest = Join-Path $PSScriptRoot 'test_rdmc_money_ready_gate_repair_executable.py'
& python $evaluatorTest | Out-Host
if($LASTEXITCODE -ne 0) { throw 'Executable evaluator regression failed.' }

# Regenerate the canonical plan after all isolated tests so worker inventory and compile-once state are authoritative.
& (Join-Path $PSScriptRoot 'run_rdmc_money_ready_gate_repair_executable_wave.ps1') | Out-Host
if(!$?) { throw 'Canonical executable plan regeneration failed.' }

$staticRows = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_STATIC_READINESS.csv'))
if($staticRows.Count -ne 63 -or @($staticRows | Where-Object { !(ConvertTo-BoolStrict $_.Pass) }).Count -ne 0) {
   throw 'Static successor readiness is no longer 63/63.'
}

$manifestPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv'
$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
if($manifestRows.Count -ne 24 -or (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ne $expectedManifestHash) {
   throw 'Executable manifest identity or row count changed.'
}
if((@(1..5 | ForEach-Object { $wave = $_; @($manifestRows | Where-Object Wave -eq ([string]$wave)).Count }) -join ',') -ne '2,4,2,4,12') {
   throw 'Executable wave allocation changed.'
}

$decision = Import-OneCsvRow (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv') 'Executable decision'
Assert-FrozenIdentity $decision 'Executable decision'
if($decision.Status -ne 'LOCKED_AWAITING_WAVE_01_REPORTS' -or $decision.CurrentWave -ne '1' -or $decision.ReportsPresent -ne '0' -or
   !(ConvertTo-BoolStrict $decision.LaunchLocked) -or (ConvertTo-BoolStrict $decision.ExecutableGatePass) -or
   !(ConvertTo-BoolStrict $decision.StaticReadinessPass) -or !(ConvertTo-BoolStrict $decision.SourceNormalizedToBase) -or
   (ConvertTo-BoolStrict $decision.ForwardCandidateChanged) -or (ConvertTo-BoolStrict $decision.RealAccountApproved)) {
   throw 'Executable decision no longer preserves the locked zero-evidence boundary.'
}

$planRows = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RUN_PLAN.csv'))
if($planRows.Count -ne 2 -or ($planRows.Window -join ',') -ne '2019,2022' -or @($planRows | Where-Object {
   $_.Status -ne 'LOCKED' -or $_.ExecutionMode -ne 'SINGLE_STAGE' -or $_.SharedBinaryStatus -notin @('LOCKED_COMPILE_ONCE_REQUIRED','SHARED_BINARY_READY')
}).Count -ne 0) { throw 'Canonical Wave 1 plan is stale or unsafe.' }

$sourceStagingRows = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING.csv'))
$sourceStagingTests = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING_TESTS.csv'))
if($sourceStagingRows.Count -ne 4 -or @($sourceStagingRows | Where-Object {
   $_.ExactSourceReady -ne 'True' -or $_.SourceChanged -ne 'False' -or $_.BinaryUnchanged -ne 'True' -or
   $_.IdentityUnchanged -ne 'True' -or $_.MQL5Launched -ne 'False'
}).Count -ne 0 -or $sourceStagingTests.Count -ne 4 -or @($sourceStagingTests | Where-Object {
   $_.Pass -ne 'True' -or $_.MQL5Launched -ne 'False'
}).Count -ne 0) {
   throw 'Hard-locked source staging no longer preserves its identity and no-launch boundary.'
}

$ledger = Import-OneCsvRow (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_DECISION.csv') 'Ledger-stress decision'
Assert-FrozenIdentity $ledger 'Ledger-stress decision'
if($ledger.Status -ne 'AWAITING_EXECUTABLE_MT5_GATE' -or (ConvertTo-BoolStrict $ledger.ExecutableLedgerPresent) -or
   (ConvertTo-BoolStrict $ledger.CostGatePass) -or (ConvertTo-BoolStrict $ledger.OrderAwareMonteCarloPass) -or
   (ConvertTo-BoolStrict $ledger.ForwardCandidateChanged) -or (ConvertTo-BoolStrict $ledger.RealAccountApproved)) {
   throw 'Ledger-stress decision inherited or overclaimed evidence.'
}

$broker = Import-OneCsvRow (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.csv') 'Second-broker decision'
Assert-FrozenIdentity $broker 'Second-broker decision' $expectedSecondBrokerManifestHash
if($broker.Status -ne 'AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS' -or $broker.ReportsPresent -ne '0' -or
   (ConvertTo-BoolStrict $broker.SpecificationPass) -or (ConvertTo-BoolStrict $broker.SecondBrokerGatePass) -or
   (ConvertTo-BoolStrict $broker.ForwardCandidateChanged) -or (ConvertTo-BoolStrict $broker.RealAccountApproved)) {
   throw 'Second-broker decision inherited or overclaimed evidence.'
}

$registrationPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_DRAFT_REGISTRATION.json'
$registration = Get-Content -Raw -LiteralPath $registrationPath | ConvertFrom-Json
$forbiddenRegistrationFields = @('accountLogin','accountNumber','accountId','brokerServer','serverName')
if($registration.activationStatus -ne 'PREPARED_NOT_REGISTERED' -or $null -ne $registration.registeredAtLocal -or
   $null -ne $registration.registeredAtUtc -or $registration.accountIdentifierPublished -or $registration.realAccountTradingAllowed -or
   $registration.sourceSha256 -ne $expectedSourceHash -or $registration.researchProfileSha256 -ne $expectedProfileHash -or
   $registration.forwardProfileSha256 -ne $expectedForwardProfileHash -or $registration.primaryExecutableManifestSha256 -ne $expectedManifestHash -or
   $registration.secondBrokerManifestSha256 -ne $expectedSecondBrokerManifestHash -or
   @($forbiddenRegistrationFields | Where-Object { $registration.PSObject.Properties.Name -contains $_ }).Count -ne 0) {
   throw 'Successor forward draft is registered, identifying, or identity-mismatched.'
}

$preflightRows = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_PREFLIGHT.csv'))
if(@($preflightRows | Where-Object Gate -eq 'static-trade-readiness').Count -ne 1 -or
   !(ConvertTo-BoolStrict ($preflightRows | Where-Object Gate -eq 'static-trade-readiness' | Select-Object -First 1).Pass) -or
   @($preflightRows | Where-Object { $_.Gate -in @('primary-executable-gate','executable-ledger-stress','distinct-broker-gate','candidate-compiled-binary','sentinel-compiled-binary') -and (ConvertTo-BoolStrict $_.Pass) }).Count -ne 0) {
   throw 'Successor forward preflight is not fail-closed at the intended prerequisites.'
}

$successorForwardTests = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_DRAFT_TESTS.csv'))
$legacyForwardTests = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_FORWARD_DEMO_DRAFT_TESTS.csv'))
if($successorForwardTests.Count -ne 4 -or @($successorForwardTests | Where-Object { !(ConvertTo-BoolStrict $_.Pass) -or (ConvertTo-BoolStrict $_.ReadyToRegister) }).Count -ne 0) {
   throw 'Successor forward preflight scenarios changed.'
}
if($legacyForwardTests.Count -ne 4 -or @($legacyForwardTests | Where-Object { !(ConvertTo-BoolStrict $_.Pass) -or (ConvertTo-BoolStrict $_.ReadyToRegister) }).Count -ne 0) {
   throw 'Legacy forward-draft compatibility scenarios changed.'
}

$reportDirectory = Join-Path $repo 'outputs\rdmc_money_ready_gate_repair_executable_package\reports_here'
$reportArtifacts = @(Get-ChildItem -LiteralPath $reportDirectory -File | Where-Object Name -ne 'README.md')
if($reportArtifacts.Count -ne 0 -or (Test-Path -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RESULTS.csv'))) {
   throw 'Unvalidated executable evidence exists in the successor package.'
}

$afterProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($afterProcesses.Count -ne 0 -or !(Test-Path -LiteralPath $repoLock) -or !(Test-Path -LiteralPath $outerLock)) {
   throw 'Offline audit changed the MT5 launch-safety state.'
}

$summary = [pscustomobject][ordered]@{
   Status = 'PASS'
   DirectTestEntrypoints = 11
   SourceStagingScenarios = 4
   ExactSourceWorkersStaged = 4
   StaticChecksPassed = 63
   ExecutableRows = 24
   ExecutableReportsPresent = 0
   ExecutableEvaluatorCases = 6
   LedgerFailClosedCases = 12
   SecondBrokerEvaluatorCases = 16
   SecondBrokerPackageChecks = 48
   SuccessorForwardScenarios = 4
   LegacyForwardScenarios = 4
   StrategyRiskInputsChangedForForward = 0
   CandidateRegistered = $false
   AccountIdentifierPublished = $false
   EvidenceInherited = $false
   MQL5Launched = $false
   RealAccountApproved = $false
   SourceSha256 = $expectedSourceHash
   ProfileSha256 = $expectedProfileHash
   ForwardProfileSha256 = $expectedForwardProfileHash
}
$summary | Export-Csv -LiteralPath $summaryCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate-Repair Offline Audit', '',
   '**PASS. The complete successor offline stack is deterministic, launch-locked, identity-bound, and fail-closed with zero executable or forward evidence.**', '',
   '- Direct test entrypoints: `11`',
   '- Hard-locked source-staging regressions: `4/4` on four portable workers',
   '- Static readiness: `63/63`',
   '- Executable queue: `24` rows in waves `2,4,2,4,12`',
   '- Executable evaluator regressions: `6/6`',
   '- Ledger fail-closed regressions: `12/12`',
   '- Second-broker evaluator regressions: `16/16`',
   '- Second-broker package checks: `48/48`',
   '- Successor forward fixtures: `4/4`',
   '- Legacy forward compatibility fixtures: `4/4`',
   '- Executable reports inherited or supplied: `0/24`',
   '- Second-broker reports inherited or supplied: `0/18`',
   '- Candidate registered: `False`',
   '- MT5 launched: `False`',
   '- Real-account approval: `False`', '',
   'This audit is workflow evidence, not profitability evidence. By default it starts and ends only on a clean Git worktree; any test-order mutation of canonical source, profile, decision, plan, or status artifacts fails the run.'
) | Set-Content -LiteralPath $summaryMarkdown -Encoding ASCII

if(!$SkipCleanWorktreeCheck) {
   $finalStatus = @(Get-WorktreeStatus)
   if($finalStatus.Count -ne 0) { throw "Offline audit changed the clean worktree: $($finalStatus -join '; ')" }
}

[pscustomobject]@{
   Status = 'PASS'
   DirectTestEntrypoints = 11
   CanonicalDriftDetected = $false
   CleanWorktreeVerified = !$SkipCleanWorktreeCheck
   ReportsPresent = 0
   MQL5Launched = $false
   RealAccountApproved = $false
}
