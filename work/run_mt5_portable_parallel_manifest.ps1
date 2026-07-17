[CmdletBinding()]
param(
   [Parameter(Mandatory=$true)][string]$ManifestPath,
   [string[]]$PortableRoots = @(
      "work\mt5_portable_research",
      "work\mt5_portable_research_w2",
      "work\mt5_portable_research_w3",
      "work\mt5_portable_research_w4"
   ),
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')][string]$OutputPrefix = "MT5_PORTABLE_WORKER",
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,1440)][int]$TimeoutMinutesPerConfig = 15,
   [ValidateRange(1,300)][int]$ProgressIntervalSeconds = 20,
   [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if(!$UserAuthorizedFocusRisk) { throw "Explicit focus-risk authorization is required." }

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestCandidate = if([IO.Path]::IsPathRooted($ManifestPath)) {
   $ManifestPath
}
else {
   Join-Path $repo $ManifestPath
}
$manifest = (Resolve-Path -LiteralPath $manifestCandidate).Path
$items = @(Import-Csv -LiteralPath $manifest)
if($items.Count -lt 1) { throw "Manifest contains no configurations: $manifest" }

$requiredColumns = @("QueueRank", "Candidate", "Window", "PackageConfig", "ReportDestination")
$columns = @($items[0].PSObject.Properties.Name)
$missingColumns = @($requiredColumns | Where-Object { $_ -notin $columns })
if($missingColumns.Count -gt 0) {
   throw "Manifest is missing required columns: $($missingColumns -join ', ')"
}

$ranks = [System.Collections.Generic.List[int]]::new()
foreach($item in $items) {
   $rank = 0
   if(![int]::TryParse([string]$item.QueueRank, [ref]$rank) -or $rank -lt 1) {
      throw "Manifest QueueRank values must be positive integers. Invalid value: '$($item.QueueRank)'"
   }
   $ranks.Add($rank) | Out-Null
   foreach($column in @("Candidate", "Window", "PackageConfig", "ReportDestination")) {
      if([string]::IsNullOrWhiteSpace([string]$item.$column)) {
         throw "Manifest row $rank has an empty $column value."
      }
   }
}
if(@($ranks | Sort-Object -Unique).Count -ne $ranks.Count) {
   throw "Manifest QueueRank values must be unique."
}
if($PortableRoots.Count -lt 1) { throw "At least one portable worker is required." }
if(@($PortableRoots | Sort-Object -Unique).Count -ne $PortableRoots.Count) {
   throw "Portable worker roots must be unique."
}

$plan = [pscustomobject]@{
   Manifest = $manifest
   Rows = $items.Count
   Workers = $PortableRoots.Count
   OutputPrefix = $OutputPrefix
   MaxCpuPercent = $MaxCpuPercent
   TimeoutMinutesPerConfig = $TimeoutMinutesPerConfig
}
if($PlanOnly) {
   $plan
   return
}

$workerScript = Join-Path $PSScriptRoot "run_mt5_portable_package_worker.ps1"
if(!(Test-Path -LiteralPath $workerScript -PathType Leaf)) {
   throw "Portable package worker is missing: $workerScript"
}
$roots = @($PortableRoots | ForEach-Object {
   $candidate = if([IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $repo $_ }
   (Resolve-Path -LiteralPath $candidate).Path
})

$outputPaths = [System.Collections.Generic.List[string]]::new()
$jobs = [System.Collections.Generic.List[object]]::new()
for($index = 1; $index -le $roots.Count; ++$index) {
   $out = Join-Path $repo ("outputs\{0}_{1}.csv" -f $OutputPrefix, $index)
   Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
   $outputPaths.Add($out) | Out-Null
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
   Start-Sleep -Seconds $ProgressIntervalSeconds
   $completed = 0
   foreach($path in $outputPaths) {
      if(Test-Path -LiteralPath $path -PathType Leaf) {
         try {
            $completed += @(Import-Csv -LiteralPath $path -ErrorAction Stop).Count
         }
         catch {
            # A worker rewrites its CSV after every row; retry on the next progress interval.
         }
      }
   }
   Write-Output ("progress reports={0}/{1} running_jobs={2}" -f $completed, $items.Count, @($jobs | Where-Object State -eq "Running").Count)
} while(@($jobs | Where-Object State -eq "Running").Count -gt 0)

$jobs | Wait-Job | Out-Null
$workerOutput = @($jobs | Receive-Job)
$failed = @($jobs | Where-Object State -eq "Failed")
$jobs | Remove-Job -Force
if($failed.Count -gt 0) { throw "$($failed.Count) portable worker job(s) failed." }

$runRows = @($outputPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
   ForEach-Object { Import-Csv -LiteralPath $_ })
$errorCount = @($runRows | Where-Object Status -eq "ERROR").Count
$complete = $runRows.Count -eq $items.Count
$workerOutput
[pscustomobject]@{
   Workers = $roots.Count
   Rows = $runRows.Count
   ExpectedRows = $items.Count
   ReportsFound = @($runRows | Where-Object Status -eq "REPORT_FOUND").Count
   Errors = $errorCount
   Complete = $complete
   OutputPrefix = $OutputPrefix
}
if(!$complete -or $errorCount -gt 0) {
   throw "Portable batch failed: rows=$($runRows.Count)/$($items.Count), errors=$errorCount."
}
