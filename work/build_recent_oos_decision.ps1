param(
   [string]$ManifestPath = "outputs\recent_oos_handoff\HANDOFF_MANIFEST.csv",
   [string]$MetricsPath = "outputs\RECENT_OOS_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\RECENT_OOS_DECISION.csv",
   [string]$OutMarkdown = "outputs\RECENT_OOS_DECISION.md",
   [string]$CandidateProfile = "tp38_sl18",
   [string]$BaselineProfile = "baseline_promoted",
   [double]$MaxAllowedDrawdownPercent = 25.0
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

function To-Double {
   param([object]$Value, [double]$Default = 0.0)
   if($null -eq $Value) { return $Default }
   $text = ([string]$Value).Trim()
   if([string]::IsNullOrWhiteSpace($text)) { return $Default }
   $parsed = 0.0
   if([double]::TryParse($text, [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) { return $parsed }
   return $Default
}

function Get-DrawdownPercent {
   param([object]$Row)
   $value = Get-Value $Row "MaxDrawdownPercent" ""
   if([string]::IsNullOrWhiteSpace([string]$value)) { $value = Get-Value $Row "EquityDrawdownPercent" "" }
   if([string]::IsNullOrWhiteSpace([string]$value)) { $value = Get-Value $Row "DrawdownPercent" "" }
   return To-Double $value
}

function Find-MetricRow {
   param([object[]]$Rows, [string]$Profile, [string]$Window)
   return $Rows | Where-Object { (Get-Value $_ "Profile") -eq $Profile -and (Get-Value $_ "Window") -eq $Window } | Select-Object -First 1
}

$manifest = Read-CsvSafe $ManifestPath
$metrics = Read-CsvSafe $MetricsPath
$windows = @($manifest | Select-Object -ExpandProperty Window -Unique | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if($windows.Count -eq 0) {
   $windows = @("2025_Q4", "2026_Q1", "2026_Q2", "2026_YTD")
}

$rows = New-Object System.Collections.Generic.List[object]
foreach($window in $windows) {
   $candidate = Find-MetricRow $metrics $CandidateProfile $window
   $baseline = Find-MetricRow $metrics $BaselineProfile $window
   $candidateStatus = Get-Value $candidate "Status" "MISSING_REPORT"
   $baselineStatus = Get-Value $baseline "Status" "MISSING_REPORT"
   $candidateNet = To-Double (Get-Value $candidate "NetProfit" "")
   $baselineNet = To-Double (Get-Value $baseline "NetProfit" "")
   $candidateDd = Get-DrawdownPercent $candidate
   $baselineDd = Get-DrawdownPercent $baseline

   $decision = "WAITING_FOR_REPORTS"
   $reason = "Candidate or baseline report is missing."
   if($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") {
      $decision = "REPAIR_REPORT"
      $reason = "At least one paired report exists but could not be parsed."
   } elseif($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateNet -lt 0) {
         $decision = "FAIL_CANDIDATE_LOSS"
         $reason = "Candidate lost money on recent out-of-sample data."
      } elseif($candidateNet -lt $baselineNet) {
         $decision = "FAIL_BELOW_BASELINE"
         $reason = "Candidate underperformed the current promoted baseline."
      } elseif($candidateDd -gt $MaxAllowedDrawdownPercent) {
         $decision = "REVIEW_DRAWDOWN"
         $reason = "Candidate passed profit comparison but drawdown needs review."
      } else {
         $decision = "PASS_WINDOW"
         $reason = "Candidate matched or beat baseline without a recent-OOS loss."
      }
   }

   $rows.Add([pscustomobject]@{
      Window = $window
      CandidateProfile = $CandidateProfile
      BaselineProfile = $BaselineProfile
      CandidateStatus = $candidateStatus
      BaselineStatus = $baselineStatus
      CandidateNetProfit = $candidateNet
      BaselineNetProfit = $baselineNet
      NetProfitDelta = ($candidateNet - $baselineNet)
      CandidateDrawdownPercent = $candidateDd
      BaselineDrawdownPercent = $baselineDd
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
$overall = if($hasFail) { "REJECT_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($allPass) { "PASS_RECENT_OOS" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Recent OOS Decision") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline decision gate only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("- Candidate: `$CandidateProfile`") | Out-Null
$md.Add("- Baseline: `$BaselineProfile`") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Window | Candidate Net | Baseline Net | Delta | Candidate DD % | Decision | Reason |") | Out-Null
$md.Add("|---|---:|---:|---:|---:|---|---|") | Out-Null
foreach($row in $rows) {
   $md.Add("| $($row.Window) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.NetProfitDelta) | $($row.CandidateDrawdownPercent) | $($row.Decision) | $($row.Reason) |") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
if($overall -eq "PASS_RECENT_OOS") { $md.Add("Recent out-of-sample passed. Continue to the full handoff; do not promote from this gate alone.") | Out-Null }
elseif($overall -eq "REJECT_CANDIDATE") { $md.Add("Reject or deprioritize the candidate and keep the promoted baseline.") | Out-Null }
elseif($overall -eq "REPAIR_REPORTS") { $md.Add("Repair or re-export the recent-OOS reports before making a candidate decision.") | Out-Null }
elseif($overall -eq "REVIEW_DRAWDOWN") { $md.Add("Profit comparison passed, but drawdown needs review before continuing.") | Out-Null }
else { $md.Add("Waiting for exported recent-OOS reports. Keep the current promoted profile.") | Out-Null }

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$rows
