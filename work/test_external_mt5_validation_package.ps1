param(
   [string]$PackageDir = "outputs\external_mt5_validation_package",
   [string]$ZipPath = "outputs\xauusd_micro_validation_package.zip",
   [string]$OutCsv = "outputs\EXTERNAL_MT5_PACKAGE_AUDIT.csv",
   [string]$OutMarkdown = "outputs\EXTERNAL_MT5_PACKAGE_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Check {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Check,
      [bool]$Passed,
      [string]$Evidence,
      [string]$Remediation
   )

   $Rows.Add([pscustomobject]@{
      Check = $Check
      Passed = $Passed
      Evidence = $Evidence
      Remediation = $Remediation
   }) | Out-Null
}

function Read-CsvSafe {
   param([string]$Path)
   if(Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }
   return @()
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$rows = New-Object System.Collections.Generic.List[object]
$manifestPath = Join-Path $PackageDir "HANDOFF_MANIFEST.csv"
$expectedPath = Join-Path $PackageDir "EXPECTED_REPORTS.csv"
$contentsPath = Join-Path $PackageDir "PACKAGE_CONTENTS.csv"
$readmePath = Join-Path $PackageDir "README_EXTERNAL_MT5.md"
$sourcePath = Join-Path $PackageDir "source\Professional_XAUUSD_EA.mq5"
$configsDir = Join-Path $PackageDir "configs"
$profilesDir = Join-Path $PackageDir "profiles"
$reportsDir = Join-Path $PackageDir "reports_here"

$manifest = Read-CsvSafe $manifestPath
$expected = Read-CsvSafe $expectedPath
$contents = Read-CsvSafe $contentsPath
$configs = if(Test-Path -LiteralPath $configsDir) { @(Get-ChildItem -LiteralPath $configsDir -Filter "*.ini" -File) } else { @() }
$profiles = if(Test-Path -LiteralPath $profilesDir) { @(Get-ChildItem -LiteralPath $profilesDir -Filter "*.set" -File) } else { @() }

Add-Check $rows "Package directory exists" (Test-Path -LiteralPath $PackageDir) $PackageDir "Rebuild with work\build_external_mt5_validation_package.ps1."
Add-Check $rows "EA source included" (Test-Path -LiteralPath $sourcePath) $sourcePath "Include outputs\Professional_XAUUSD_EA.mq5."
Add-Check $rows "Manifest included" ($manifest.Count -gt 0) "$manifestPath rows=$($manifest.Count)" "Copy HANDOFF_MANIFEST.csv into the package."
Add-Check $rows "Expected reports checklist included" ($expected.Count -eq $manifest.Count -and $expected.Count -gt 0) "$expectedPath rows=$($expected.Count); manifest rows=$($manifest.Count)" "Regenerate EXPECTED_REPORTS.csv from the manifest."
Add-Check $rows "All configs included" ($configs.Count -eq $manifest.Count -and $configs.Count -gt 0) "$configsDir ini files=$($configs.Count); manifest rows=$($manifest.Count)" "Copy every manifest HandoffConfig into configs."
Add-Check $rows "Profile snapshots included" ($profiles.Count -ge 2) "$profilesDir set files=$($profiles.Count)" "Include promoted and candidate profile .set files."
Add-Check $rows "Reports return folder exists" (Test-Path -LiteralPath $reportsDir) $reportsDir "Create reports_here for exported reports."
Add-Check $rows "README included" (Test-Path -LiteralPath $readmePath) $readmePath "Generate README_EXTERNAL_MT5.md."
Add-Check $rows "Package contents inventory included" ($contents.Count -gt 0) "$contentsPath rows=$($contents.Count)" "Generate PACKAGE_CONTENTS.csv."

$zipEntries = @()
if(Test-Path -LiteralPath $ZipPath) {
   $zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath))
   try { $zipEntries = @($zip.Entries) } finally { $zip.Dispose() }
}
Add-Check $rows "Zip archive exists" (Test-Path -LiteralPath $ZipPath) $ZipPath "Rebuild zip archive."
Add-Check $rows "Zip archive has required files" ($zipEntries.Count -ge ($manifest.Count + $profiles.Count + 5)) "$ZipPath entries=$($zipEntries.Count)" "Rebuild archive from package folder contents."
Add-Check $rows "Zip contains EA source" (@($zipEntries | Where-Object { $_.FullName -eq "source/Professional_XAUUSD_EA.mq5" -or $_.FullName -eq "source\Professional_XAUUSD_EA.mq5" }).Count -gt 0) "source/Professional_XAUUSD_EA.mq5" "Rebuild archive after copying EA source."

$missingConfigs = New-Object System.Collections.Generic.List[string]
foreach($row in $manifest) {
   $leaf = Split-Path -Leaf ([string]$row.HandoffConfig)
   if(!(Test-Path -LiteralPath (Join-Path $configsDir $leaf))) { $missingConfigs.Add($leaf) | Out-Null }
}
Add-Check $rows "No manifest configs missing from package" ($missingConfigs.Count -eq 0) $(if($missingConfigs.Count -eq 0) { "All manifest configs are present." } else { $missingConfigs -join "; " }) "Rebuild package from the handoff manifest."

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$failed = @($rows | Where-Object { -not $_.Passed })

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# External MT5 Package Audit") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline audit only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$(if($failed.Count -eq 0) { "PASS" } else { "FAIL" })**") | Out-Null
$md.Add("- Checks passed: $($rows.Count - $failed.Count) / $($rows.Count)") | Out-Null
$md.Add("- Manifest rows: $($manifest.Count)") | Out-Null
$md.Add("- Configs packaged: $($configs.Count)") | Out-Null
$md.Add("- Zip entries: $($zipEntries.Count)") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Check | Passed | Evidence | Remediation |") | Out-Null
$md.Add("|---|---|---|---|") | Out-Null
foreach($row in $rows) {
   $evidence = ([string]$row.Evidence) -replace '\|', '/'
   $remediation = ([string]$row.Remediation) -replace '\|', '/'
   $md.Add("| $($row.Check) | $($row.Passed) | $evidence | $remediation |") | Out-Null
}
Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{
   Overall = if($failed.Count -eq 0) { "PASS" } else { "FAIL" }
   Checks = $rows.Count
   Passed = $rows.Count - $failed.Count
   Failed = $failed.Count
   ManifestRows = $manifest.Count
   Configs = $configs.Count
   ZipEntries = $zipEntries.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}

if($failed.Count -gt 0) { exit 1 }
