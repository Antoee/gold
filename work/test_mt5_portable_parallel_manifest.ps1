[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$runner = Join-Path $PSScriptRoot "run_mt5_portable_parallel_manifest.ps1"
if(!(Test-Path -LiteralPath $runner -PathType Leaf)) { throw "Missing generic runner: $runner" }

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("mt5_parallel_manifest_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
   $validPath = Join-Path $tempRoot "valid.csv"
   @(
      [pscustomobject]@{ QueueRank = 1; Candidate = "alpha"; Window = "older"; PackageConfig = "a.ini"; ReportDestination = "a" },
      [pscustomobject]@{ QueueRank = 2; Candidate = "beta"; Window = "later"; PackageConfig = "b.ini"; ReportDestination = "b" },
      [pscustomobject]@{ QueueRank = 4; Candidate = "gamma"; Window = "continuous"; PackageConfig = "c.ini"; ReportDestination = "c" }
   ) | Export-Csv -LiteralPath $validPath -NoTypeInformation -Encoding ASCII

   $plan = & $runner -ManifestPath $validPath -PortableRoots @("worker-a", "worker-b") `
      -UserAuthorizedFocusRisk -OutputPrefix "GENERIC_TEST" -MaxCpuPercent 73 `
      -TimeoutMinutesPerConfig 9 -PlanOnly
   if($plan.Rows -ne 3 -or $plan.Workers -ne 2 -or $plan.OutputPrefix -ne "GENERIC_TEST") {
      throw "Generic runner plan does not match the validated manifest."
   }
   if($plan.MaxCpuPercent -ne 73 -or $plan.TimeoutMinutesPerConfig -ne 9) {
      throw "Generic runner plan lost resource controls."
   }

   $duplicatePath = Join-Path $tempRoot "duplicate.csv"
   @(
      [pscustomobject]@{ QueueRank = 1; Candidate = "alpha"; Window = "older"; PackageConfig = "a.ini"; ReportDestination = "a" },
      [pscustomobject]@{ QueueRank = 1; Candidate = "beta"; Window = "later"; PackageConfig = "b.ini"; ReportDestination = "b" }
   ) | Export-Csv -LiteralPath $duplicatePath -NoTypeInformation -Encoding ASCII
   $duplicateRejected = $false
   try {
      & $runner -ManifestPath $duplicatePath -PortableRoots @("worker-a") `
         -UserAuthorizedFocusRisk -PlanOnly | Out-Null
   }
   catch {
      $duplicateRejected = $_.Exception.Message -match "must be unique"
   }
   if(!$duplicateRejected) { throw "Duplicate QueueRank values were not rejected." }

   $before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   $hardLockRejected = $false
   try {
      & $runner -ManifestPath $validPath -PortableRoots @("worker-a") `
         -UserAuthorizedFocusRisk -OutputPrefix "LOCK_TEST" | Out-Null
   }
   catch {
      $hardLockRejected = $_.Exception.Message -match "hard-locked"
   }
   $after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)
   if(!$hardLockRejected) { throw "Generic parallel runner did not honor the MT5 hard lock." }
   if($after.Count -gt $before.Count) { throw "Generic parallel runner created an MT5-family process while locked." }

   $runnerText = Get-Content -LiteralPath $runner -Raw
   foreach($token in @("run_mt5_portable_package_worker.ps1", "assert_mt5_launch_allowed.ps1", "UserAuthorizedFocusRisk", "MaxCpuPercent", "ExpectedRows", "PlanOnly")) {
      if($runnerText -notmatch [regex]::Escape($token)) { throw "Generic runner is missing required token: $token" }
   }

   [pscustomobject]@{
      Status = "PASS"
      ValidRows = $plan.Rows
      Workers = $plan.Workers
      DuplicateRanksRejected = $duplicateRejected
      HardLockRejected = $hardLockRejected
      MQL5Launched = $false
   }
}
finally {
   Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
