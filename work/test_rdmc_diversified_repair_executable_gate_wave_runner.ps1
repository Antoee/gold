Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$runner = Join-Path $PSScriptRoot "run_rdmc_diversified_repair_executable_gate_wave.ps1"
$planDir = Join-Path $repo ("outputs\_rdmc_exec_wave_plan_test_" + [guid]::NewGuid().ToString("N"))
$planCsv = Join-Path $planDir "plan.csv"
$planMd = Join-Path $planDir "plan.md"
if(!$planDir.StartsWith((Join-Path $repo "outputs") + "\", [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe plan-test path." }
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

try {
   $plan = & $runner -PlanCsv $planCsv -PlanMarkdown $planMd
   if($plan.Status -ne "LOCKED" -or $plan.Wave -ne 1 -or $plan.Rows -ne 2 -or $plan.MQL5Launched -or
      $plan.SharedBinaryStatus -notin @("LOCKED_COMPILE_ONCE_REQUIRED","SHARED_BINARY_READY")) {
      throw "Wave runner plan did not preserve the locked wave-one contract."
   }
   $rows = @(Import-Csv -LiteralPath $planCsv)
   if($rows.Count -ne 2 -or ($rows.Window -join ',') -ne '2019,2022' -or @($rows | Where-Object Model -ne '1').Count -gt 0) {
      throw "Wave runner plan did not select only Model1 2019/2022."
   }

   $wrongWaveRejected = $false
   try { & $runner -Wave 2 -PlanCsv $planCsv -PlanMarkdown $planMd | Out-Null } catch { $wrongWaveRejected = $_.Exception.Message -match "not the admitted wave" }
   if(!$wrongWaveRejected) { throw "Wave runner accepted a future wave." }

   $hardLockRejected = $false
   try { & $runner -Run -UserAuthorizedFocusRisk -PlanCsv $planCsv -PlanMarkdown $planMd | Out-Null } catch { $hardLockRejected = $_.Exception.Message -match "hard-locked" }
   if(!$hardLockRejected) { throw "Wave runner did not fail closed in run mode." }

   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   if($after.Count -gt $before.Count) { throw "Wave runner test launched an MT5-family process." }
   $text = Get-Content -LiteralPath $runner -Raw
   foreach($token in @("assert_mt5_launch_allowed.ps1", "prepare_mt5_portable_shared_expert.ps1", "run_mt5_portable_parallel_manifest.ps1", "collect_rdmc_diversified_repair_executable_gate_results.ps1", "MaxParallelism", "currentWave", "PortableBinarySha256")) {
      if($text -notmatch [regex]::Escape($token)) { throw "Wave runner is missing required token: $token" }
   }
   $prepareIndex = $text.LastIndexOf('& $sharedBinaryPreparer', [StringComparison]::Ordinal)
   $parallelIndex = $text.IndexOf('& $parallelRunner', [StringComparison]::Ordinal)
   if($prepareIndex -lt 0 -or $parallelIndex -lt 0 -or $prepareIndex -ge $parallelIndex) {
      throw "Wave runner does not prepare one shared binary before parallel workers."
   }

   [pscustomobject]@{
      Status = "PASS"
      PlannedWave = $plan.Wave
      PlannedRows = $plan.Rows
      SharedBinaryStatus = $plan.SharedBinaryStatus
      WrongWaveRejected = $wrongWaveRejected
      HardLockRejected = $hardLockRejected
      MQL5Launched = $false
   }
}
finally {
   if(Test-Path -LiteralPath $planDir) { Remove-Item -LiteralPath $planDir -Recurse -Force }
}
