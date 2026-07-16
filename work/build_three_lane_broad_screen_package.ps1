param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5",
   [string]$BaseProfilePath = "outputs\two_lane_isolated_execution_screen_package\profiles\two_lane_risk010.set",
   [string]$DonchianProfilePath = "outputs\daily_donchian_channel_exit_realtick_package\profiles\ddb_ch_lb20e150_x5.set",
   [string]$PackageDir = "outputs\three_lane_broad_screen_package",
   [string]$QueueManifestPath = "outputs\THREE_LANE_BROAD_SCREEN_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\THREE_LANE_BROAD_SCREEN_PACKAGE_MANIFEST.csv",
   [ValidateRange(100,100000000)][int]$Deposit = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$source = Join-Path $repo $SourcePath
$baseProfile = Join-Path $repo $BaseProfilePath
$donchianProfile = Join-Path $repo $DonchianProfilePath
$packageFull = Join-Path $repo $PackageDir
foreach($required in @($source, $baseProfile, $donchianProfile)) {
   if(!(Test-Path -LiteralPath $required)) { throw "Required three-lane artifact missing: $required" }
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
if($sourceHash -ne $expectedSourceHash) { throw "Three-lane source changed: $sourceHash" }
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$baseInputs = Import-SetInputs $baseProfile
$donchianInputs = Import-SetInputs $donchianProfile
$donchianNames = @($donchianInputs.Keys | Where-Object {
   $_ -eq "InpUseDailyDonchianBreakoutLane" -or $_ -like "InpDailyDonchian*"
})
if($donchianNames.Count -ne 20) {
   throw "Expected 20 frozen Donchian module inputs, found $($donchianNames.Count)."
}

$variants = @(
   [pscustomobject]@{ Rank = 1; Candidate = "three_lane_ddb040"; EnableDonchian = $true; DonchianRisk = "0.40" },
   [pscustomobject]@{ Rank = 2; Candidate = "three_lane_ddb045"; EnableDonchian = $true; DonchianRisk = "0.45" },
   [pscustomobject]@{ Rank = 3; Candidate = "three_lane_ddb050"; EnableDonchian = $true; DonchianRisk = "0.50" },
   [pscustomobject]@{ Rank = 4; Candidate = "three_lane_ddb055"; EnableDonchian = $true; DonchianRisk = "0.55" },
   [pscustomobject]@{ Rank = 5; Candidate = "three_lane_ddb060"; EnableDonchian = $true; DonchianRisk = "0.60" }
)
$windows = @(
   [pscustomobject]@{ Rank = 1; Name = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Rank = 2; Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Rank = 3; Name = "middle_2019_2022"; From = "2019.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Rank = 4; Name = "recent_2023_2026"; From = "2023.01.01"; To = "2026.07.12" }
)

$queueRows = [Collections.Generic.List[object]]::new()
$manifestRows = [Collections.Generic.List[object]]::new()
$queueRank = 0
foreach($variant in $variants) {
   $inputs = [ordered]@{}
   foreach($name in $baseInputs.Keys) { $inputs[$name] = $baseInputs[$name] }
   foreach($name in $donchianNames) { $inputs[$name] = $donchianInputs[$name] }

   Set-InputLine -Inputs $inputs -Name "InpUseDailyDonchianBreakoutLane" -Value $variant.EnableDonchian.ToString().ToLowerInvariant()
   Set-InputLine -Inputs $inputs -Name "InpDailyDonchianStandaloneMode" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpDailyDonchianBypassPrimarySession" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpDailyDonchianUseIsolatedExecution" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpDailyDonchianUseTakeProfit" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpDailyDonchianRiskMultiplier" -Value $variant.DonchianRisk
   Set-InputLine -Inputs $inputs -Name "InpUseLaneSpecificMonthlyEntryCaps" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpMagicNumber" -Value "26071630"
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Candidate
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "three_lane_isolated_model1_broad_screen"

   $profileName = "$($variant.Candidate).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $queueRank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $queueRank, $variant.Candidate, $window.Name
      $reportName = "$($variant.Candidate)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit $Deposit
      $stopRule = "Reject if any broad era is non-positive, continuous PF is below 1.20, drawdown exceeds 3%, or neighboring risk values show a narrow unstable optimum."

      $queueRows.Add([pscustomobject]@{
         QueueRank = $queueRank; Candidate = $variant.Candidate; CandidateRank = $variant.Rank
         SourceType = "three_lane_broad_screen"; SourceRank = 1; Phase = "model1_broad_gate"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = $Deposit
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; DonchianEnabled = $variant.EnableDonchian
         DonchianRiskMultiplier = $variant.DonchianRisk; LaneSpecificMonthlyCaps = $true; StopRule = $stopRule
      }) | Out-Null
      $manifestRows.Add([pscustomobject]@{
         QueueRank = $queueRank; Candidate = $variant.Candidate; Phase = "model1_broad_gate"
         PhaseLabel = "Isolated M15 plus H1 plus D1 broad screen"; Window = $window.Name; Model = 1; Deposit = $Deposit
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Variants = $variants.Count
   Windows = $windows.Count
   Configs = $queueRows.Count
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
