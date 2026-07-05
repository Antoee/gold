param(
   [string]$MetricsPath = "outputs\MICRO_TEST_REPORT_METRICS.csv",
   [string]$ManifestPath = "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv",
   [string]$CandidateProfile = "tp38_sl18",
   [string]$BaselineProfile = "baseline_promoted",
   [string]$OutCsv = "outputs\MICRO_TEST_DECISION.csv",
   [string]$OutReport = "outputs\MICRO_TEST_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvSafe {
   param([string]$Path)
   if(Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }
   return @()
}

function To-DoubleOrNull {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-RowValue {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

$manifest = Read-CsvSafe $ManifestPath
$metrics = Read-CsvSafe $MetricsPath
$windows = @($manifest | Where-Object { $_.Profile -eq $CandidateProfile } | Sort-Object {[int]$_.Rank} | ForEach-Object { $_.Window } | Select-Object -Unique)

$rows = New-Object System.Collections.Generic.List[object]
foreach($window in $windows) {
   $candidate = $metrics | Where-Object { $_.Profile -eq $CandidateProfile -and $_.Window -eq $window } | Select-Object -First 1
   $baseline = $metrics | Where-Object { $_.Profile -eq $BaselineProfile -and $_.Window -eq $window } | Select-Object -First 1

   $candidateStatus = [string](Get-RowValue $candidate "Status" "MISSING_REPORT")
   $baselineStatus = [string](Get-RowValue $baseline "Status" "MISSING_REPORT")
   $candidateProfit = To-DoubleOrNull (Get-RowValue $candidate "NetProfit" "")
   $baselineProfit = To-DoubleOrNull (Get-RowValue $baseline "NetProfit" "")
   $candidateDd = To-DoubleOrNull (Get-RowValue $candidate "MaxDrawdownMoney" "")
   $baselineDd = To-DoubleOrNull (Get-RowValue $baseline "MaxDrawdownMoney" "")
   $candidatePf = To-DoubleOrNull (Get-RowValue $candidate "ProfitFactor" "")
   $baselinePf = To-DoubleOrNull (Get-RowValue $baseline "ProfitFactor" "")

   $decision = "WAITING_FOR_REPORTS"
   $reason = "Candidate and baseline reports must both parse before judging this window."
   if($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED" -and $null -ne $candidateProfit -and $null -ne $baselineProfit) {
      if($candidateProfit -lt 0) {
         $decision = "FAIL_CANDIDATE_LOSS"
         $reason = "Candidate lost money in this stress window."
      } elseif($candidateProfit -lt $baselineProfit) {
         $decision = "FAIL_BELOW_BASELINE"
         $reason = "Candidate net profit is below the paired baseline."
      } elseif($null -ne $candidateDd -and $null -ne $baselineDd -and $candidateDd -gt ($baselineDd * 1.15)) {
         $decision = "REVIEW_DRAWDOWN"
         $reason = "Candidate beat profit but drawdown is more than 15 percent worse than baseline."
      } else {
         $decision = "PASS_WINDOW"
         $reason = "Candidate matched or beat baseline without a detected loss."
      }
   } elseif($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") {
      $decision = "REPAIR_REPORT"
      $reason = "At least one paired report exists but did not parse."
   }

   $rows.Add([pscustomobject]@{
      Window = $window
      CandidateProfile = $CandidateProfile
      BaselineProfile = $BaselineProfile
      CandidateStatus = $candidateStatus
      BaselineStatus = $baselineStatus
      CandidateNetProfit = if($null -eq $candidateProfit) { "" } else { [Math]::Round($candidateProfit, 2) }
      BaselineNetProfit = if($null -eq $baselineProfit) { "" } else { [Math]::Round($baselineProfit, 2) }
      ProfitDelta = if($null -eq $candidateProfit -or $null -eq $baselineProfit) { "" } else { [Math]::Round($candidateProfit - $baselineProfit, 2) }
      CandidateMaxDrawdown = if($null -eq $candidateDd) { "" } else { [Math]::Round($candidateDd, 2) }
      BaselineMaxDrawdown = if($null -eq $baselineDd) { "" } else { [Math]::Round($baselineDd, 2) }
      CandidateProfitFactor = if($null -eq $candidatePf) { "" } else { [Math]::Round($candidatePf, 4) }
      BaselineProfitFactor = if($null -eq $baselinePf) { "" } else { [Math]::Round($baselinePf, 4) }
      Decision = $decision
      Reason = $reason
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$failRows = @($rows | Where-Object { $_.Decision -like "FAIL_*" })
$repairRows = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" })
$waitingRows = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" })
$reviewRows = @($rows | Where-Object { $_.Decision -eq "REVIEW_DRAWDOWN" })
$passRows = @($rows | Where-Object { $_.Decision -eq "PASS_WINDOW" })

$overall = "WAITING_FOR_REPORTS"
$nextAction = "Run/export/import the paired micro handoff reports."
if($repairRows.Count -gt 0) {
   $overall = "REPAIR_REPORTS"
   $nextAction = "Fix or re-export unparsed paired reports before judging the candidate."
} elseif($failRows.Count -gt 0) {
   $overall = "REJECT_CANDIDATE"
   $nextAction = "Keep the promoted baseline and deprioritize this candidate."
} elseif($waitingRows.Count -gt 0) {
   $overall = "WAITING_FOR_REPORTS"
   $nextAction = "Run/export/import the remaining paired micro handoff reports."
} elseif($reviewRows.Count -gt 0) {
   $overall = "REVIEW_DRAWDOWN"
   $nextAction = "Review drawdown shape before allowing this candidate into the full handoff."
} elseif($rows.Count -gt 0 -and $passRows.Count -eq $rows.Count) {
   $overall = "PASS_MICRO"
   $nextAction = "Continue to the full 24-config handoff and phase-2 real ticks before promotion."
}

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Micro Test Decision") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from exported MT5 report metrics only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Metrics source: ``$MetricsPath``") | Out-Null
$report.Add("- Manifest source: ``$ManifestPath``") | Out-Null
$report.Add("- Candidate: ``$CandidateProfile``") | Out-Null
$report.Add("- Baseline: ``$BaselineProfile``") | Out-Null
$report.Add("- Overall decision: **$overall**") | Out-Null
$report.Add("- Next action: $nextAction") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Paired Windows") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Window | Candidate | Baseline | Delta | Candidate DD | Baseline DD | Decision | Reason |") | Out-Null
$report.Add("|---|---:|---:|---:|---:|---:|---|---|") | Out-Null
foreach($row in $rows) {
   $report.Add("| $($row.Window) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.ProfitDelta) | $($row.CandidateMaxDrawdown) | $($row.BaselineMaxDrawdown) | $($row.Decision) | $($row.Reason) |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Rule") | Out-Null
$report.Add("") | Out-Null
$report.Add("A candidate that loses money or underperforms the paired baseline in any stress window is rejected for this iteration. A micro pass only earns a full handoff; it does not authorize promotion.") | Out-Null
Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

[pscustomobject]@{
   OverallDecision = $overall
   Windows = $rows.Count
   Passed = $passRows.Count
   Failed = $failRows.Count
   Waiting = $waitingRows.Count
   Repair = $repairRows.Count
   Review = $reviewRows.Count
   NextAction = $nextAction
}
