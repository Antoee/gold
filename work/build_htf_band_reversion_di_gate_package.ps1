param(
   [string]$ExperimentalSourceDir = "outputs\htf_band_reversion_feature_experimental_source",
   [string]$BaseProfilePath = "outputs\CANDIDATE_HTF_BAND_REVERSION_RESEARCH_PROFILE.set",
   [string]$PackageDir = "outputs\htf_band_reversion_di_gate_model1_package",
   [string]$QueueManifestPath = "outputs\HTF_BAND_REVERSION_DI_GATE_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\HTF_BAND_REVERSION_DI_GATE_MODEL1_PACKAGE_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$sourcePath = (Resolve-Path (Join-Path $repo "$ExperimentalSourceDir\Professional_XAUUSD_EA.mq5")).Path
$profileSource = (Resolve-Path (Join-Path $repo $BaseProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$packageFull = Join-Path $repo $PackageDir

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
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$candidates = @(
   [pscustomobject]@{ Name = "di_off"; UseGate = "false"; Threshold = "-10" },
   [pscustomobject]@{ Name = "di_m12"; UseGate = "true"; Threshold = "-12" },
   [pscustomobject]@{ Name = "di_m10"; UseGate = "true"; Threshold = "-10" },
   [pscustomobject]@{ Name = "di_m8"; UseGate = "true"; Threshold = "-8" }
)
$windows = @(
   [pscustomobject]@{ Name = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Name = "middle_2019_2022"; From = "2019.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Name = "recent_2023_2026"; From = "2023.01.01"; To = "2026.07.12" }
)

$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($candidate in $candidates) {
   $inputs = Import-SetInputs $profileSource
   Set-InputLine -Inputs $inputs -Name "InpBandVWAPReversionUseDIEdgeGate" -Value $candidate.UseGate
   Set-InputLine -Inputs $inputs -Name "InpBandVWAPReversionMinDIEdge" -Value $candidate.Threshold
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value ("htf_band_reversion_{0}" -f $candidate.Name)
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "htf_band_reversion_di_gate_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value ("htf_band_reversion_{0}_model1.csv" -f $candidate.Name)

   $profileName = "htf_band_reversion_{0}.set" -f $candidate.Name
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_htf_band_reversion_{1}_{2}_m1.ini" -f $rank, $candidate.Name, $window.Name
      $reportName = "htf_band_reversion_{0}_{1}_m1" -f $candidate.Name, $window.Name
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000

      $stopRule = "Advance only a neighboring DI threshold plateau with positive net in all three eras, continuous PF >= 1.50, and adequate activity."
      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; CandidateRank = $rank
         SourceType = "htf_band_reversion_di_gate"; SourceRank = 1; Phase = "broad_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To
         Model = 1; Deposit = 10000; Config = "configs\$configName"; ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; Phase = "broad_model1"
         PhaseLabel = "HTF band reversion DI gate broad screen"; Window = $window.Name
         Model = 1; Deposit = 10000; PackageConfig = "$PackageDir\configs\$configName"
         SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
         ReportDestination = "$PackageDir\reports_here\$reportName"; ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Candidates = $candidates.Count
   Windows = $windows.Count
   Configurations = $rank
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
