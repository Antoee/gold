param(
   [string]$ProfilePath = "outputs\lowatr_exit_sweep_package\profiles\lowatr_exit_peak_r20.set",
   [string]$CandidateName = "lowatr_exit_peak_r20",
   [string]$OutDir = "outputs\lowatr_peak_r20_split_package",
   [string]$OutQueueManifest = "outputs\LOWATR_PEAK_R20_SPLIT_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\LOWATR_PEAK_R20_SPLIT_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\LOWATR_PEAK_R20_SPLIT_PACKAGE.md",
   [int]$Model = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function Clear-OutputDirSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   $outputs = (Resolve-Path -LiteralPath (Join-Path $repo "outputs")).Path
   $fullParent = Split-Path -Parent $resolved
   if($fullParent -and !(Test-Path -LiteralPath $fullParent)) {
      New-Item -ItemType Directory -Path $fullParent -Force | Out-Null
   }
   if(Test-Path -LiteralPath $resolved) {
      $actual = (Resolve-Path -LiteralPath $resolved).Path
      if(!$actual.StartsWith($outputs, [System.StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $actual"
      }
      Remove-Item -LiteralPath $actual -Recurse -Force
   }
   New-Item -ItemType Directory -Path $resolved -Force | Out-Null
}

$resolvedProfile = Resolve-RepoPath $ProfilePath
if(!(Test-Path -LiteralPath $resolvedProfile)) { throw "Profile missing: $resolvedProfile" }

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $resolvedProfile -Algorithm SHA256).Hash

$packageDir = Resolve-RepoPath $OutDir
Clear-OutputDirSafe $packageDir
$configDir = Join-Path $packageDir "configs"
$profileDir = Join-Path $packageDir "profiles"
$reportDir = Join-Path $packageDir "reports_here"
$sourceDir = Join-Path $packageDir "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force
$setFileName = "$CandidateName.set"
Copy-Item -LiteralPath $resolvedProfile -Destination (Join-Path $profileDir $setFileName) -Force

$windows = @(
   [pscustomobject]@{ Window = "2024_full"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2025_full"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" }
)

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($window in $windows) {
   $rank++
   $inputs = Import-SetInputs $resolvedProfile
   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $CandidateName, $window.Window, $Model
   $reportName = "{0}_split_{1}_m{2}" -f $CandidateName, $window.Window, $Model
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model

   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $CandidateName
      CandidateRank = 1
      SourceType = "year_split"
      SourceRank = $rank
      Phase = "phase0_yearly_model1"
      Set = $setFileName
      Window = $window.Window
      From = $window.From
      To = $window.To
      Model = $Model
      Config = "configs\$configName"
      ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$setFileName"
      ProfileSha256 = $profileHash
      StopRule = "Reject if any yearly split is red, too sparse, or has weak recovery."
   }) | Out-Null

   $runRows.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $CandidateName
      Phase = "phase0_yearly_model1"
      PhaseLabel = "yearly Model1 split"
      Window = $window.Window
      Model = $Model
      PackageConfig = "$OutDir\configs\$configName"
      SourceConfig = "$OutDir\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "$OutDir\reports_here\$reportName"
      ProfileSha256 = $profileHash
      StopRule = "Reject if any yearly split is red, too sparse, or has weak recovery."
   }) | Out-Null
}

$queuePath = Resolve-RepoPath $OutQueueManifest
$runPath = Resolve-RepoPath $OutPackageManifest
$mdPath = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $queuePath
Ensure-ParentDir $runPath
Ensure-ParentDir $mdPath

$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath $runPath -NoTypeInformation -Encoding ASCII

$md = @(
   "# LowATR Peak R20 Split Package",
   "",
   "Offline package builder only. This does not launch MT5.",
   "",
   "- Candidate: ``$CandidateName``",
   "- Source hash: ``$sourceHash``",
   "- Profile hash: ``$profileHash``",
   "- Model: ``$Model``",
   "- Windows: ``$($windows.Count)``",
   "",
   "## Files",
   "",
   "- Queue manifest: ``$OutQueueManifest``",
   "- Runner manifest: ``$OutPackageManifest``",
   "- Package dir: ``$OutDir``"
)
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   ProfileHash = $profileHash
   Windows = $windows.Count
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
