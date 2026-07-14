param(
   [string]$ProfilePath,
   [string]$CandidateName,
   [string]$OutDir,
   [string]$OutQueueManifest,
   [string]$OutPackageManifest,
   [string]$OutMarkdown,
   [string]$From = "2024.01.01",
   [string]$To = "2026.07.12",
   [string]$Window = "continuous_2024_2026",
   [int]$Model = 1,
   [string]$StopRule = "Reject if the broad window is red, too sparse, or drawdown is unacceptable."
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
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
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

if([string]::IsNullOrWhiteSpace($ProfilePath)) { throw "ProfilePath is required." }
if([string]::IsNullOrWhiteSpace($CandidateName)) { throw "CandidateName is required." }
if([string]::IsNullOrWhiteSpace($OutDir)) { throw "OutDir is required." }
if([string]::IsNullOrWhiteSpace($OutQueueManifest)) { throw "OutQueueManifest is required." }
if([string]::IsNullOrWhiteSpace($OutPackageManifest)) { throw "OutPackageManifest is required." }
if([string]::IsNullOrWhiteSpace($OutMarkdown)) { throw "OutMarkdown is required." }

$resolvedProfile = Resolve-RepoPath $ProfilePath
if(!(Test-Path -LiteralPath $resolvedProfile)) {
   throw "Profile missing: $resolvedProfile"
}

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

$setFileName = "$CandidateName.set"
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force
Copy-Item -LiteralPath $resolvedProfile -Destination (Join-Path $profileDir $setFileName) -Force

$inputs = Import-SetInputs $resolvedProfile
$configName = "001_{0}_{1}_m{2}.ini" -f $CandidateName, $Window, $Model
$reportName = "{0}_{1}_m{2}" -f $CandidateName, $Window, $Model
$configPath = Join-Path $configDir $configName
Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model

$queue = @([pscustomobject]@{
   QueueRank = 1
   Candidate = $CandidateName
   CandidateRank = 1
   SourceType = "single_profile"
   SourceRank = 1
   Phase = "single_profile_model$Model"
   Set = $setFileName
   Window = $Window
   From = $From
   To = $To
   Model = $Model
   Config = "configs\$configName"
   ExpectedReportName = $reportName
   ProfileSnapshot = "profiles\$setFileName"
   ProfileSha256 = $profileHash
   StopRule = $StopRule
})

$runRows = @([pscustomobject]@{
   QueueRank = 1
   Candidate = $CandidateName
   Phase = "single_profile_model$Model"
   PhaseLabel = "single profile Model$Model"
   Window = $Window
   Model = $Model
   PackageConfig = "$OutDir\configs\$configName"
   SourceConfig = "$OutDir\configs\$configName"
   ExpectedReportName = $reportName
   ReportDestination = "$OutDir\reports_here\$reportName"
   ProfileSha256 = $profileHash
   StopRule = $StopRule
})

$queuePath = Resolve-RepoPath $OutQueueManifest
$runPath = Resolve-RepoPath $OutPackageManifest
$mdPath = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $queuePath
Ensure-ParentDir $runPath
Ensure-ParentDir $mdPath
$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath $runPath -NoTypeInformation -Encoding ASCII

$md = @(
   "# Single Profile Test Package",
   "",
   "Offline package builder only. This does not launch MT5.",
   "",
   "- Candidate: ``$CandidateName``",
   "- Window: ``$Window``",
   "- From: ``$From``",
   "- To: ``$To``",
   "- Model: ``$Model``",
   "- Source hash: ``$sourceHash``",
   "- Profile hash: ``$profileHash``",
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
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
