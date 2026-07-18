$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$stager = Join-Path $PSScriptRoot 'stage_rdmc_money_ready_gate_repair_source_offline.ps1'
$statusCsv = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING.csv'
$testsCsv = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING_TESTS.csv'
$testsMarkdown = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SOURCE_STAGING_TESTS.md'
$beforeProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($beforeProcesses.Count -ne 0) { throw 'Source-staging regression tests require zero MT5-family processes.' }

$scenarios = [System.Collections.Generic.List[object]]::new()
$plan = & $stager
if($plan.Status -ne 'ALREADY_STAGED_OFFLINE_LOCKED' -or $plan.Workers -ne 4 -or
   $plan.RuntimeWorkersReady -ne 4 -or $plan.ExactSourceWorkersReady -ne 4 -or
   !$plan.CompiledArtifactsUnchanged -or !$plan.LaunchLocksPresent -or $plan.MQL5Launched -or
   $plan.Compiled -or $plan.Backtested -or $plan.ForwardCandidateChanged -or $plan.RealAccountApproved) {
   throw 'Already-staged plan did not preserve the offline no-launch contract.'
}
$scenarios.Add([pscustomobject]@{Scenario='already_staged_plan';Expected='ALREADY_STAGED_OFFLINE_LOCKED';Actual=$plan.Status;Pass=$true;MQL5Launched=$false}) | Out-Null

$idempotent = & $stager -Stage
$stagedRows = @(Import-Csv -LiteralPath $statusCsv)
if($idempotent.Status -ne 'ALREADY_STAGED_OFFLINE_LOCKED' -or $idempotent.ExactSourceWorkersReady -ne 4 -or
   !$idempotent.CompiledArtifactsUnchanged -or @($stagedRows | Where-Object {
      $_.ExactSourceReady -ne 'True' -or $_.SourceChanged -ne 'False' -or
      $_.BinaryUnchanged -ne 'True' -or $_.IdentityUnchanged -ne 'True' -or $_.MQL5Launched -ne 'False'
   }).Count -ne 0) {
   throw 'Idempotent source staging changed source identity or compiled artifacts.'
}
$scenarios.Add([pscustomobject]@{Scenario='idempotent_locked_stage';Expected='ALREADY_STAGED_OFFLINE_LOCKED';Actual=$idempotent.Status;Pass=$true;MQL5Launched=$false}) | Out-Null

$badSourceRejected = $false
try {
   & $stager -SourcePath 'README.md' | Out-Null
}
catch {
   $badSourceRejected = $_.Exception.Message -match 'canonical frozen successor source path'
}
if(!$badSourceRejected) { throw 'Noncanonical source path was not rejected.' }
$scenarios.Add([pscustomobject]@{Scenario='noncanonical_source';Expected='REJECTED';Actual='REJECTED';Pass=$true;MQL5Launched=$false}) | Out-Null

$badWorkerRejected = $false
try {
   & $stager -WorkerNames @('mt5_portable_research','unsafe_worker') | Out-Null
}
catch {
   $badWorkerRejected = $_.Exception.Message -match 'outside the portable research allowlist'
}
if(!$badWorkerRejected) { throw 'Nonallowlisted worker was not rejected.' }
$scenarios.Add([pscustomobject]@{Scenario='nonallowlisted_worker';Expected='REJECTED';Actual='REJECTED';Pass=$true;MQL5Launched=$false}) | Out-Null

$afterProcesses = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
if($afterProcesses.Count -ne 0) { throw 'Source-staging regression tests launched an MT5-family process.' }

$scenarios | Export-Csv -LiteralPath $testsCsv -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate-Repair Source-Staging Tests', '',
   '**PASS. Four scenarios preserve the exact-source, hard-lock, compiled-artifact, and no-launch boundaries.**', '',
   '- Exact source staged on four workers: `PASS`',
   '- Idempotent stage: `PASS`',
   '- Noncanonical source rejected: `PASS`',
   '- Nonallowlisted worker rejected: `PASS`',
   '- Existing EX5 and identity artifacts unchanged: `PASS`',
   '- MT5 launched: `False`', '',
   '| Scenario | Expected | Actual | Pass |',
   '|---|---|---|---:|'
) + @($scenarios | ForEach-Object { "| $($_.Scenario) | $($_.Expected) | $($_.Actual) | $($_.Pass) |" }) |
   Set-Content -LiteralPath $testsMarkdown -Encoding ASCII

[pscustomobject][ordered]@{
   Status = 'PASS'
   Scenarios = $scenarios.Count
   ExactSourceWorkersReady = $idempotent.ExactSourceWorkersReady
   CompiledArtifactsUnchanged = $idempotent.CompiledArtifactsUnchanged
   LaunchLocksPresent = $idempotent.LaunchLocksPresent
   MQL5Launched = $false
   ForwardCandidateChanged = $false
   RealAccountApproved = $false
}
