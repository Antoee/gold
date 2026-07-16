param(
   [string]$SourcePackageDir = "outputs\peak_trail_unblock_probe_package",
   [string]$BaseProfilePath = "outputs\dgf_highprofit_risk_shape_package\profiles\dgf_hp_control.set",
   [string]$PackageDir = "outputs\highprofit_headline_model1_control_package",
   [string]$QueueManifestPath = "outputs\HIGHPROFIT_HEADLINE_MODEL1_CONTROL_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\HIGHPROFIT_HEADLINE_MODEL1_CONTROL_PACKAGE_MANIFEST.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$source = Join-Path $repo "$SourcePackageDir\source\Professional_XAUUSD_EA.mq5"
$baseProfile = Join-Path $repo $BaseProfilePath
$packageFull = Join-Path $repo $PackageDir
if(!(Test-Path -LiteralPath $source)) { throw "Headline 8D62 source missing: $source" }
if(!(Test-Path -LiteralPath $baseProfile)) { throw "Headline high-profit profile missing: $baseProfile" }

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
$expectedSourceHash = "8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A"
if($sourceHash -ne $expectedSourceHash) {
   throw "Headline high-profit source hash changed: $sourceHash"
}
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$inputs = Import-SetInputs $baseProfile
$candidate = "highprofit_headline_8d62_model1_control"
Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $candidate
Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value $candidate
$profileName = "$candidate.set"
$profilePath = Join-Path $profileDir $profileName
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $profilePath -Encoding ASCII
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$configName = "001_${candidate}_continuous_2019_2026_m1.ini"
$reportName = "${candidate}_continuous_2019_2026_m1"
Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
   -ReportName $reportName -From "2019.01.01" -To "2026.07.12" -Inputs $inputs -Model 1 -Deposit 10000
$stopRule = "Compare only with the guarded common-executable high-profit Model1 control; a mismatch rejects source portability."

@([pscustomobject]@{
   QueueRank = 1; Candidate = $candidate; CandidateRank = 1; SourceType = "highprofit_headline_control"
   SourceRank = 1; Phase = "headline_8d62_model1_control"; Set = $profileName; Window = "continuous_2019_2026"
   From = "2019.01.01"; To = "2026.07.12"; Model = 1; Deposit = 10000
   Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
   ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
}) | Export-Csv -LiteralPath (Join-Path $repo $QueueManifestPath) -NoTypeInformation -Encoding ASCII

@([pscustomobject]@{
   QueueRank = 1; Candidate = $candidate; Phase = "headline_8d62_model1_control"
   PhaseLabel = "Headline 8D62 high-profit Model1 control"; Window = "continuous_2019_2026"; Model = 1; Deposit = 10000
   PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
   ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
   ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
}) | Export-Csv -LiteralPath (Join-Path $repo $PackageManifestPath) -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   ProfileHash = $profileHash
   QueueManifest = $QueueManifestPath
   PackageManifest = $PackageManifestPath
}
