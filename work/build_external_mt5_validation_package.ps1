param(
   [string]$HandoffDir = "outputs\risk_adjusted_micro_handoff",
   [string]$EaSourcePath = "outputs\Professional_XAUUSD_EA.mq5",
   [string]$PackageDir = "outputs\external_mt5_validation_package",
   [string]$PackageName = "xauusd_micro_validation_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Copy-RequiredFile {
   param(
      [string]$Source,
      [string]$Destination
   )

   if(!(Test-Path -LiteralPath $Source)) { throw "Required file missing: $Source" }
   $parent = Split-Path -Parent $Destination
   if(!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
   Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Escape-MarkdownCell {
   param([string]$Value)
   if($null -eq $Value) { return "" }
   return (($Value -replace '\|', '/') -replace "`r?`n", " ").Trim()
}

$manifestPath = Join-Path $HandoffDir "HANDOFF_MANIFEST.csv"
$configDir = Join-Path $HandoffDir "configs"
$outCsv = Join-Path $PackageDir "PACKAGE_CONTENTS.csv"
$outReadme = Join-Path $PackageDir "README_EXTERNAL_MT5.md"
$expectedReports = Join-Path $PackageDir "EXPECTED_REPORTS.csv"
$packageParent = Split-Path -Parent $PackageDir
if([string]::IsNullOrWhiteSpace($packageParent)) { $packageParent = "." }
$zipPath = Join-Path $packageParent ("{0}.zip" -f $PackageName)

if(!(Test-Path -LiteralPath $manifestPath)) { throw "Handoff manifest missing: $manifestPath" }
if(!(Test-Path -LiteralPath $configDir)) { throw "Handoff config directory missing: $configDir" }

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "profiles") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "source") -Force | Out-Null

$rows = @(Import-Csv -LiteralPath $manifestPath)
if($rows.Count -eq 0) { throw "Handoff manifest has no rows: $manifestPath" }

$contents = New-Object System.Collections.Generic.List[object]

Copy-RequiredFile $manifestPath (Join-Path $PackageDir "HANDOFF_MANIFEST.csv")
$contents.Add([pscustomobject]@{ Type = "manifest"; Source = $manifestPath; PackagePath = "HANDOFF_MANIFEST.csv" }) | Out-Null

Copy-RequiredFile $EaSourcePath (Join-Path $PackageDir "source\Professional_XAUUSD_EA.mq5")
$contents.Add([pscustomobject]@{ Type = "ea_source"; Source = $EaSourcePath; PackagePath = "source\Professional_XAUUSD_EA.mq5" }) | Out-Null

$profileFiles = New-Object System.Collections.Generic.List[string]
@(
   "outputs\ROBUST_BOS_SWEEP_PROFILE.set",
   "outputs\CANDIDATE_RISK16_SL18_TP38_PROFILE.set",
   "outputs\CANDIDATE_RISK16_SL16_TP38_PROFILE.set",
   "outputs\CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set"
) | ForEach-Object { $profileFiles.Add($_) | Out-Null }

foreach($profileName in @($rows | Select-Object -ExpandProperty Profile -Unique | Sort-Object)) {
   $generatedProfile = Join-Path "work\generated_profit_search\profiles" ("{0}.set" -f $profileName)
   if(Test-Path -LiteralPath $generatedProfile) {
      $profileFiles.Add($generatedProfile) | Out-Null
   }
}

$profileFiles = @($profileFiles | Select-Object -Unique)
foreach($profileFile in $profileFiles) {
   if(Test-Path -LiteralPath $profileFile) {
      $dest = Join-Path $PackageDir ("profiles\" + (Split-Path -Leaf $profileFile))
      Copy-RequiredFile $profileFile $dest
      $contents.Add([pscustomobject]@{ Type = "profile"; Source = $profileFile; PackagePath = ("profiles\" + (Split-Path -Leaf $profileFile)) }) | Out-Null
   }
}

$expected = New-Object System.Collections.Generic.List[object]
foreach($row in $rows) {
   $configPath = [string]$row.HandoffConfig
   if([string]::IsNullOrWhiteSpace($configPath)) { throw "Manifest row $($row.Rank) has empty HandoffConfig." }
   if(!(Test-Path -LiteralPath $configPath)) { throw "Manifest config missing: $configPath" }

   $configName = Split-Path -Leaf $configPath
   Copy-RequiredFile $configPath (Join-Path $PackageDir ("configs\" + $configName))
   $contents.Add([pscustomobject]@{ Type = "config"; Source = $configPath; PackagePath = ("configs\" + $configName) }) | Out-Null

   $expected.Add([pscustomobject]@{
      Rank = $row.Rank
      Profile = $row.Profile
      Window = $row.Window
      From = $row.From
      To = $row.To
      Model = $row.Model
      Config = "configs\$configName"
      ExpectedReportName = $row.ExpectedReportName
      ExpectedHtml = "reports_here\$($row.ExpectedReportName).htm"
      ExpectedXml = "reports_here\$($row.ExpectedReportName).xml"
   }) | Out-Null
}

$expected | Export-Csv -LiteralPath $expectedReports -NoTypeInformation
$contents.Add([pscustomobject]@{ Type = "expected_reports"; Source = $expectedReports; PackagePath = "EXPECTED_REPORTS.csv" }) | Out-Null

$readme = New-Object System.Collections.Generic.List[string]
$readme.Add("# External MT5 Validation Package") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("This package is for running the smallest useful XAUUSD validation batch away from the user's active PC session. It does not require any local MT5 launch from the Codex workspace.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Contents") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("- source\Professional_XAUUSD_EA.mq5: EA source to compile on the external MT5 machine.") | Out-Null
$readme.Add("- configs\*.ini: MT5 Strategy Tester config files from the handoff manifest.") | Out-Null
$readme.Add("- profiles\*.set: profile/input snapshots for review.") | Out-Null
$readme.Add("- HANDOFF_MANIFEST.csv: source of truth for windows, profiles, and expected report names.") | Out-Null
$readme.Add("- EXPECTED_REPORTS.csv: checklist of report files to return.") | Out-Null
$readme.Add("- reports_here: put exported .htm/.html reports here before copying results back.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Run Order") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("1. Compile source\Professional_XAUUSD_EA.mq5 in MetaEditor on the external machine.") | Out-Null
$readme.Add("2. Save the MetaEditor compile log and require 0 errors, 0 warnings before accepting reports.") | Out-Null
$readme.Add("3. Run each config in configs\ with MT5 Strategy Tester.") | Out-Null
$readme.Add("4. Export each report using the ExpectedReportName from EXPECTED_REPORTS.csv.") | Out-Null
$readme.Add("5. Copy reports and the compile log back to the main workspace for offline import.") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Return Import") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("After reports are copied back into outputs\external_mt5_validation_package\reports_here, run these from the main workspace:") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("1. work\import_mt5_compile_log.ps1 against the returned compile log.") | Out-Null
$readme.Add("2. work\import_external_mt5_validation_package_reports.ps1") | Out-Null
$readme.Add("3. work\build_external_mt5_micro_decision.ps1") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("## Batch") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("| Rank | Profile | Window | From | To | Config | Expected Report |") | Out-Null
$readme.Add("|---:|---|---|---|---|---|---|") | Out-Null
foreach($row in $expected) {
   $configCell = Escape-MarkdownCell $row.Config
   $reportCell = Escape-MarkdownCell $row.ExpectedReportName
   $readme.Add("| $($row.Rank) | $(Escape-MarkdownCell $row.Profile) | $(Escape-MarkdownCell $row.Window) | $($row.From) | $($row.To) | $configCell | $reportCell |") | Out-Null
}
$readme.Add("") | Out-Null
$readme.Add("## Promotion Discipline") | Out-Null
$readme.Add("") | Out-Null
$readme.Add("Do not promote a profile from this micro batch alone. Passing this package only allows the candidate to advance to broader real-tick validation and the full promotion gate.") | Out-Null
Set-Content -LiteralPath $outReadme -Value $readme -Encoding UTF8
$contents.Add([pscustomobject]@{ Type = "readme"; Source = $outReadme; PackagePath = "README_EXTERNAL_MT5.md" }) | Out-Null

$contents | Export-Csv -LiteralPath $outCsv -NoTypeInformation

if(Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
$archiveItems = @(Get-ChildItem -LiteralPath $PackageDir -Force)
if($archiveItems.Count -eq 0) { throw "Package directory is empty: $PackageDir" }
Compress-Archive -LiteralPath $archiveItems.FullName -DestinationPath $zipPath -Force

[pscustomobject]@{
   PackageDir = $PackageDir
   ZipPath = $zipPath
   Configs = $rows.Count
   Profiles = @($contents | Where-Object { $_.Type -eq "profile" }).Count
   ContentsCsv = $outCsv
   ExpectedReports = $expectedReports
   Readme = $outReadme
}
