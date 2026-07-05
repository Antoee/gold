param(
   [string]$PackageAuditPath = "outputs\EXTERNAL_MT5_PACKAGE_AUDIT.csv",
   [string]$MicroDecisionPath = "outputs\EXTERNAL_MT5_MICRO_DECISION.csv",
   [string]$CompileStatusPath = "outputs\MT5_COMPILE_STATUS.csv",
   [string]$OutCsv = "outputs\EXTERNAL_VALIDATION_READINESS.csv",
   [string]$OutMarkdown = "outputs\EXTERNAL_VALIDATION_READINESS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvSafe {
   param([string]$Path)
   if(Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }
   return @()
}

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Add-Row {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Area,
      [string]$Status,
      [string]$Evidence,
      [string]$NextAction
   )

   $Rows.Add([pscustomobject]@{
      Area = $Area
      Status = $Status
      Evidence = $Evidence
      NextAction = $NextAction
   }) | Out-Null
}

$packageRows = @(Read-CsvSafe $PackageAuditPath)
$microRows = @(Read-CsvSafe $MicroDecisionPath)
$compileRows = @(Read-CsvSafe $CompileStatusPath)
$rows = New-Object System.Collections.Generic.List[object]

$compileRow = $compileRows | Select-Object -First 1
$compileStatus = if($compileRows.Count -gt 0) { Get-Value $compileRow "Status" } else { "MISSING_REPORT" }
Add-Row $rows "Compile status" $compileStatus `
   $(if($compileRows.Count -gt 0) { Get-Value $compileRow "Evidence" } else { "No compile status CSV found at $CompileStatusPath." }) `
   $(if($compileStatus -eq "PASS") { "Compile gate is clean for the imported log." } else { "Import a clean MetaEditor compile log before accepting tester reports." })

$packageFailures = @($packageRows | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
$packageStatus = if($packageRows.Count -eq 0) { "MISSING_REPORT" } elseif($packageFailures.Count -eq 0) { "PASS" } else { "FAIL" }
Add-Row $rows "External package" $packageStatus `
   $(if($packageRows.Count -gt 0) { "$($packageRows.Count) checks; failures=$($packageFailures.Count)." } else { "No package audit CSV found at $PackageAuditPath." }) `
   $(if($packageStatus -eq "PASS") { "Package is ready for external MT5 execution." } else { "Build and audit the external MT5 package before running it." })

$decisionCounts = if($microRows.Count -gt 0) { ($microRows | Group-Object Decision | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; " } else { "" }
$hasFail = @($microRows | Where-Object { (Get-Value $_ "Decision") -like "FAIL_*" }).Count -gt 0
$hasRepair = @($microRows | Where-Object { (Get-Value $_ "Decision") -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($microRows | Where-Object { (Get-Value $_ "Decision") -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($microRows | Where-Object { (Get-Value $_ "Decision") -eq "REVIEW_DRAWDOWN" }).Count -gt 0
$allPass = $microRows.Count -gt 0 -and @($microRows | Where-Object { (Get-Value $_ "Decision") -eq "PASS_WINDOW" }).Count -eq $microRows.Count
$microStatus = if($hasFail) { "REJECT_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($allPass) { "PASS_MICRO" } elseif($microRows.Count -gt 0) { "REVIEW_REQUIRED" } else { "WAITING_FOR_REPORTS" }
Add-Row $rows "External micro decision" $microStatus `
   $(if($microRows.Count -gt 0) { $decisionCounts } else { "No micro decision CSV found at $MicroDecisionPath." }) `
   $(if($microStatus -eq "PASS_MICRO") { "Advance to full handoff and phase-2 real ticks; do not promote from micro evidence alone." } elseif($microStatus -eq "REJECT_CANDIDATE") { "Keep the promoted baseline and deprioritize this candidate." } else { "Return all external package reports before advancing this candidate." })

$overall = if($compileStatus -ne "PASS") {
   "WAITING_FOR_COMPILE"
} elseif($packageStatus -ne "PASS") {
   "PACKAGE_NOT_READY"
} elseif($microStatus -eq "PASS_MICRO") {
   "READY_FOR_FULL_VALIDATION"
} elseif($microStatus -eq "REJECT_CANDIDATE") {
   "REJECT_CANDIDATE"
} elseif($microStatus -eq "REPAIR_REPORTS") {
   "REPAIR_REPORTS"
} else {
   "WAITING_FOR_REPORTS"
}

Add-Row $rows "Overall external validation" $overall `
   "Compile=$compileStatus; Package=$packageStatus; Micro=$microStatus." `
   $(if($overall -eq "READY_FOR_FULL_VALIDATION") { "Run broader validation next." } elseif($overall -eq "REJECT_CANDIDATE") { "Do not spend more tester time on this candidate." } else { "Complete the external package report cycle." })

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# External Validation Readiness") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline snapshot only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Area | Status | Evidence | Next Action |") | Out-Null
$md.Add("|---|---|---|---|") | Out-Null
foreach($row in $rows) {
   $evidence = ([string]$row.Evidence) -replace '\|', '/'
   $next = ([string]$row.NextAction) -replace '\|', '/'
   $md.Add("| $($row.Area) | $($row.Status) | $evidence | $next |") | Out-Null
}
Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{
   Overall = $overall
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
