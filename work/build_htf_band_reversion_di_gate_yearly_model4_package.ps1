param(
   [string]$SourcePackageDir = "outputs\htf_band_reversion_di_gate_model4_package",
   [string]$PackageDir = "outputs\htf_band_reversion_di_gate_yearly_model4_package",
   [string]$QueueManifestPath = "outputs\HTF_BAND_REVERSION_DI_GATE_YEARLY_MODEL4_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\HTF_BAND_REVERSION_DI_GATE_YEARLY_MODEL4_PACKAGE_MANIFEST.csv"
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

$windows = [System.Collections.Generic.List[object]]::new()
foreach($year in 2015..2025) {
   $windows.Add([pscustomobject]@{
      Name = [string]$year
      From = ("{0}.01.01" -f $year)
      To = ("{0}.12.31" -f $year)
   }) | Out-Null
}
$windows.Add([pscustomobject]@{ Name = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" }) | Out-Null

$candidateNames = @("di_m12", "di_m10")
$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
foreach($candidate in $candidateNames) {
   $sourceProfile = Join-Path $sourcePackage ("profiles\htf_band_reversion_{0}.set" -f $candidate)
   if(!(Test-Path -LiteralPath $sourceProfile)) { throw "Profile missing: $sourceProfile" }

   $inputs = Import-SetInputs $sourceProfile
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "htf_band_reversion_di_gate_yearly_model4"
   Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value ("htf_band_reversion_{0}_yearly_model4.csv" -f $candidate)

   $profileName = "htf_band_reversion_{0}.set" -f $candidate
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_htf_band_reversion_{1}_{2}_m4.ini" -f $rank, $candidate, $window.Name
      $reportName = "htf_band_reversion_{0}_{1}_m4" -f $candidate, $window.Name
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit 10000

      $stopRule = "Require no losing active year, useful activity across regimes, and yearly restart sum consistent with continuous Model4."
      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate; CandidateRank = $rank
         SourceType = "htf_band_reversion_di_gate"; SourceRank = 1; Phase = "yearly_model4"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To
         Model = 4; Deposit = 10000; Config = "configs\$configName"; ExpectedReportName = $reportName
         ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate; Phase = "yearly_model4"
         PhaseLabel = "HTF band reversion DI gate yearly real-tick gate"; Window = $window.Name
         Model = 4; Deposit = 10000; PackageConfig = "$PackageDir\configs\$configName"
         SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
         ReportDestination = "$PackageDir\reports_here\$reportName"; ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   Candidates = $candidateNames.Count
   WindowsPerCandidate = $windows.Count
   Configurations = $rank
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
   PackageDir = $PackageDir
}
