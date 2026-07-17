param(
   [string]$ManifestPath = "outputs\INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string[]]$PortableRoots = @(
      "work\mt5_portable_research",
      "work\mt5_portable_research_w2",
      "work\mt5_portable_research_w3",
      "work\mt5_portable_research_w4"
   ),
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [int]$TimeoutMinutesPerConfig = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if(!$UserAuthorizedFocusRisk) { throw "Explicit focus-risk authorization is required." }
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifest = (Resolve-Path (Join-Path $repo $ManifestPath)).Path
$workerScript = Join-Path $PSScriptRoot "run_mt5_portable_package_worker.ps1"
$roots = @($PortableRoots | ForEach-Object { (Resolve-Path (Join-Path $repo $_)).Path })
if($roots.Count -lt 1) { throw "At least one portable worker is required." }

$jobs = [System.Collections.Generic.List[object]]::new()
for($index = 1; $index -le $roots.Count; ++$index) {
   $out = Join-Path $repo ("outputs\M15_TREND_PULLBACK_PORTABLE_WORKER_{0}.csv" -f $index)
   Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
   $job = Start-Job -ScriptBlock {
      param($Script, $Manifest, $Root, $Index, $Count, $Cpu, $Timeout, $Out)
      & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script `
         -ManifestPath $Manifest -PortableRoot $Root -WorkerIndex $Index -WorkerCount $Count `
         -UserAuthorizedFocusRisk -MaxCpuPercent $Cpu -TimeoutMinutesPerConfig $Timeout -OutCsv $Out
      if($LASTEXITCODE -ne 0) { throw "Worker $Index exited with code $LASTEXITCODE" }
   } -ArgumentList $workerScript, $manifest, $roots[$index - 1], $index, $roots.Count, $MaxCpuPercent, $TimeoutMinutesPerConfig, $out
   $jobs.Add($job) | Out-Null
}

do {
   Start-Sleep -Seconds 20
   $completed = 0
   foreach($path in (Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "M15_TREND_PULLBACK_PORTABLE_WORKER_*.csv" -ErrorAction SilentlyContinue)) {
      $completed += @(Import-Csv -LiteralPath $path.FullName).Count
   }
   Write-Output ("progress reports={0}/30 running_jobs={1}" -f $completed, @($jobs | Where-Object State -eq "Running").Count)
} while(@($jobs | Where-Object State -eq "Running").Count -gt 0)

$jobs | Wait-Job | Out-Null
$workerOutput = @($jobs | Receive-Job)
$failed = @($jobs | Where-Object State -eq "Failed")
$jobs | Remove-Job -Force
if($failed.Count -gt 0) { throw "$($failed.Count) portable worker job(s) failed." }

$runRows = @(Get-ChildItem -LiteralPath (Join-Path $repo "outputs") -Filter "M15_TREND_PULLBACK_PORTABLE_WORKER_*.csv" |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$workerOutput
[pscustomobject]@{
   Workers = $roots.Count
   Rows = $runRows.Count
   ReportsFound = @($runRows | Where-Object Status -eq "REPORT_FOUND").Count
   Errors = @($runRows | Where-Object Status -eq "ERROR").Count
}
