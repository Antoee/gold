param(
   [Parameter(Mandatory=$true)][string]$ManifestPath,
   [Parameter(Mandatory=$true)][string]$PortableRoot,
   [Parameter(Mandatory=$true)][ValidateRange(1,32)][int]$WorkerIndex,
   [Parameter(Mandatory=$true)][ValidateRange(1,32)][int]$WorkerCount,
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [int]$TimeoutMinutesPerConfig = 15,
   [string]$OutCsv = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifest = (Resolve-Path -LiteralPath $ManifestPath).Path
$portable = (Resolve-Path -LiteralPath $PortableRoot).Path
$runner = Join-Path $PSScriptRoot "run_mt5_portable_config_hidden.ps1"
if([string]::IsNullOrWhiteSpace($OutCsv)) {
   $OutCsv = Join-Path $repo ("outputs\M15_TREND_PULLBACK_PORTABLE_WORKER_{0}.csv" -f $WorkerIndex)
}
elseif(![IO.Path]::IsPathRooted($OutCsv)) {
   $OutCsv = Join-Path $repo $OutCsv
}

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

$rows = [System.Collections.Generic.List[object]]::new()
$items = @(Import-Csv -LiteralPath $manifest | Where-Object {
   (([int]$_.QueueRank - 1) % $WorkerCount) -eq ($WorkerIndex - 1)
} | Sort-Object { [int]$_.QueueRank })

foreach($item in $items) {
   $config = Resolve-RepoPath ([string]$item.PackageConfig)
   $destinationBase = Resolve-RepoPath ([string]$item.ReportDestination)
   $existing = @('.htm','.html','.xml') | ForEach-Object { $destinationBase + $_ } |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
   $started = (Get-Date).ToString("s")
   $status = ""
   $reportPath = ""
   $evidence = ""
   if($existing) {
      $status = "REPORT_FOUND"
      $reportPath = $existing
      $evidence = "Reused existing non-empty package report."
   }
   else {
      try {
         $run = & $runner -PortableRoot $portable -ConfigPath $config -UserAuthorizedFocusRisk `
            -MaxCpuPercent $MaxCpuPercent -TimeoutMinutes $TimeoutMinutesPerConfig
         $sourceReport = [string]$run.Report
         $extension = [IO.Path]::GetExtension($sourceReport)
         $target = $destinationBase + $extension
         $parent = Split-Path -Parent $target
         if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
         Copy-Item -LiteralPath $sourceReport -Destination $target -Force
         $status = "REPORT_FOUND"
         $reportPath = $target
         $evidence = "Portable worker exported and copied the full MT5 report."
      }
      catch {
         $status = "ERROR"
         $evidence = $_.Exception.Message
      }
   }
   $rows.Add([pscustomobject]@{
      Worker = $WorkerIndex
      QueueRank = $item.QueueRank
      Candidate = $item.Candidate
      Window = $item.Window
      Status = $status
      ReportPath = $reportPath
      Evidence = $evidence
      Started = $started
      Finished = (Get-Date).ToString("s")
   }) | Out-Null
   $rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation -Encoding ASCII
}

[pscustomobject]@{
   Worker = $WorkerIndex
   Rows = $rows.Count
   ReportsFound = @($rows | Where-Object Status -eq 'REPORT_FOUND').Count
   Errors = @($rows | Where-Object Status -eq 'ERROR').Count
   OutCsv = $OutCsv
}
