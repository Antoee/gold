Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$runner = Join-Path $PSScriptRoot "run_rdmc_money_ready_gate_repair_executable_wave.ps1"
$planDir = Join-Path $repo ("outputs\_rdmc_exec_wave_plan_test_" + [guid]::NewGuid().ToString("N"))
$planCsv = Join-Path $planDir "plan.csv"
$planMd = Join-Path $planDir "plan.md"
$decisionFixture = Join-Path $planDir "decision.csv"
if(!$planDir.StartsWith((Join-Path $repo "outputs") + "\", [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe plan-test path." }
$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

try {
   New-Item -ItemType Directory -Path $planDir -Force | Out-Null
   [pscustomobject]@{ CurrentWave = 1; TerminalRejection = $false } |
      Export-Csv -LiteralPath $decisionFixture -NoTypeInformation -Encoding ASCII
   $plan = & $runner -DecisionCsvPath $decisionFixture -PlanCsv $planCsv -PlanMarkdown $planMd
   if($plan.Status -ne "LOCKED" -or $plan.Wave -ne 1 -or $plan.Rows -ne 2 -or $plan.MQL5Launched -or
      $plan.SharedBinaryStatus -notin @("LOCKED_COMPILE_ONCE_REQUIRED","SHARED_BINARY_READY")) {
      throw "Wave runner plan did not preserve the locked wave-one contract."
   }
   $rows = @(Import-Csv -LiteralPath $planCsv)
   if($rows.Count -ne 2 -or ($rows.Window -join ',') -ne '2019,2022' -or @($rows | Where-Object Model -ne '1').Count -gt 0) {
      throw "Wave runner plan did not select only Model1 2019/2022."
   }
   if(@($rows | Where-Object { $_.ExecutionStage -ne "1" -or $_.ExecutionMode -ne "SINGLE_STAGE" }).Count -gt 0) {
      throw "Wave-one plan does not preserve the single-stage execution contract."
   }

   $wrongWaveRejected = $false
   try { & $runner -DecisionCsvPath $decisionFixture -Wave 2 -PlanCsv $planCsv -PlanMarkdown $planMd | Out-Null } catch { $wrongWaveRejected = $_.Exception.Message -match "not the admitted wave" }
   if(!$wrongWaveRejected) { throw "Wave runner accepted a future wave." }

   $hardLockRejected = $false
   try { & $runner -DecisionCsvPath $decisionFixture -Run -UserAuthorizedFocusRisk -PlanCsv $planCsv -PlanMarkdown $planMd | Out-Null } catch { $hardLockRejected = $_.Exception.Message -match "hard-locked" }
   if(!$hardLockRejected) { throw "Wave runner did not fail closed in run mode." }

   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   if($after.Count -gt $before.Count) { throw "Wave runner test launched an MT5-family process." }
   $text = Get-Content -LiteralPath $runner -Raw
   foreach($token in @("assert_mt5_launch_allowed.ps1", "prepare_mt5_portable_shared_expert.ps1", "mt5_tick_cache_sync_helpers.ps1", "sync_mt5_portable_xauusd_tick_cache.ps1", "run_mt5_portable_parallel_manifest.ps1", "collect_rdmc_money_ready_gate_repair_executable_results.ps1", "MaxParallelism", "currentWave", "PortableBinarySha256", "DISJOINT_THEN_SYNC_THEN_CONTINUOUS")) {
      if($text -notmatch [regex]::Escape($token)) { throw "Wave runner is missing required token: $token" }
   }
   $prepareIndex = $text.LastIndexOf('& $sharedBinaryPreparer', [StringComparison]::Ordinal)
   $parallelIndex = $text.IndexOf('& $parallelRunner', [StringComparison]::Ordinal)
   if($prepareIndex -lt 0 -or $parallelIndex -lt 0 -or $prepareIndex -ge $parallelIndex) {
      throw "Wave runner does not prepare one shared binary before parallel workers."
   }
   $stageAIndex = $text.IndexOf('& $parallelRunner -ManifestPath $broadManifest', [StringComparison]::Ordinal)
   $syncIndex = $text.IndexOf('$cacheResult = & $tickCacheSync', [StringComparison]::Ordinal)
   $stageBIndex = $text.IndexOf('& $parallelRunner -ManifestPath $continuousManifest', [StringComparison]::Ordinal)
   $stagedCollectorIndex = $text.IndexOf('& $collector -Wave $Wave -RunnerLedgerGlob', [StringComparison]::Ordinal)
   if($stageAIndex -lt 0 -or $syncIndex -le $stageAIndex -or
      $stageBIndex -le $syncIndex -or $stagedCollectorIndex -le $stageBIndex) {
      throw "Wave 4 is not ordered as disjoint eras, cache union, continuous, then collection."
   }
   $manifest = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv"))
   $wave4 = @($manifest | Where-Object Wave -eq "4")
   if($wave4.Count -ne 4 -or @($wave4 | Where-Object Role -eq "broad").Count -ne 3 -or
      @($wave4 | Where-Object Role -eq "continuous").Count -ne 1) {
      throw "Frozen wave 4 no longer contains three disjoint eras and one continuous row."
   }

   [pscustomobject]@{
      Status = "PASS"
      PlannedWave = $plan.Wave
      PlannedRows = $plan.Rows
      SharedBinaryStatus = $plan.SharedBinaryStatus
      Wave4BroadRows = @($wave4 | Where-Object Role -eq "broad").Count
      Wave4ContinuousRows = @($wave4 | Where-Object Role -eq "continuous").Count
      WrongWaveRejected = $wrongWaveRejected
      HardLockRejected = $hardLockRejected
      MQL5Launched = $false
   }
}
finally {
   if(Test-Path -LiteralPath $planDir) { Remove-Item -LiteralPath $planDir -Recurse -Force }
}
