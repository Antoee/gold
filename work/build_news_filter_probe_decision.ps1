param(
   [string]$MetricsPath = "outputs\NEWS_FILTER_PROBE_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\NEWS_FILTER_PROBE_DECISION.csv",
   [string]$OutMarkdown = "outputs\NEWS_FILTER_PROBE_DECISION.md",
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
   [pscustomobject]@{ Pair = "baseline_news_filter"; Candidate = "baseline_promoted_news_filter"; Baseline = "baseline_promoted" },
   [pscustomobject]@{ Pair = "tp38_sl18_news_filter"; Candidate = "tp38_sl18_news_filter"; Baseline = "tp38_sl18" }
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
   $ddDelta = $candidateDd - $baselineDd

   $decision = "WAITING_FOR_REPORTS"
   $reason = "Candidate or paired no-news-filter report is missing."
   if($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") { $decision = "REPAIR_REPORT"; $reason = "At least one paired report exists but could not be parsed." }
   elseif($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateNet -lt 0) { $decision = "FAIL_CANDIDATE_LOSS"; $reason = "News-filter candidate lost money." }
      elseif($candidateNet -lt $baselineNet -and $candidateDd -ge $baselineDd) { $decision = "FAIL_NO_RISK_REWARD"; $reason = "News filter reduced profit without reducing drawdown." }
      elseif($candidateDd -gt $MaxAllowedDrawdownPercent) { $decision = "REVIEW_DRAWDOWN"; $reason = "News-filter candidate passed profit/risk comparison but drawdown needs review." }
      elseif($candidateNet -ge $baselineNet) { $decision = "PASS_NEWS_FILTER_PROBE"; $reason = "News-filter candidate was profitable and matched or beat its no-news-filter pair." }
      elseif($candidateDd -lt $baselineDd) { $decision = "PASS_RISK_REDUCTION_REVIEW"; $reason = "News filter reduced drawdown but gave up some profit; review risk-adjusted tradeoff before expansion." }
      else { $decision = "REVIEW_REQUIRED"; $reason = "Paired comparison is mixed." }
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
      DrawdownDelta = $ddDelta
      Decision = $decision
      Reason = $reason
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$hasPass = @($rows | Where-Object { $_.Decision -in @("PASS_NEWS_FILTER_PROBE", "PASS_RISK_REDUCTION_REVIEW") }).Count -gt 0
$hasFail = @($rows | Where-Object { $_.Decision -like "FAIL_*" }).Count -gt 0
$hasRepair = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($rows | Where-Object { $_.Decision -like "*REVIEW*" }).Count -gt 0
$overall = if($hasPass) { "HAS_NEWS_FILTER_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_REQUIRED" } elseif($hasFail) { "NO_NEWS_FILTER_CANDIDATE" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# News Filter Probe Decision") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline decision gate only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Pair | Candidate Net | Baseline Net | Delta | Candidate DD % | Baseline DD % | DD Delta | Decision | Reason |") | Out-Null
$md.Add("|---|---:|---:|---:|---:|---:|---:|---|---|") | Out-Null
foreach($row in $rows) { $md.Add("| $($row.Pair) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.NetProfitDelta) | $($row.CandidateDrawdownPercent) | $($row.BaselineDrawdownPercent) | $($row.DrawdownDelta) | $($row.Decision) | $($row.Reason) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
if($overall -eq "HAS_NEWS_FILTER_CANDIDATE") { $md.Add("At least one news-filter candidate deserves broader stress/recent-OOS validation. Do not promote from this probe alone.") | Out-Null }
elseif($overall -eq "NO_NEWS_FILTER_CANDIDATE") { $md.Add("No tested news-filter candidate improved the paired risk/reward tradeoff. Keep the current promoted profile unchanged.") | Out-Null }
elseif($overall -eq "REPAIR_REPORTS") { $md.Add("Repair or re-export news-filter probe reports before making a module decision.") | Out-Null }
else { $md.Add("Waiting for exported news-filter probe reports or mixed results need review. Keep the current promoted profile unchanged.") | Out-Null }

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$rows
