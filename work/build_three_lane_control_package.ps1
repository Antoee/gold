param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5",
   [string]$PackageDir = "outputs\three_lane_control_package",
   [string]$QueueManifestPath = "outputs\THREE_LANE_CONTROL_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\THREE_LANE_CONTROL_PACKAGE_MANIFEST.csv",
   [ValidateRange(100,100000000)][int]$Deposit = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$source = Join-Path $repo $SourcePath
$packageFull = Join-Path $repo $PackageDir
if(!(Test-Path -LiteralPath $source)) { throw "Three-lane source missing: $source" }

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
if($sourceHash -ne $expectedSourceHash) { throw "Three-lane source changed: $sourceHash" }
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$controls = @(
   [pscustomobject]@{
      Rank = 1; Candidate = "three_lane_two_lane_default_off_control"
      Profile = "outputs\two_lane_isolated_execution_screen_package\profiles\two_lane_risk010.set"
      ExpectedNet = "427.61"; ExpectedPF = "2.83"; ExpectedTrades = "51"
   },
   [pscustomobject]@{
      Rank = 2; Candidate = "three_lane_donchian_compat_control"
      Profile = "outputs\daily_donchian_channel_exit_realtick_package\profiles\ddb_ch_lb20e150_x5.set"
      ExpectedNet = "440.14"; ExpectedPF = "1.41"; ExpectedTrades = "51"
   }
)

$queueRows = [Collections.Generic.List[object]]::new()
$manifestRows = [Collections.Generic.List[object]]::new()
foreach($control in $controls) {
   $profileSource = Join-Path $repo $control.Profile
   if(!(Test-Path -LiteralPath $profileSource)) { throw "Control profile missing: $profileSource" }
   $profileName = "$($control.Candidate).set"
   $profilePath = Join-Path $profileDir $profileName
   Copy-Item -LiteralPath $profileSource -Destination $profilePath -Force
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   $inputs = Import-SetInputs $profilePath

   $configName = "{0:000}_{1}_m1.ini" -f $control.Rank, $control.Candidate
   $reportName = "$($control.Candidate)_continuous_2015_2026_m1"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
      -ReportName $reportName -From "2015.01.01" -To "2026.07.12" -Inputs $inputs -Model 1 -Deposit $Deposit

   $stopRule = "Exact compatibility control: reject the three-lane source if net, PF, or trade count differs materially from the frozen source result."
   $queueRows.Add([pscustomobject]@{
      QueueRank = $control.Rank; Candidate = $control.Candidate; CandidateRank = $control.Rank
      SourceType = "three_lane_control"; SourceRank = 1; Phase = "default_off_model1_control"
      Set = $profileName; Window = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12"
      Model = 1; Deposit = $Deposit; Config = "configs\$configName"; ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; SourceSha256 = $sourceHash
      OriginalProfile = $control.Profile; ExpectedNet = $control.ExpectedNet; ExpectedPF = $control.ExpectedPF
      ExpectedTrades = $control.ExpectedTrades; StopRule = $stopRule
   }) | Out-Null
   $manifestRows.Add([pscustomobject]@{
      QueueRank = $control.Rank; Candidate = $control.Candidate; Phase = "default_off_model1_control"
      PhaseLabel = "Three-lane default-off compatibility control"; Window = "continuous_2015_2026"
      Model = 1; Deposit = $Deposit; PackageConfig = "$PackageDir\configs\$configName"
      SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
      ReportDestination = "$PackageDir\reports_here\$reportName"; ProfileSha256 = $profileHash
      SourceSha256 = $sourceHash; StopRule = $stopRule
   }) | Out-Null
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Controls = $controls.Count
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
