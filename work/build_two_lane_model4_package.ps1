param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_TWO_LANE_ISOLATED.mq5",
   [string]$BroadPackageDir = "outputs\two_lane_isolated_execution_screen_package",
   [string]$PackageDir = "outputs\two_lane_risk010_model4_package",
   [string]$QueueManifestPath = "outputs\TWO_LANE_RISK010_MODEL4_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\TWO_LANE_RISK010_MODEL4_PACKAGE_MANIFEST.csv",
   [ValidateRange(100,100000000)][int]$Deposit = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$source = Join-Path $repo $SourcePath
$broadPackage = Join-Path $repo $BroadPackageDir
$packageFull = Join-Path $repo $PackageDir
foreach($required in @($source, $broadPackage)) {
   if(!(Test-Path -LiteralPath $required)) { throw "Required Model4 artifact missing: $required" }
}

if(Test-Path -LiteralPath $packageFull) {
   $resolved = (Resolve-Path -LiteralPath $packageFull).Path
   if(!$resolved.StartsWith($outputsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clear non-outputs directory: $resolved"
   }
   Remove-Item -LiteralPath $resolved -Recurse -Force
}

$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$expectedSourceHash = "007B8DCF4A9A66652B1F34A32893ECA676165B88239119270A9B4D138F184472"
if($sourceHash -ne $expectedSourceHash) { throw "Two-lane source hash changed: $sourceHash" }
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$candidate = "two_lane_risk010"
$profileSource = Join-Path $broadPackage "profiles\$candidate.set"
if(!(Test-Path -LiteralPath $profileSource)) { throw "Frozen broad profile missing: $profileSource" }
$profileName = "$candidate.set"
$profilePath = Join-Path $profileDir $profileName
Copy-Item -LiteralPath $profileSource -Destination $profilePath -Force
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
$expectedProfileHash = "7CABA7BFB0C24BE307B261E892F36D7F8C5609B4265E5951543487E95EBDA44D"
if($profileHash -ne $expectedProfileHash) { throw "Frozen risk010 profile hash changed: $profileHash" }
$inputs = Import-SetInputs $profilePath

$windows = @(
   [pscustomobject]@{ Rank = 1; Name = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Rank = 2; Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Rank = 3; Name = "middle_2019_2022"; From = "2019.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Rank = 4; Name = "recent_2023_2026"; From = "2023.01.01"; To = "2026.07.12" }
)

$queueRows = [Collections.Generic.List[object]]::new()
$manifestRows = [Collections.Generic.List[object]]::new()
foreach($window in $windows) {
   $configName = "{0:000}_{1}_{2}_m4.ini" -f $window.Rank, $candidate, $window.Name
   $reportName = "$($candidate)_$($window.Name)_m4"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
      -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit $Deposit
   $stopRule = "Reject if any broad era is non-positive, continuous PF is below 1.20, reports are missing, or real ticks materially contradict Model1."

   $queueRows.Add([pscustomobject]@{
      QueueRank = $window.Rank; Candidate = $candidate; CandidateRank = 1
      SourceType = "two_lane_risk010_model4"; SourceRank = 1; Phase = "model4_broad_gate"
      Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To
      Model = 4; Deposit = $Deposit; Config = "configs\$configName"; ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; SourceSha256 = $sourceHash
      StopRule = $stopRule
   }) | Out-Null
   $manifestRows.Add([pscustomobject]@{
      QueueRank = $window.Rank; Candidate = $candidate; Phase = "model4_broad_gate"
      PhaseLabel = "Conservative two-lane real-tick broad gate"; Window = $window.Name; Model = 4; Deposit = $Deposit
      PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
      ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
      ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
   }) | Out-Null
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   ProfileHash = $profileHash
   Candidate = $candidate
   Windows = $windows.Count
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
