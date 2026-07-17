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

function Get-PackageSourceHash([string]$ConfigPath) {
   $packageRoot = Split-Path -Parent (Split-Path -Parent $ConfigPath)
   $source = Join-Path $packageRoot "source\Professional_XAUUSD_EA.mq5"
   if(!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Package source is missing: $source" }
   return (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Test-ReportSourceIdentity([string]$Path, [string]$ExpectedHash) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
   return (Get-Content -LiteralPath $Path -Raw).IndexOf($ExpectedHash, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

$rows = [System.Collections.Generic.List[object]]::new()
$items = @(Import-Csv -LiteralPath $manifest | Where-Object {
   (([int]$_.QueueRank - 1) % $WorkerCount) -eq ($WorkerIndex - 1)
} | Sort-Object { [int]$_.QueueRank })

foreach($item in $items) {
   $config = Resolve-RepoPath ([string]$item.PackageConfig)
   $expectedSourceHash = Get-PackageSourceHash $config
   $destinationBase = Resolve-RepoPath ([string]$item.ReportDestination)
   $existing = @('.htm','.html','.xml') | ForEach-Object { $destinationBase + $_ } |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
   if($existing -and !(Test-ReportSourceIdentity $existing $expectedSourceHash)) {
      $existing = $null
   }
   $started = (Get-Date).ToString("s")
   $status = ""
   $reportPath = ""
   $evidence = ""
   $portableBinaryHash = ""
   $portableExpertRecompiled = $false
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
         if([string]$run.PackageSourceSha256 -ne $expectedSourceHash) {
            throw "Portable runner package-source identity mismatch."
         }
         if(!(Test-ReportSourceIdentity $sourceReport $expectedSourceHash)) {
            throw "Portable report does not embed the expected package-source identity."
         }
         $portableBinaryHash = [string]$run.PortableBinarySha256
         $portableExpertRecompiled = [bool]$run.PortableExpertRecompiled
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
      PackageSourceSha256 = $expectedSourceHash
      PortableBinarySha256 = $portableBinaryHash
      PortableExpertRecompiled = $portableExpertRecompiled
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
