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
$statusPath = Join-Path $PackageDir "PACKAGE_STATUS.csv"
$compileChecklistPath = Join-Path $PackageDir "COMPILE_RETURN_CHECKLIST.csv"
$runReturnChecklistPath = Join-Path $PackageDir "RUN_RETURN_CHECKLIST.csv"
$runReturnChecklistMdPath = Join-Path $PackageDir "RUN_RETURN_CHECKLIST.md"
$readmePath = Join-Path $PackageDir "README_EXTERNAL_MT5.md"
$sourcePath = Join-Path $PackageDir "source\Professional_XAUUSD_EA.mq5"
$configsDir = Join-Path $PackageDir "configs"
$profilesDir = Join-Path $PackageDir "profiles"
$reportsDir = Join-Path $PackageDir "reports_here"

$manifest = @(Read-CsvSafe $manifestPath)
$expected = @(Read-CsvSafe $expectedPath)
$contents = @(Read-CsvSafe $contentsPath)
$packageStatus = @(Read-CsvSafe $statusPath)
$compileChecklist = @(Read-CsvSafe $compileChecklistPath)
$runReturnChecklist = @(Read-CsvSafe $runReturnChecklistPath)
$configs = @(if(Test-Path -LiteralPath $configsDir) { Get-ChildItem -LiteralPath $configsDir -Filter "*.ini" -File } else { @() })
$profiles = @(if(Test-Path -LiteralPath $profilesDir) { Get-ChildItem -LiteralPath $profilesDir -Filter "*.set" -File } else { @() })

Add-Check $rows "Package directory exists" (Test-Path -LiteralPath $PackageDir) $PackageDir "Rebuild with work\build_external_mt5_validation_package.ps1."
Add-Check $rows "EA source included" (Test-Path -LiteralPath $sourcePath) $sourcePath "Include outputs\Professional_XAUUSD_EA.mq5."
Add-Check $rows "Manifest included" ($manifest.Count -gt 0) "$manifestPath rows=$($manifest.Count)" "Copy HANDOFF_MANIFEST.csv into the package."
Add-Check $rows "Expected reports checklist included" ($expected.Count -eq $manifest.Count -and $expected.Count -gt 0) "$expectedPath rows=$($expected.Count); manifest rows=$($manifest.Count)" "Regenerate EXPECTED_REPORTS.csv from the manifest."
Add-Check $rows "All configs included" ($configs.Count -eq $manifest.Count -and $configs.Count -gt 0) "$configsDir ini files=$($configs.Count); manifest rows=$($manifest.Count)" "Copy every manifest HandoffConfig into configs."
Add-Check $rows "Profile snapshots included" ($profiles.Count -ge 2) "$profilesDir set files=$($profiles.Count)" "Include promoted and candidate profile .set files."
Add-Check $rows "Reports return folder exists" (Test-Path -LiteralPath $reportsDir) $reportsDir "Create reports_here for exported reports."
Add-Check $rows "README included" (Test-Path -LiteralPath $readmePath) $readmePath "Generate README_EXTERNAL_MT5.md."
Add-Check $rows "Package contents inventory included" ($contents.Count -gt 0) "$contentsPath rows=$($contents.Count)" "Generate PACKAGE_CONTENTS.csv."
Add-Check $rows "Package status included" ($packageStatus.Count -gt 0) "$statusPath rows=$($packageStatus.Count)" "Generate PACKAGE_STATUS.csv with compile trust and package scope."
Add-Check $rows "Compile return checklist included" ($compileChecklist.Count -ge 5) "$compileChecklistPath rows=$($compileChecklist.Count)" "Generate COMPILE_RETURN_CHECKLIST.csv with source hash and import requirements."
Add-Check $rows "Run return checklist included" ($runReturnChecklist.Count -ge 5 -and (Test-Path -LiteralPath $runReturnChecklistMdPath)) "$runReturnChecklistPath rows=$($runReturnChecklist.Count); markdown=$runReturnChecklistMdPath" "Generate RUN_RETURN_CHECKLIST.csv and RUN_RETURN_CHECKLIST.md."
$compileTrust = $packageStatus | Where-Object { $_.Area -eq "Compile trust" } | Select-Object -First 1
$sourceHashRow = $packageStatus | Where-Object { $_.Area -eq "Source hash" } | Select-Object -First 1
Add-Check $rows "Compile trust status requires fresh external compile" ($null -ne $compileTrust -and [string]$compileTrust.Status -in @("STALE", "FRESH_PASS")) `
   $(if($compileTrust) { "Status=$($compileTrust.Status); $($compileTrust.Evidence)" } else { "Compile trust row missing." }) `
   "Rebuild package status and require a returned MetaEditor compile log before trusting reports."
Add-Check $rows "Source hash status included" ($null -ne $sourceHashRow -and [string]$sourceHashRow.Status -eq "SHA256" -and ([string]$sourceHashRow.Evidence).Length -eq 64) `
   $(if($sourceHashRow) { "Hash=$($sourceHashRow.Evidence)" } else { "Source hash row missing." }) `
   "Rebuild package status with a SHA-256 hash of source\Professional_XAUUSD_EA.mq5."
if($sourceHashRow) {
   $checklistHash = $compileChecklist | Where-Object { $_.Item -eq "Source hash" } | Select-Object -First 1
   Add-Check $rows "Compile checklist source hash matches package" ($null -ne $checklistHash -and [string]$checklistHash.ExpectedValue -eq [string]$sourceHashRow.Evidence) `
      $(if($checklistHash) { "ChecklistHash=$($checklistHash.ExpectedValue); PackageHash=$($sourceHashRow.Evidence)" } else { "Source hash checklist row missing." }) `
      "Rebuild package so compile checklist and package status use the same source hash."
}
$importCommand = $compileChecklist | Where-Object { $_.Item -eq "Import command" } | Select-Object -First 1
Add-Check $rows "Compile checklist includes import command" ($null -ne $importCommand -and [string]$importCommand.ExpectedValue -like "*import_mt5_compile_log.ps1*") `
   $(if($importCommand) { $importCommand.ExpectedValue } else { "Import command row missing." }) `
   "Add the compile-log importer command to COMPILE_RETURN_CHECKLIST.csv."
Add-Check $rows "Compile checklist requires compiled source path" ($null -ne $importCommand -and [string]$importCommand.ExpectedValue -like "*-CompiledSourcePath*") `
   $(if($importCommand) { $importCommand.ExpectedValue } else { "Import command row missing." }) `
   "Require -CompiledSourcePath so SourceHashStatus can become MATCH instead of EXPECTED_ONLY."

$manifestProfiles = @($manifest | Select-Object -ExpandProperty Profile -Unique | Sort-Object)
$manifestWindows = @($manifest | Select-Object -ExpandProperty Window -Unique | Sort-Object)
$profileNames = @($profiles | Select-Object -ExpandProperty Name)
$requiredProfiles = @("baseline_promoted", "risk12_tp38_sl18", "risk14_tp38_sl18", "baseline_dd4", "buyblock2_dd4")
$requiredWindows = @("2024_Q1", "2025_Q2", "2026_Q2", "2026_ytd")
$missingRequiredPairs = New-Object System.Collections.Generic.List[string]
foreach($profile in $requiredProfiles) {
   foreach($window in $requiredWindows) {
      if(@($manifest | Where-Object { $_.Profile -eq $profile -and $_.Phase -eq "phase1_fast_triage" -and $_.Window -eq $window }).Count -eq 0) {
         $missingRequiredPairs.Add("$profile/$window") | Out-Null
      }
   }
}
$hasRiskAdjustedShape = (
   $manifest.Count -eq 20 -and
   @($requiredProfiles | Where-Object { $manifestProfiles -contains $_ }).Count -eq $requiredProfiles.Count -and
   @($requiredWindows | Where-Object { $manifestWindows -contains $_ }).Count -eq $requiredWindows.Count -and
   $missingRequiredPairs.Count -eq 0
)
Add-Check $rows "Risk-adjusted package shape" $hasRiskAdjustedShape `
   "Rows=$($manifest.Count); profiles=$($manifestProfiles -join ','); windows=$($manifestWindows -join ','); missingRequiredPairs=$($missingRequiredPairs -join ',')" `
   "Rebuild with work\build_external_mt5_validation_package.ps1 using outputs\risk_adjusted_micro_handoff."
Add-Check $rows "Lower-risk candidate profile snapshot included" ($profileNames -contains "risk12_tp38_sl18.set") `
   "Profile snapshots: $($profileNames -join ',')" `
   "Regenerate profit-search profiles and rebuild the external package."
Add-Check $rows "Date-block research profile snapshot included" ($profileNames -contains "buyblock2_dd4.set") `
   "Profile snapshots: $($profileNames -join ',')" `
   "Regenerate profit-search profiles and rebuild the external package."

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

$reportTargetMismatches = New-Object System.Collections.Generic.List[string]
foreach($row in $expected) {
   $configPath = Join-Path $PackageDir ([string]$row.Config)
   if(!(Test-Path -LiteralPath $configPath)) {
      $reportTargetMismatches.Add("$($row.Config):missing_config") | Out-Null
      continue
   }

   $reportLine = Get-Content -LiteralPath $configPath | Where-Object { $_ -match '^Report=' } | Select-Object -First 1
   if([string]::IsNullOrWhiteSpace($reportLine)) {
      $reportTargetMismatches.Add("$($row.Config):missing_Report") | Out-Null
      continue
   }

   $actualReportPath = ($reportLine -split '=', 2)[1].Trim()
   $actualReportName = [IO.Path]::GetFileNameWithoutExtension($actualReportPath)
   if($actualReportName -ne [string]$row.ExpectedReportName) {
      $reportTargetMismatches.Add("$($row.Config):$actualReportName<>$($row.ExpectedReportName)") | Out-Null
   }
}
Add-Check $rows "Config report targets match expected names" ($reportTargetMismatches.Count -eq 0) `
   $(if($reportTargetMismatches.Count -eq 0) { "All packaged config Report= names match EXPECTED_REPORTS.csv." } else { $reportTargetMismatches -join "; " }) `
   "Regenerate handoff configs and package so Report= basenames match EXPECTED_REPORTS.csv."

$runReturnText = if(Test-Path -LiteralPath $runReturnChecklistMdPath) { Get-Content -LiteralPath $runReturnChecklistMdPath -Raw } else { "" }
$runReturnHasShape = (
   $runReturnText -match "Expected Reports" -and
   $runReturnText -match "risk14_tp38_sl18" -and
   $runReturnText -match "buyblock2_dd4" -and
   $runReturnText -match "2026_ytd" -and
   $runReturnText -match [regex]::Escape("audit_external_report_return_completeness.ps1")
)
Add-Check $rows "Run return checklist matches current micro shape" $runReturnHasShape `
   "Contains Expected Reports=$($runReturnText -match 'Expected Reports'); risk14=$($runReturnText -match 'risk14_tp38_sl18'); buyblock2=$($runReturnText -match 'buyblock2_dd4'); 2026_ytd=$($runReturnText -match '2026_ytd')" `
   "Regenerate the package so external run instructions match the current 20-report micro frontier."

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
