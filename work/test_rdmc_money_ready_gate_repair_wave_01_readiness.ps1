$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$builder = Join-Path $PSScriptRoot 'build_rdmc_money_ready_gate_repair_wave_01_readiness.ps1'
$statusPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_READINESS.csv'
$workersPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_WORKERS.csv'
$testsCsvPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_READINESS_TESTS.csv'
$testsMarkdownPath = Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_WAVE_01_READINESS_TESTS.md'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$temp = [IO.Path]::GetFullPath((Join-Path $tempRoot ('rdmc-wave-01-readiness-test-' + [guid]::NewGuid().ToString('N'))))
if(!$temp.StartsWith($tempRoot + '\rdmc-wave-01-readiness-test-', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe Wave 1 readiness test path.' }
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

try {
   $current = & $builder
   $workers = @(Import-Csv -LiteralPath $workersPath)
   if($current.Status -ne 'HARD_LOCKED_SOURCE_STAGED_COMPILE_ONCE_REQUIRED' -or !$current.InfrastructureReady -or $current.SafeToLaunchNow -or
      !$current.LaunchLocksPresent -or $current.RuntimeWorkersReady -ne 2 -or !$current.Model1History2019Ready -or
      !$current.Model1History2022Ready -or !$current.StagedSourceReady -or $current.SharedBinaryReady -or !$current.CompilationNeeded -or
      $current.ReportsPresent -ne 0 -or $current.MQL5Launched -or $current.ForwardCandidateChanged -or $current.RealAccountApproved) {
      throw 'Current Wave 1 readiness did not preserve the expected hard-locked compile-once boundary.'
   }
   if($workers.Count -ne 2 -or @($workers | Where-Object RuntimeReady -ne 'True').Count -ne 0 -or
      @($workers | Where-Object ExactSourceReady -ne 'True').Count -ne 0 -or
      @($workers | Where-Object { $_.History2019Sha256 -eq 'MISSING' -or $_.History2022Sha256 -eq 'MISSING' }).Count -ne 0) {
      throw 'Current Wave 1 worker inventory is incomplete.'
   }

   $tamperedManifest = Join-Path $temp 'tampered-wave.csv'
   $tamperedRows = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_01_MANIFEST.csv'))
   $tamperedRows[0].ConfigSha256 = '0' * 64
   $tamperedRows | Export-Csv -LiteralPath $tamperedManifest -NoTypeInformation -Encoding ASCII
   $tampered = & $builder -WaveManifestPath $tamperedManifest `
      -StatusCsvPath (Join-Path $temp 'tampered-status.csv') -WorkersCsvPath (Join-Path $temp 'tampered-workers.csv') `
      -StatusMarkdownPath (Join-Path $temp 'tampered-status.md')
   if($tampered.Status -ne 'INFRASTRUCTURE_BLOCKED' -or $tampered.InfrastructureReady -or $tampered.SafeToLaunchNow -or $tampered.MQL5Launched) {
      throw 'Tampered Wave 1 manifest was not refused before launch.'
   }

   $missingWorker = & $builder -WorkerNames @('mt5_portable_research','mt5_portable_research_w99') `
      -StatusCsvPath (Join-Path $temp 'missing-status.csv') -WorkersCsvPath (Join-Path $temp 'missing-workers.csv') `
      -StatusMarkdownPath (Join-Path $temp 'missing-status.md')
   if($missingWorker.Status -ne 'INFRASTRUCTURE_BLOCKED' -or $missingWorker.InfrastructureReady -or $missingWorker.SafeToLaunchNow -or $missingWorker.MQL5Launched) {
      throw 'Missing portable worker was not refused before launch.'
   }

   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   if($after.Count -ne $before.Count -or $after.Count -ne 0) { throw 'Wave 1 readiness tests launched an MT5-family process.' }

   $scenarios = @(
      [pscustomobject]@{Scenario='current_hard_locked_runtime';Expected='HARD_LOCKED_SOURCE_STAGED_COMPILE_ONCE_REQUIRED';Actual=$current.Status;Pass=$true;MQL5Launched=$false},
      [pscustomobject]@{Scenario='tampered_wave_manifest';Expected='INFRASTRUCTURE_BLOCKED';Actual=$tampered.Status;Pass=$true;MQL5Launched=$false},
      [pscustomobject]@{Scenario='missing_portable_worker';Expected='INFRASTRUCTURE_BLOCKED';Actual=$missingWorker.Status;Pass=$true;MQL5Launched=$false}
   )
   $scenarios | Export-Csv -LiteralPath $testsCsvPath -NoTypeInformation -Encoding ASCII
   @(
      '# RDMC Money-Ready Gate-Repair Wave 1 Readiness Tests', '',
      '**PASS. Three no-launch scenarios preserve exact identity, infrastructure, and hard-lock boundaries.**', '',
      '- Current Wave 1 infrastructure: `READY`',
      '- Current launch state: `HARD_LOCKED_SOURCE_STAGED_COMPILE_ONCE_REQUIRED`',
      '- Tampered manifest rejected: `PASS`',
      '- Missing worker rejected: `PASS`',
      '- MT5 launched: `False`', '',
      '| Scenario | Expected | Actual | Pass |', '|---|---|---|---:|'
   ) + @($scenarios | ForEach-Object { "| $($_.Scenario) | $($_.Expected) | $($_.Actual) | $($_.Pass) |" }) |
      Set-Content -LiteralPath $testsMarkdownPath -Encoding ASCII

   [pscustomobject]@{
      Status = 'PASS'
      Scenarios = $scenarios.Count
      RuntimeWorkersReady = $current.RuntimeWorkersReady
      Model1HistoryYearsReady = 2
      SharedBinaryReady = $current.SharedBinaryReady
      CompilationNeeded = $current.CompilationNeeded
      SafeToLaunchNow = $current.SafeToLaunchNow
      MQL5Launched = $false
      RealAccountApproved = $false
   }
}
finally {
   if(Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
