param(
   [string]$SourcePackageDir = "outputs\htf_band_reversion_di_gate_model1_package",
   [string]$PackageDir = "outputs\htf_band_reversion_di_gate_model4_package",
   [string]$QueueManifestPath = "outputs\HTF_BAND_REVERSION_DI_GATE_MODEL4_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\HTF_BAND_REVERSION_DI_GATE_MODEL4_PACKAGE_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$sourcePackage = (Resolve-Path (Join-Path $repo $SourcePackageDir)).Path
$sourcePath = Join-Path $sourcePackage "source\Professional_XAUUSD_EA.mq5"
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

$candidateNames = @("di_off", "di_m12", "di_m10")
$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($candidate in $candidateNames) {
   $sourceProfile = Join-Path $sourcePackage ("profiles\htf_band_reversion_{0}.set" -f $candidate)
   if(!(Test-Path -LiteralPath $sourceProfile)) { throw "Profile missing: $sourceProfile" }

   $inputs = Import-SetInputs $sourceProfile
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "htf_band_reversion_di_gate_continuous_model4"
   Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value ("htf_band_reversion_{0}_model4.csv" -f $candidate)

   $profileName = "htf_band_reversion_{0}.set" -f $candidate
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   $rank++
   $configName = "{0:000}_htf_band_reversion_{1}_continuous_2015_2026_m4.ini" -f $rank, $candidate
   $reportName = "htf_band_reversion_{0}_continuous_2015_2026_m4" -f $candidate
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
      -ReportName $reportName -From "2015.01.01" -To "2026.07.12" -Inputs $inputs -Model 4 -Deposit 10000

   $stopRule = "Require exact gate-off reproduction; gated candidates need net > 0, PF >= 1.50, DD <= 3%, at least 24 trades, and agreement with the Model1 plateau."
   $queueRows.Add([pscustomobject]@{
      QueueRank = $rank; Candidate = $candidate; CandidateRank = $rank
      SourceType = "htf_band_reversion_di_gate"; SourceRank = 1; Phase = "continuous_model4"
      Set = $profileName; Window = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12"
      Model = 4; Deposit = 10000; Config = "configs\$configName"; ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; StopRule = $stopRule
   }) | Out-Null
   $runRows.Add([pscustomobject]@{
      QueueRank = $rank; Candidate = $candidate; Phase = "continuous_model4"
      PhaseLabel = "HTF band reversion DI gate continuous real-tick gate"; Window = "continuous_2015_2026"
      Model = 4; Deposit = 10000; PackageConfig = "$PackageDir\configs\$configName"
      SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
      ReportDestination = "$PackageDir\reports_here\$reportName"; ProfileSha256 = $profileHash; StopRule = $stopRule
   }) | Out-Null
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Candidates = $candidateNames.Count
   Configurations = $rank
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
