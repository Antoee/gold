param(
   [string]$MetricsPath = "outputs\EXTERNAL_MT5_PACKAGE_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\EXTERNAL_MT5_MICRO_DECISION.csv",
   [string]$OutMarkdown = "outputs\EXTERNAL_MT5_MICRO_DECISION.md",
   [string]$CandidateProfile = "",
   [string]$BaselineProfile = "baseline_promoted"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function To-DoubleOrNull {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Format-Num {
   param([object]$Value)
   if($null -eq $Value) { return "" }
   return [Math]::Round([double]$Value, 2)
}

if(!(Test-Path -LiteralPath $MetricsPath)) {
   throw "Metrics CSV missing: $MetricsPath. Run work\import_external_mt5_validation_package_reports.ps1 first."
}

$metrics = @(Import-Csv -LiteralPath $MetricsPath)
if($metrics.Count -eq 0) { throw "Metrics CSV has no rows: $MetricsPath" }

if([string]::IsNullOrWhiteSpace($CandidateProfile)) {
   $candidateProfiles = @($metrics | Where-Object { (Get-Value $_ "Profile") -ne $BaselineProfile } | Select-Object -ExpandProperty Profile -Unique)
   if($candidateProfiles.Count -ne 1) {
      throw "Could not infer a single candidate profile. Candidates found: $($candidateProfiles -join ', ')"
   }
   $CandidateProfile = [string]$candidateProfiles[0]
}

$windows = @($metrics | Select-Object -ExpandProperty Window -Unique | Sort-Object)
$rows = New-Object System.Collections.Generic.List[object]

foreach($window in $windows) {
   $candidate = $metrics | Where-Object { (Get-Value $_ "Profile") -eq $CandidateProfile -and (Get-Value $_ "Window") -eq $window } | Select-Object -First 1
   $baseline = $metrics | Where-Object { (Get-Value $_ "Profile") -eq $BaselineProfile -and (Get-Value $_ "Window") -eq $window } | Select-Object -First 1

   $candidateStatus = Get-Value $candidate "Status" "MISSING_REPORT"
   $baselineStatus = Get-Value $baseline "Status" "MISSING_REPORT"
   $candidateProfit = To-DoubleOrNull (Get-Value $candidate "NetProfit")
   $baselineProfit = To-DoubleOrNull (Get-Value $baseline "NetProfit")
   $candidateDrawdown = To-DoubleOrNull (Get-Value $candidate "MaxDrawdownMoney")
   $baselineDrawdown = To-DoubleOrNull (Get-Value $baseline "MaxDrawdownMoney")
   $delta = if($null -ne $candidateProfit -and $null -ne $baselineProfit) { $candidateProfit - $baselineProfit } else { $null }
   $drawdownDelta = if($null -ne $candidateDrawdown -and $null -ne $baselineDrawdown) { $candidateDrawdown - $baselineDrawdown } else { $null }

   $decision = "WAITING_FOR_REPORTS"
   $reason = "Candidate or baseline report is missing/unparsed."
   if($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateProfit -lt 0) {
         $decision = "FAIL_CANDIDATE_LOSS"
         $reason = "Candidate lost money in this stress window."
      } elseif($candidateProfit -lt $baselineProfit) {
         $decision = "FAIL_UNDERPERFORM_BASELINE"
         $reason = "Candidate net profit is below the promoted baseline on the same window."
      } elseif($null -ne $drawdownDelta -and $drawdownDelta -gt 0 -and $candidateProfit -le $baselineProfit) {
         $decision = "REVIEW_DRAWDOWN"
         $reason = "Candidate did not improve profit and has higher drawdown."
      } else {
         $decision = "PASS_WINDOW"
         $reason = "Candidate matches or improves baseline without losing money."
      }
   } elseif($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") {
      $decision = "REPAIR_REPORT"
      $reason = "At least one report exists but could not be parsed."
   }

   $rows.Add([pscustomobject]@{
      Window = $window
      CandidateProfile = $CandidateProfile
      BaselineProfile = $BaselineProfile
      CandidateStatus = $candidateStatus
      BaselineStatus = $baselineStatus
      CandidateNetProfit = Format-Num $candidateProfit
      BaselineNetProfit = Format-Num $baselineProfit
      NetProfitDelta = Format-Num $delta
      CandidateDrawdown = Format-Num $candidateDrawdown
      BaselineDrawdown = Format-Num $baselineDrawdown
      DrawdownDelta = Format-Num $drawdownDelta
      Decision = $decision
      Reason = $reason
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$hasFail = @($rows | Where-Object { $_.Decision -like "FAIL_*" }).Count -gt 0
$hasRepair = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($rows | Where-Object { $_.Decision -eq "REVIEW_DRAWDOWN" }).Count -gt 0
$allPass = $rows.Count -gt 0 -and @($rows | Where-Object { $_.Decision -eq "PASS_WINDOW" }).Count -eq $rows.Count
$overall = if($hasFail) { "REJECT_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($allPass) { "PASS_MICRO" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# External MT5 Micro Decision") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline decision only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("- Candidate: ``$CandidateProfile``") | Out-Null
$md.Add("- Baseline: ``$BaselineProfile``") | Out-Null
$md.Add("- Windows checked: $($rows.Count)") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Window | Decision | Candidate Net | Baseline Net | Delta | Candidate DD | Baseline DD | Reason |") | Out-Null
$md.Add("|---|---|---:|---:|---:|---:|---:|---|") | Out-Null
foreach($row in $rows) {
   $reason = ([string]$row.Reason) -replace '\|', '/'
   $md.Add("| $($row.Window) | $($row.Decision) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.NetProfitDelta) | $($row.CandidateDrawdown) | $($row.BaselineDrawdown) | $reason |") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Next Action") | Out-Null
$md.Add("") | Out-Null
if($overall -eq "PASS_MICRO") {
   $md.Add("Candidate passed the paired micro stress check. Advance to the full handoff and phase-2 real-tick validation; do not promote from micro evidence alone.") | Out-Null
} elseif($overall -eq "REJECT_CANDIDATE") {
   $md.Add("Candidate failed a protected stress window. Keep the promoted baseline and deprioritize this candidate.") | Out-Null
} elseif($overall -eq "REPAIR_REPORTS") {
   $md.Add("At least one report could not be parsed. Repair or re-export the report before deciding.") | Out-Null
} else {
   $md.Add("Reports are not complete enough to decide. Export/import all expected package reports first.") | Out-Null
}
Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{
   Overall = $overall
   CandidateProfile = $CandidateProfile
   BaselineProfile = $BaselineProfile
   Windows = $rows.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
