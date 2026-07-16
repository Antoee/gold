param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5",
   [string]$ProfilePath = "outputs\three_lane_broad_screen_package\profiles\three_lane_ddb050.set",
   [string]$Candidate = "three_lane_ddb050",
   [string]$PackageDir = "outputs\three_lane_model4_validation_package",
   [string]$QueueManifestPath = "outputs\THREE_LANE_MODEL4_VALIDATION_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\THREE_LANE_MODEL4_VALIDATION_PACKAGE_MANIFEST.csv",
   [switch]$RecentContinuousOnly,
   [ValidateRange(100,100000000)][int]$Deposit = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$source = Join-Path $repo $SourcePath
$sourceProfile = Join-Path $repo $ProfilePath
$packageFull = Join-Path $repo $PackageDir
foreach($required in @($source, $sourceProfile)) {
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
$expectedSourceHash = "45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90"
if($sourceHash -ne $expectedSourceHash) { throw "Three-lane source hash changed: $sourceHash" }
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$candidate = $Candidate
$profileName = "$candidate.set"
$profilePath = Join-Path $profileDir $profileName
Copy-Item -LiteralPath $sourceProfile -Destination $profilePath -Force
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
$inputs = Import-SetInputs $profilePath
Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "${candidate}_model4_validation"
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $profilePath -Encoding ASCII
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$windows = if($RecentContinuousOnly) {
   @([pscustomobject]@{ Rank = 1; Name = "continuous_2019_2026"; From = "2019.01.01"; To = "2026.07.12" })
}
else {
   @(
      [pscustomobject]@{ Rank = 1; Name = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12" },
      [pscustomobject]@{ Rank = 2; Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
      [pscustomobject]@{ Rank = 3; Name = "middle_2019_2022"; From = "2019.01.01"; To = "2022.12.31" },
      [pscustomobject]@{ Rank = 4; Name = "recent_2023_2026"; From = "2023.01.01"; To = "2026.07.12" }
   )
}

$queueRows = [Collections.Generic.List[object]]::new()
$manifestRows = [Collections.Generic.List[object]]::new()
foreach($window in $windows) {
   $configName = "{0:000}_{1}_{2}_m4.ini" -f $window.Rank, $candidate, $window.Name
   $reportName = "${candidate}_$($window.Name)_m4"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
      -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit $Deposit
   $stopRule = "Reject if any real-tick era is non-positive, continuous PF is below 1.20, drawdown exceeds 3%, or risk-adjusted performance is weaker than the frozen two-lane candidate."

   $queueRows.Add([pscustomobject]@{
      QueueRank = $window.Rank; Candidate = $candidate; CandidateRank = 1
      SourceType = "three_lane_model4_validation"; SourceRank = 1; Phase = "model4_broad_gate"
      Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 4; Deposit = $Deposit
      Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
      ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
   }) | Out-Null
   $manifestRows.Add([pscustomobject]@{
      QueueRank = $window.Rank; Candidate = $candidate; Phase = "model4_broad_gate"
      PhaseLabel = "Three-lane $candidate real-tick broad validation"; Window = $window.Name
      Model = 4; Deposit = $Deposit; PackageConfig = "$PackageDir\configs\$configName"
      SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
      ReportDestination = "$PackageDir\reports_here\$reportName"; ProfileSha256 = $profileHash
      SourceSha256 = $sourceHash; StopRule = $stopRule
   }) | Out-Null
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   ProfileHash = $profileHash
   Candidate = $candidate
   Windows = @($windows).Count
   Configs = $queueRows.Count
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
