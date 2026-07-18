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
if(!$UserAuthorizedFocusRisk) { throw "Explicit focus-risk authorization is required." }
. (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1")
. (Join-Path $PSScriptRoot "mt5_report_identity_helpers.ps1")
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
   $configHash = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant()
   if($item.PSObject.Properties.Name -contains "ConfigSha256" -and
      ![string]::IsNullOrWhiteSpace([string]$item.ConfigSha256) -and
      $configHash -ne ([string]$item.ConfigSha256).ToUpperInvariant()) {
      throw "Package config identity mismatch at queue rank $($item.QueueRank)."
   }
   $expectedSourceHash = Get-PackageSourceHash $config
   if($item.PSObject.Properties.Name -contains "SourceSha256" -and
      ![string]::IsNullOrWhiteSpace([string]$item.SourceSha256) -and
      $expectedSourceHash -ne ([string]$item.SourceSha256).ToUpperInvariant()) {
      throw "Package source identity mismatch at queue rank $($item.QueueRank)."
   }
   $destinationBase = Resolve-RepoPath ([string]$item.ReportDestination)
   $expectedReportName = if($item.PSObject.Properties.Name -contains "ExpectedReportName" -and
                            ![string]::IsNullOrWhiteSpace([string]$item.ExpectedReportName)) {
      [string]$item.ExpectedReportName
   } else {
      [IO.Path]::GetFileName($destinationBase)
   }
   $identityPath = $destinationBase + ".identity.json"
   $existingCandidates = @(@('.htm','.html','.xml') | ForEach-Object { $destinationBase + $_ } |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
   $existing = if($existingCandidates.Count -eq 1) { $existingCandidates[0] } else { $null }
   $cachedIdentity = $null
   if($existing) {
      $cachedIdentity = Read-MT5ReportIdentityEvidence -ReportPath $existing `
         -IdentityPath $identityPath -ExpectedReportName $expectedReportName `
         -ConfigSha256 $configHash -SourceSha256 $expectedSourceHash
   }
   $started = (Get-Date).ToString("s")
   $status = ""
   $reportPath = ""
   $evidence = ""
   $portableBinaryHash = ""
   $portableExpertRecompiled = $false
   $reportHash = ""
   $reportIdentityReused = $false
   if($cachedIdentity) {
      $status = "REPORT_FOUND"
      $reportPath = $existing
      $portableBinaryHash = $cachedIdentity.PortableBinarySha256
      $reportHash = $cachedIdentity.ReportSha256
      $reportIdentityReused = $true
      $evidence = "Reused identity-bound package report."
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
         foreach($candidate in $existingCandidates) {
            if($candidate -ne $target) { Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue }
         }
         Copy-Item -LiteralPath $sourceReport -Destination $target -Force
         $identity = Write-MT5ReportIdentityEvidence -ReportPath $target `
            -IdentityPath $identityPath -ExpectedReportName $expectedReportName `
            -ConfigSha256 $configHash -SourceSha256 $expectedSourceHash `
            -PortableBinarySha256 $portableBinaryHash
         if(!$identity) { throw "Copied report identity evidence did not validate." }
         $status = "REPORT_FOUND"
         $reportPath = $target
         $reportHash = $identity.ReportSha256
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
      PackageConfigSha256 = $configHash
      PackageSourceSha256 = $expectedSourceHash
      PortableBinarySha256 = $portableBinaryHash
      PortableExpertRecompiled = $portableExpertRecompiled
      ReportSha256 = $reportHash
      ReportIdentityPath = $identityPath
      ReportIdentityReused = $reportIdentityReused
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
