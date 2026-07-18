[CmdletBinding()]
param(
   [ValidateRange(0,5)][int]$Wave = 0,
   [string[]]$PortableRoots = @(),
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [switch]$UserAuthorizedFocusRisk,
   [switch]$Run,
   [string]$DecisionCsvPath = "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv",
   [string]$PlanCsv = "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RUN_PLAN.csv",
   [string]$PlanMarkdown = "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_RUN_PLAN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sharedWork = Split-Path -Parent $repo
$decisionPath = if([IO.Path]::IsPathRooted($DecisionCsvPath)) { $DecisionCsvPath } else { Join-Path $repo $DecisionCsvPath }
$manifestPath = Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_MANIFEST.csv"
$parallelRunner = Join-Path $PSScriptRoot "run_mt5_portable_parallel_manifest.ps1"
$collector = Join-Path $PSScriptRoot "collect_rdmc_money_ready_gate_repair_executable_results.ps1"
$sharedBinaryPreparer = Join-Path $PSScriptRoot "prepare_mt5_portable_shared_expert.ps1"
$tickCacheHelper = Join-Path $PSScriptRoot "mt5_tick_cache_sync_helpers.ps1"
$tickCacheSync = Join-Path $PSScriptRoot "sync_mt5_portable_xauusd_tick_cache.ps1"
$packageSource = Join-Path $repo "outputs\rdmc_money_ready_gate_repair_package\source\Professional_XAUUSD_EA.mq5"
$repoLock = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$outerLock = Join-Path $sharedWork "MT5_LOCAL_LAUNCH_DISABLED.lock"
$expectedManifestHash = "EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972"
$expectedSourceHash = "104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8"
$expectedProfileHash = "8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

foreach($required in @($decisionPath,$manifestPath,$parallelRunner,$collector,$sharedBinaryPreparer,$tickCacheHelper,$tickCacheSync,$packageSource)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required executable-gate artifact is missing: $required" }
}
if((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw "Executable-gate manifest identity changed."
}
$decision = @(Import-Csv -LiteralPath $decisionPath)
if($decision.Count -ne 1) { throw "Expected one executable-gate decision row." }
if($decision[0].TerminalRejection -eq "True") { throw "Executable gate is terminally rejected." }
$currentWave = [int]$decision[0].CurrentWave
if($currentWave -lt 1 -or $currentWave -gt 5) { throw "No executable wave is currently admitted." }
if($Wave -eq 0) { $Wave = $currentWave }
if($Wave -ne $currentWave) { throw "Requested wave $Wave is not the admitted wave $currentWave." }

$manifest = @(Import-Csv -LiteralPath $manifestPath)
$waveRows = @($manifest | Where-Object Wave -eq ([string]$Wave) | Sort-Object { [int]$_.QueueRank })
if($waveRows.Count -lt 1) { throw "Admitted wave has no rows." }
if(@($waveRows | Where-Object { $_.SourceSha256 -ne $expectedSourceHash -or $_.ProfileSha256 -ne $expectedProfileHash }).Count -gt 0) {
   throw "Admitted wave source/profile identity changed."
}
foreach($row in $waveRows) {
   $config = Resolve-RepoPath ([string]$row.PackageConfig)
   if(!(Test-Path -LiteralPath $config -PathType Leaf)) { throw "Admitted config is missing: $config" }
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $row.ConfigSha256) {
      throw "Admitted config identity changed at queue rank $($row.QueueRank)."
   }
}

if($PortableRoots.Count -eq 0) {
   $PortableRoots = @(
      (Join-Path $sharedWork "mt5_portable_research"),
      (Join-Path $sharedWork "mt5_portable_research_w2"),
      (Join-Path $sharedWork "mt5_portable_research_w3"),
      (Join-Path $sharedWork "mt5_portable_research_w4")
   )
}
$availableRoots = @($PortableRoots | Where-Object {
   (Test-Path -LiteralPath (Join-Path $_ "terminal64.exe") -PathType Leaf) -and
   (Test-Path -LiteralPath (Join-Path $_ "MetaEditor64.exe") -PathType Leaf)
} | Select-Object -Unique)
$executionMode = if($Wave -eq 4) { "DISJOINT_THEN_SYNC_THEN_CONTINUOUS" } else { "SINGLE_STAGE" }
$maxWorkers = if($Wave -eq 4) { 3 } else { [int]($waveRows | Select-Object -First 1).MaxParallelism }
$workerCount = [Math]::Min($maxWorkers, $availableRoots.Count)
$sharedBinaryPlan = if($availableRoots.Count -gt 0) {
   & $sharedBinaryPreparer -SourcePath $packageSource -ExpectedSourceSha256 $expectedSourceHash `
      -PortableRoots $availableRoots -MaxCpuPercent $MaxCpuPercent -PlanOnly -NoWritePlan
} else {
   [pscustomobject]@{ Status="RUNTIME_MISSING"; Action="PROVISION_RUNTIME"; SharedBinaryReady=$false }
}
$repoLocked = Test-Path -LiteralPath $repoLock
$outerLocked = Test-Path -LiteralPath $outerLock
$status = if($repoLocked -or $outerLocked) { "LOCKED" } elseif($workerCount -lt 1) { "NO_PORTABLE_RUNTIME" } else { "READY" }
$action = if($status -eq "LOCKED") { "WAIT_FOR_DELIBERATE_LOCK_REVIEW" } elseif($status -eq "READY") { "RUN_ADMITTED_WAVE_ONLY" } else { "PROVISION_PORTABLE_RUNTIME" }

$planRows = foreach($row in $waveRows) {
   [pscustomobject]@{
      Wave = $Wave
      QueueRank = $row.QueueRank
      Model = $row.Model
      Role = $row.Role
      Window = $row.Window
      ConfigSha256 = $row.ConfigSha256
      Status = $status
      Action = $action
      AvailableWorkers = $workerCount
      MaxCpuPercent = $MaxCpuPercent
      TimeoutMinutesPerConfig = $TimeoutMinutesPerConfig
      ExecutionStage = if($Wave -eq 4 -and $row.Role -eq "continuous") { 2 } else { 1 }
      ExecutionMode = $executionMode
      SharedBinaryStatus = $sharedBinaryPlan.Status
      SharedBinaryAction = $sharedBinaryPlan.Action
   }
}
$planCsvFull = Resolve-RepoPath $PlanCsv
$planMarkdownFull = Resolve-RepoPath $PlanMarkdown
$planParent = Split-Path -Parent $planCsvFull
if($planParent -and !(Test-Path -LiteralPath $planParent)) { New-Item -ItemType Directory -Path $planParent -Force | Out-Null }
$planRows | Export-Csv -LiteralPath $planCsvFull -NoTypeInformation -Encoding ASCII
$markdown = @(
   "# RDMC Money-Ready Gate Repair Executable Run Plan",
   "",
   "- Status: **$status**",
   "- Admitted wave: ``$Wave``",
   "- Rows: ``$($waveRows.Count)``",
   "- Available workers: ``$workerCount`` of ``$maxWorkers`` allowed",
   "- CPU ceiling per worker: ``$MaxCpuPercent%``",
   "- Execution mode: ``$executionMode``",
   "- Shared binary status: ``$($sharedBinaryPlan.Status)``",
   "- Shared binary action: ``$($sharedBinaryPlan.Action)``",
   "- Repository hard lock: ``$repoLocked``",
   "- Outer workspace hard lock: ``$outerLocked``",
   "- Action: ``$action``",
   "",
   "Plan mode never launches MT5. Run mode requires explicit focus-risk authorization, both hard locks absent, both unlock acknowledgements, and the launch-guard environment flags. Only the currently admitted wave manifest is passed to the generic parallel runner.",
   "",
   "Before workers start, run mode compiles the exact candidate once on one allowlisted leader and distributes that byte-identical source, EX5, and identity file to every portable root. Workers receive the prepared binary hash and are prohibited from recompiling independently.",
   "",
   "Wave 4 is staged without changing any frozen evidence row: three disjoint real-tick eras run first on at most three workers, verified missing complete-month XAUUSD tick caches are unioned across stopped portable roots, and only then does the continuous 2015-2026 row run on a warm cache. A complete-month same-name hash conflict stops the wave; the frozen partial July 2026 cutoff month is never copied.",
   "",
   "Interrupted work is resumable only through identity sidecars generated after a complete terminal exit. A cached report without matching report, config, source, and compiled-binary hashes is ignored and rerun."
)
[IO.File]::WriteAllLines($planMarkdownFull, $markdown, [Text.Encoding]::ASCII)

if(!$Run) {
   [pscustomobject]@{ Status=$status; Wave=$Wave; Rows=$waveRows.Count; Workers=$workerCount; SharedBinaryStatus=$sharedBinaryPlan.Status; MQL5Launched=$false }
   return
}
if(!$UserAuthorizedFocusRisk) { throw "Run mode requires explicit focus-risk authorization." }
if($repoLocked -or $outerLocked) { throw "RDMC executable wave is hard-locked; no MT5 process was started." }
if($workerCount -lt 1) { throw "No admitted portable runtime is available." }
. (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1")

$sharedBinary = & $sharedBinaryPreparer -SourcePath $packageSource `
   -ExpectedSourceSha256 $expectedSourceHash -PortableRoots $availableRoots `
   -MaxCpuPercent $MaxCpuPercent -UserAuthorizedFocusRisk
if($sharedBinary.Status -notin @("REUSED_SHARED_BINARY","COMPILED_ONCE_AND_DISTRIBUTED") -or
   [string]::IsNullOrWhiteSpace([string]$sharedBinary.PortableBinarySha256)) {
   throw "Shared portable binary preparation failed."
}

$waveManifest = "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_{0:D2}_MANIFEST.csv" -f $Wave
if($Wave -eq 4) {
   $broadRows = @($waveRows | Where-Object Role -eq "broad" | Sort-Object { [int]$_.QueueRank })
   $continuousRows = @($waveRows | Where-Object Role -eq "continuous" | Sort-Object { [int]$_.QueueRank })
   if($broadRows.Count -ne 3 -or $continuousRows.Count -ne 1) {
      throw "Wave 4 no longer matches the frozen three-era plus continuous staging contract."
   }
   $stageToken = [guid]::NewGuid().ToString("N")
   $broadManifest = Join-Path $env:TEMP ("rdmc_mrgr_wave04_broad_" + $stageToken + ".csv")
   $continuousManifest = Join-Path $env:TEMP ("rdmc_mrgr_wave04_continuous_" + $stageToken + ".csv")
   $stageAPrefix = "RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_04_STAGE_A_WORKER"
   $stageBPrefix = "RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_04_STAGE_B_WORKER"
   try {
      $broadRows | Export-Csv -LiteralPath $broadManifest -NoTypeInformation -Encoding ASCII
      $continuousRows | Export-Csv -LiteralPath $continuousManifest -NoTypeInformation -Encoding ASCII
      Get-ChildItem -Path (Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_04_STAGE_A_WORKER_*.csv") -File -ErrorAction SilentlyContinue |
         Remove-Item -Force
      Get-ChildItem -Path (Join-Path $repo "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_04_STAGE_B_WORKER_*.csv") -File -ErrorAction SilentlyContinue |
         Remove-Item -Force
      $stageARoots = @($availableRoots | Select-Object -First $workerCount)
      & $parallelRunner -ManifestPath $broadManifest -PortableRoots $stageARoots `
         -UserAuthorizedFocusRisk -OutputPrefix $stageAPrefix -MaxCpuPercent $MaxCpuPercent `
         -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
         -ExpectedPortableBinarySha256 $sharedBinary.PortableBinarySha256

      $cacheResult = & $tickCacheSync -PortableRoots $availableRoots -Synchronize -UserAuthorizedCacheWrite
      if($cacheResult.Status -notin @("ALREADY_SYNCHRONIZED","SYNCHRONIZED_NOW")) {
         throw "Wave 4 tick-cache union did not complete."
      }

      & $parallelRunner -ManifestPath $continuousManifest -PortableRoots @($availableRoots[0]) `
         -UserAuthorizedFocusRisk -OutputPrefix $stageBPrefix -MaxCpuPercent $MaxCpuPercent `
         -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
         -ExpectedPortableBinarySha256 $sharedBinary.PortableBinarySha256
      & $collector -Wave $Wave -RunnerLedgerGlob "outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_04_STAGE_*_WORKER_*.csv"
   }
   finally {
      Remove-Item -LiteralPath $broadManifest,$continuousManifest -Force -ErrorAction SilentlyContinue
   }
}
else {
   $outputPrefix = "RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_WAVE_{0:D2}_WORKER" -f $Wave
   & $parallelRunner -ManifestPath $waveManifest -PortableRoots $availableRoots[0..($workerCount - 1)] `
      -UserAuthorizedFocusRisk -OutputPrefix $outputPrefix -MaxCpuPercent $MaxCpuPercent `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -ExpectedPortableBinarySha256 $sharedBinary.PortableBinarySha256
   & $collector -Wave $Wave
}
