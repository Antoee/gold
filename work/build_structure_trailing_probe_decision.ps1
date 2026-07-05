param(
   [string]$MetricsPath = "outputs\STRUCTURE_TRAILING_PROBE_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\STRUCTURE_TRAILING_PROBE_DECISION.csv",
   [string]$OutMarkdown = "outputs\STRUCTURE_TRAILING_PROBE_DECISION.md",
   [double]$MaxAllowedDrawdownPercent = 25.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvSafe { param([string]$Path) if(Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) } return @() }
function Get-Value { param([object]$Row, [string]$Name, [object]$Default = "") if($null -eq $Row) { return $Default } $p = $Row.PSObject.Properties[$Name]; if($null -eq $p) { return $Default } return $p.Value }
function To-Double { param([object]$Value, [double]$Default = 0.0) $text = ([string]$Value).Trim(); if([string]::IsNullOrWhiteSpace($text)) { return $Default } $parsed = 0.0; if([double]::TryParse($text, [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) { return $parsed } return $Default }
function Get-DrawdownPercent { param([object]$Row) $v = Get-Value $Row "MaxDrawdownPercent" ""; if([string]::IsNullOrWhiteSpace([string]$v)) { $v = Get-Value $Row "EquityDrawdownPercent" "" }; if([string]::IsNullOrWhiteSpace([string]$v)) { $v = Get-Value $Row "DrawdownPercent" "" }; return To-Double $v }
function Find-MetricRow { param([object[]]$Rows, [string]$Profile) return $Rows | Where-Object { (Get-Value $_ "Profile") -eq $Profile } | Select-Object -First 1 }

$pairs = @(
   [pscustomobject]@{ Pair = "baseline_structure_trail"; Candidate = "baseline_promoted_structure_trail"; Baseline = "baseline_promoted" },
   [pscustomobject]@{ Pair = "tp38_sl18_structure_trail"; Candidate = "tp38_sl18_structure_trail"; Baseline = "tp38_sl18" }
)

$metrics = Read-CsvSafe $MetricsPath
$rows = New-Object System.Collections.Generic.List[object]
foreach($pair in $pairs) {
   $candidate = Find-MetricRow $metrics $pair.Candidate
   $baseline = Find-MetricRow $metrics $pair.Baseline
   $candidateStatus = Get-Value $candidate "Status" "MISSING_REPORT"
   $baselineStatus = Get-Value $baseline "Status" "MISSING_REPORT"
   $candidateNet = To-Double (Get-Value $candidate "NetProfit" "")
   $baselineNet = To-Double (Get-Value $baseline "NetProfit" "")
   $candidateDd = Get-DrawdownPercent $candidate
   $baselineDd = Get-DrawdownPercent $baseline

   $decision = "WAITING_FOR_REPORTS"
   $reason = "Candidate or paired unfiltered report is missing."
   if($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") { $decision = "REPAIR_REPORT"; $reason = "At least one paired report exists but could not be parsed." }
   elseif($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateNet -lt 0) { $decision = "FAIL_CANDIDATE_LOSS"; $reason = "Structure-trailing candidate lost money." }
      elseif($candidateNet -lt $baselineNet) { $decision = "FAIL_BELOW_UNFILTERED"; $reason = "Structure-trailing candidate underperformed its unfiltered pair." }
      elseif($candidateDd -gt $MaxAllowedDrawdownPercent) { $decision = "REVIEW_DRAWDOWN"; $reason = "Structure-trailing candidate passed profit comparison but drawdown needs review." }
      else { $decision = "PASS_STRUCTURE_TRAIL_PROBE"; $reason = "Structure-trailing candidate was profitable and beat its unfiltered pair." }
   }

   $rows.Add([pscustomobject]@{
      Pair = $pair.Pair
      CandidateProfile = $pair.Candidate
      BaselineProfile = $pair.Baseline
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
$hasPass = @($rows | Where-Object { $_.Decision -eq "PASS_STRUCTURE_TRAIL_PROBE" }).Count -gt 0
$hasFail = @($rows | Where-Object { $_.Decision -like "FAIL_*" }).Count -gt 0
$hasRepair = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($rows | Where-Object { $_.Decision -eq "REVIEW_DRAWDOWN" }).Count -gt 0
$overall = if($hasPass) { "HAS_STRUCTURE_TRAIL_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($hasFail) { "NO_STRUCTURE_TRAIL_CANDIDATE" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Structure Trailing Probe Decision") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline decision gate only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Pair | Candidate Net | Baseline Net | Delta | Candidate DD % | Decision | Reason |") | Out-Null
$md.Add("|---|---:|---:|---:|---:|---|---|") | Out-Null
foreach($row in $rows) { $md.Add("| $($row.Pair) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.NetProfitDelta) | $($row.CandidateDrawdownPercent) | $($row.Decision) | $($row.Reason) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
if($overall -eq "HAS_STRUCTURE_TRAIL_CANDIDATE") { $md.Add("At least one structure-trailing candidate deserves broader stress/recent-OOS validation. Do not promote from this probe alone.") | Out-Null }
elseif($overall -eq "NO_STRUCTURE_TRAIL_CANDIDATE") { $md.Add("No tested structure-trailing candidate beat its unfiltered pair. Keep the current promoted profile.") | Out-Null }
elseif($overall -eq "REPAIR_REPORTS") { $md.Add("Repair or re-export structure-trailing probe reports before making a filter decision.") | Out-Null }
elseif($overall -eq "REVIEW_DRAWDOWN") { $md.Add("A structure-trailing candidate may have profit potential, but drawdown needs review before expanding validation.") | Out-Null }
else { $md.Add("Waiting for exported structure-trailing probe reports. Keep the current promoted profile.") | Out-Null }

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$rows
