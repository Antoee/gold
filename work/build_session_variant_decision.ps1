param(
   [string]$MetricsPath = "outputs\SESSION_VARIANT_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\SESSION_VARIANT_DECISION.csv",
   [string]$OutMarkdown = "outputs\SESSION_VARIANT_DECISION.md",
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
   param([object[]]$Rows, [string]$Profile)
   return $Rows | Where-Object { (Get-Value $_ "Profile") -eq $Profile } | Select-Object -First 1
}

$pairs = @(
   [pscustomobject]@{ Session = "london_07_16"; Candidate = "tp38_sl18_london_07_16"; Baseline = "baseline_promoted_london_pair" },
   [pscustomobject]@{ Session = "newyork_13_22"; Candidate = "tp38_sl18_newyork_13_22"; Baseline = "baseline_promoted_newyork_pair" },
   [pscustomobject]@{ Session = "overlap_13_16"; Candidate = "tp38_sl18_overlap_13_16"; Baseline = "baseline_promoted_overlap_pair" }
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
   $reason = "Candidate or baseline report is missing."
   if($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") {
      $decision = "REPAIR_REPORT"
      $reason = "At least one paired report exists but could not be parsed."
   } elseif($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateNet -lt 0) {
         $decision = "FAIL_CANDIDATE_LOSS"
         $reason = "Session candidate lost money."
      } elseif($candidateNet -lt $baselineNet) {
         $decision = "FAIL_BELOW_BASELINE"
         $reason = "Session candidate underperformed the unfiltered promoted baseline pair."
      } elseif($candidateDd -gt $MaxAllowedDrawdownPercent) {
         $decision = "REVIEW_DRAWDOWN"
         $reason = "Session candidate passed profit comparison but drawdown needs review."
      } else {
         $decision = "PASS_SESSION_PROBE"
         $reason = "Session candidate was profitable and beat its paired baseline."
      }
   }

   $rows.Add([pscustomobject]@{
      Session = $pair.Session
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

$hasPass = @($rows | Where-Object { $_.Decision -eq "PASS_SESSION_PROBE" }).Count -gt 0
$hasFail = @($rows | Where-Object { $_.Decision -like "FAIL_*" }).Count -gt 0
$hasRepair = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($rows | Where-Object { $_.Decision -eq "REVIEW_DRAWDOWN" }).Count -gt 0
$overall = if($hasPass) { "HAS_SESSION_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($hasFail) { "NO_SESSION_CANDIDATE" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Session Variant Decision") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline decision gate only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Session | Candidate Net | Baseline Net | Delta | Candidate DD % | Decision | Reason |") | Out-Null
$md.Add("|---|---:|---:|---:|---:|---|---|") | Out-Null
foreach($row in $rows) {
   $md.Add("| $($row.Session) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.NetProfitDelta) | $($row.CandidateDrawdownPercent) | $($row.Decision) | $($row.Reason) |") | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
if($overall -eq "HAS_SESSION_CANDIDATE") { $md.Add("At least one session variant deserves broader stress/recent-OOS validation. Do not promote from this probe alone.") | Out-Null }
elseif($overall -eq "NO_SESSION_CANDIDATE") { $md.Add("No tested session variant beat its paired baseline. Keep the current promoted profile.") | Out-Null }
elseif($overall -eq "REPAIR_REPORTS") { $md.Add("Repair or re-export session reports before making a session-filter decision.") | Out-Null }
elseif($overall -eq "REVIEW_DRAWDOWN") { $md.Add("A session variant may have profit potential, but drawdown needs review before further validation.") | Out-Null }
else { $md.Add("Waiting for exported session-variant reports. Keep the current promoted profile.") | Out-Null }

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$rows
