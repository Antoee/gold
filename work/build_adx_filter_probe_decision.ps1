param(
   [string]$MetricsPath = "outputs\ADX_FILTER_PROBE_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\ADX_FILTER_PROBE_DECISION.csv",
   [string]$OutMarkdown = "outputs\ADX_FILTER_PROBE_DECISION.md",
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
   [pscustomobject]@{ Pair = "baseline_adx18"; Candidate = "baseline_promoted_adx18"; Baseline = "baseline_promoted" },
   [pscustomobject]@{ Pair = "tp38_sl18_adx18"; Candidate = "tp38_sl18_adx18"; Baseline = "tp38_sl18" }
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
   $reason = "Candidate or paired no-ADX report is missing."
   if($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") { $decision = "REPAIR_REPORT"; $reason = "At least one paired report exists but could not be parsed." }
   elseif($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateNet -lt 0) { $decision = "FAIL_CANDIDATE_LOSS"; $reason = "ADX-filter candidate lost money." }
      elseif($candidateNet -lt $baselineNet) { $decision = "FAIL_BELOW_NO_ADX"; $reason = "ADX-filter candidate underperformed its no-ADX pair." }
      elseif($candidateDd -gt $MaxAllowedDrawdownPercent) { $decision = "REVIEW_DRAWDOWN"; $reason = "ADX-filter candidate passed profit comparison but drawdown needs review." }
      else { $decision = "PASS_ADX_FILTER_PROBE"; $reason = "ADX-filter candidate was profitable and beat its no-ADX pair." }
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
$hasPass = @($rows | Where-Object { $_.Decision -eq "PASS_ADX_FILTER_PROBE" }).Count -gt 0
$hasFail = @($rows | Where-Object { $_.Decision -like "FAIL_*" }).Count -gt 0
$hasRepair = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($rows | Where-Object { $_.Decision -eq "REVIEW_DRAWDOWN" }).Count -gt 0
$overall = if($hasPass) { "HAS_ADX_FILTER_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($hasFail) { "NO_ADX_FILTER_CANDIDATE" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# ADX Filter Probe Decision") | Out-Null
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
if($overall -eq "HAS_ADX_FILTER_CANDIDATE") { $md.Add("At least one ADX-filter candidate deserves broader stress/recent-OOS validation. Do not promote from this probe alone.") | Out-Null }
elseif($overall -eq "NO_ADX_FILTER_CANDIDATE") { $md.Add("No tested ADX-filter candidate beat its no-ADX pair. Keep the current promoted profile unchanged.") | Out-Null }
elseif($overall -eq "REPAIR_REPORTS") { $md.Add("Repair or re-export ADX-filter probe reports before making a filter decision.") | Out-Null }
elseif($overall -eq "REVIEW_DRAWDOWN") { $md.Add("An ADX-filter candidate may have profit potential, but drawdown needs review before expanding validation.") | Out-Null }
else { $md.Add("Waiting for exported ADX-filter probe reports. Keep the current promoted profile unchanged.") | Out-Null }

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$rows
