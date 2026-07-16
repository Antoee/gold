param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5",
   [string]$BroadPackageDir = "outputs\three_lane_broad_screen_package",
   [string]$Candidate = "three_lane_ddb050",
   [string]$PackageDir = "outputs\three_lane_yearly_model1_package",
   [string]$QueueManifestPath = "outputs\THREE_LANE_YEARLY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\THREE_LANE_YEARLY_MODEL1_PACKAGE_MANIFEST.csv",
   [ValidateSet(1,4)][int]$Model = 1,
   [ValidateRange(100,100000000)][int]$Deposit = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$source = Join-Path $repo $SourcePath
$broadPackage = Join-Path $repo $BroadPackageDir
$sourceProfile = Join-Path $broadPackage "profiles\$Candidate.set"
$packageFull = Join-Path $repo $PackageDir
foreach($required in @($source, $sourceProfile)) {
   if(!(Test-Path -LiteralPath $required)) { throw "Required yearly artifact missing: $required" }
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
$expectedSourceHash = "45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90"
if($sourceHash -ne $expectedSourceHash) { throw "Three-lane source hash changed: $sourceHash" }
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$profileName = "$Candidate.set"
$profilePath = Join-Path $profileDir $profileName
Copy-Item -LiteralPath $sourceProfile -Destination $profilePath -Force
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
$inputs = Import-SetInputs $profilePath

$years = 2015..2026
$queueRows = [Collections.Generic.List[object]]::new()
$manifestRows = [Collections.Generic.List[object]]::new()
$queueRank = 0
foreach($year in $years) {
   $queueRank++
   $from = "$year.01.01"
   $to = if($year -eq 2026) { "2026.07.12" } else { "$year.12.31" }
   $window = if($year -eq 2026) { "2026_ytd" } else { "$year" }
   $configName = "{0:000}_{1}_{2}_m{3}.ini" -f $queueRank, $Candidate, $window, $Model
   $reportName = "${Candidate}_${window}_m${Model}"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
      -ReportName $reportName -From $from -To $to -Inputs $inputs -Model $Model -Deposit $Deposit
   $stopRule = "Reject promotion for material red active years, missing reports, excessive yearly drawdown, or concentration in one regime."

   $queueRows.Add([pscustomobject]@{
      QueueRank = $queueRank; Candidate = $Candidate; CandidateRank = 1
      SourceType = "three_lane_yearly_model${Model}"; SourceRank = 1; Phase = "yearly_model${Model}_gate"
      Set = $profileName; Window = $window; From = $from; To = $to; Model = $Model; Deposit = $Deposit
      Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
      ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
   }) | Out-Null
   $manifestRows.Add([pscustomobject]@{
      QueueRank = $queueRank; Candidate = $Candidate; Phase = "yearly_model${Model}_gate"
      PhaseLabel = "Three-lane restarted yearly Model${Model} gate"; Window = $window; Model = $Model; Deposit = $Deposit
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
   Candidate = $Candidate
   Model = $Model
   Years = $years.Count
   Configs = $queueRows.Count
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
