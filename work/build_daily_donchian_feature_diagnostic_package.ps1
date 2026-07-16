param(
   [string]$BaseProfilePath = "outputs\daily_donchian_channel_exit_realtick_package\profiles\ddb_ch_lb20e150_x5.set",
   [string]$SourcePath = "work\Professional_XAUUSD_EA_DDB_FEATURE_DIAGNOSTIC.mq5",
   [string]$PackageDir = "outputs\daily_donchian_feature_diagnostic_package",
   [string]$TradeLogFile = "ddb_ch_lb20e150_x5_features.csv",
   [string]$From = "2015.01.01",
   [string]$To = "2026.07.12",
   [ValidateSet(0,1,2,3,4)][int]$Model = 1,
   [ValidateRange(100,100000000)][int]$Deposit = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$baseProfile = Join-Path $repo $BaseProfilePath
$source = Join-Path $repo $SourcePath
$packageFull = Join-Path $repo $PackageDir

if(!(Test-Path -LiteralPath $baseProfile)) { throw "Base profile missing: $baseProfile" }
if(!(Test-Path -LiteralPath $source)) { throw "Feature diagnostic source missing: $source" }
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
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$candidate = "ddb_ch_lb20e150_x5_feature_diagnostic"
$inputs = Import-SetInputs $baseProfile
Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "2"
Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value $TradeLogFile
Set-InputLine -Inputs $inputs -Name "InpUseBlockReasonDiagnostics" -Value "false"
Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $candidate
Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "daily_donchian_feature_diagnostic"

$profileName = "$candidate.set"
$profilePath = Join-Path $profileDir $profileName
@($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
   Set-Content -LiteralPath $profilePath -Encoding ASCII
$profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

$window = "continuous_2015_2026"
$configName = "001_${candidate}_${window}_m${Model}.ini"
$reportName = "${candidate}_${window}_m${Model}"
Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
   -ReportName $reportName -From $From -To $To -Inputs $inputs -Model $Model -Deposit $Deposit

$queuePath = Join-Path $repo "outputs\DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_QUEUE.csv"
$manifestPath = Join-Path $repo "outputs\DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_PACKAGE_MANIFEST.csv"
$stopRule = "Diagnostic only: do not promote from this run; use features to predeclare behavior gates, then validate independently."

@([pscustomobject]@{
   QueueRank = 1; Candidate = $candidate; CandidateRank = 1
   SourceType = "daily_donchian_feature_diagnostic"; SourceRank = 1; Phase = "diagnostic_model${Model}"
   Set = $profileName; Window = $window; From = $From; To = $To
   Model = $Model; Deposit = $Deposit; Config = "configs\$configName"; ExpectedReportName = $reportName
   ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; SourceSha256 = $sourceHash
   TradeLogFile = $TradeLogFile; StopRule = $stopRule
}) | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII

@([pscustomobject]@{
   QueueRank = 1; Candidate = $candidate; Phase = "diagnostic_model${Model}"
   PhaseLabel = "Daily Donchian entry-feature diagnostic"; Window = $window; Model = $Model; Deposit = $Deposit
   PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
   ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
   ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; TradeLogFile = $TradeLogFile; StopRule = $stopRule
}) | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   SourceHash = $sourceHash
   ProfileHash = $profileHash
   TradeLogFile = $TradeLogFile
   QueueManifest = "outputs\DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_QUEUE.csv"
   PackageManifest = "outputs\DAILY_DONCHIAN_FEATURE_DIAGNOSTIC_PACKAGE_MANIFEST.csv"
}

