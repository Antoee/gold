param(
   [string]$ProfileDir = "outputs\peak_r20_drawdown_sweep_package\profiles",
   [string]$OutDir = "outputs\peak_r20_drawdown_shortlist_validation_package",
   [string]$OutQueueManifest = "outputs\PEAK_R20_DRAWDOWN_SHORTLIST_QUEUE.csv",
   [string]$OutPackageManifest = "outputs\PEAK_R20_DRAWDOWN_SHORTLIST_PACKAGE_MANIFEST.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_DRAWDOWN_SHORTLIST_PACKAGE.md",
   [string[]]$Candidates = @("r10_base", "r10_dailytrail35", "r10_loss_scale_25", "r10_loss_scale_15", "r10_profit_guard40"),
   [string]$From = "2024.01.01",
   [string]$To = "2026.07.12",
   [int]$Model = 4
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

$resolvedProfileDir = Resolve-RepoPath $ProfileDir
if(!(Test-Path -LiteralPath $resolvedProfileDir)) {
   throw "Profile directory missing: $resolvedProfileDir"
}

$sourcePath = Join-Path $repo "Professional_XAUUSD_EA.mq5"
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash

$packageDir = Resolve-RepoPath $OutDir
Clear-OutputDirSafe $packageDir
$configDir = Join-Path $packageDir "configs"
$profileOutDir = Join-Path $packageDir "profiles"
$reportDir = Join-Path $packageDir "reports_here"
$sourceDir = Join-Path $packageDir "source"
New-Item -ItemType Directory -Path $configDir, $profileOutDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($candidate in $Candidates) {
   $rank++
   $sourceSet = Join-Path $resolvedProfileDir ("{0}.set" -f $candidate)
   if(!(Test-Path -LiteralPath $sourceSet)) {
      throw "Candidate profile missing: $sourceSet"
   }

   $setName = "{0}.set" -f $candidate
   $setPath = Join-Path $profileOutDir $setName
   Copy-Item -LiteralPath $sourceSet -Destination $setPath -Force
   $profileHash = (Get-FileHash -LiteralPath $setPath -Algorithm SHA256).Hash
   $inputs = Import-SetInputs $setPath

   $window = "continuous_2024_2026"
   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $rank, $candidate, $window, $Model
   $reportName = "peak_r20_dd_short_{0}_{1}_m{2}" -f $candidate, $window, $Model
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model

   $stopRule = "Reject unless Model4 keeps positive profit, acceptable drawdown, and better risk-adjusted behavior than the R10 baseline."
   $queue.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $candidate
      CandidateRank = $rank
      SourceType = "peak_r20_drawdown_shortlist"
      SourceRank = $rank
      Phase = "phase1_model4_shortlist"
      Set = $setName
      Window = $window
      From = $From
      To = $To
      Model = $Model
      Config = "configs\$configName"
      ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$setName"
      ProfileSha256 = $profileHash
      StopRule = $stopRule
      Purpose = "Model4 real-tick validation of the drawdown-sweep shortlist."
   }) | Out-Null

   $runRows.Add([pscustomobject]@{
      QueueRank = $rank
      Candidate = $candidate
      Phase = "phase1_model4_shortlist"
      PhaseLabel = "Peak R20 R10 drawdown shortlist Model4"
      Window = $window
      Model = $Model
      PackageConfig = "$OutDir\configs\$configName"
      SourceConfig = "$OutDir\configs\$configName"
      ExpectedReportName = $reportName
      ReportDestination = "$OutDir\reports_here\$reportName"
      ProfileSha256 = $profileHash
      StopRule = $stopRule
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

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Peak R20 R10 Drawdown Shortlist Validation Package") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline package builder only. This does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Source hash: ``$sourceHash``") | Out-Null
$md.Add("- Model: ``$Model``") | Out-Null
$md.Add("- Candidates: ``$($Candidates -join ', ')``") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Files") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Queue manifest: ``$OutQueueManifest``") | Out-Null
$md.Add("- Runner manifest: ``$OutPackageManifest``") | Out-Null
$md.Add("- Package dir: ``$OutDir``") | Out-Null
$md | Set-Content -LiteralPath $mdPath -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Candidates = $Candidates.Count
   QueueManifest = $OutQueueManifest
   PackageManifest = $OutPackageManifest
   PackageDir = $OutDir
}
