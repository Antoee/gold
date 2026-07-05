param(
   [string]$MetricsPath = "outputs\BREAKEVEN_PROBE_REPORT_METRICS.csv",
   [string]$OutCsv = "outputs\BREAKEVEN_PROBE_DECISION.csv",
   [string]$OutMarkdown = "outputs\BREAKEVEN_PROBE_DECISION.md",
   [double]$MaxAllowedDrawdownPercent = 25.0,
   [double]$AllowedProfitTradeoffPercent = 10.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvSafe { param([string]$Path) if(Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) } return @() }
function Get-Value { param([object]$Row, [string]$Name, [object]$Default = "") if($null -eq $Row) { return $Default } $p = $Row.PSObject.Properties[$Name]; if($null -eq $p) { return $Default } return $p.Value }
function To-Double { param([object]$Value, [double]$Default = 0.0) $text = ([string]$Value).Trim(); if([string]::IsNullOrWhiteSpace($text)) { return $Default } $parsed = 0.0; if([double]::TryParse($text, [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) { return $parsed } return $Default }
function Get-DrawdownPercent { param([object]$Row) $v = Get-Value $Row "MaxDrawdownPercent" ""; if([string]::IsNullOrWhiteSpace([string]$v)) { $v = Get-Value $Row "EquityDrawdownPercent" "" }; if([string]::IsNullOrWhiteSpace([string]$v)) { $v = Get-Value $Row "DrawdownPercent" "" }; return To-Double $v }
function Find-MetricRow { param([object[]]$Rows, [string]$Profile) return $Rows | Where-Object { (Get-Value $_ "Profile") -eq $Profile } | Select-Object -First 1 }

$pairs = @(
   [pscustomobject]@{ Pair = "baseline_be"; Candidate = "baseline_promoted_be"; Baseline = "baseline_promoted" },
   [pscustomobject]@{ Pair = "tp38_sl18_be"; Candidate = "tp38_sl18_be"; Baseline = "tp38_sl18" }
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
   $netDelta = $candidateNet - $baselineNet
   $ddDelta = $candidateDd - $baselineDd
   $allowedTradeoff = [Math]::Abs($baselineNet) * ($AllowedProfitTradeoffPercent / 100.0)

   $decision = "WAITING_FOR_REPORTS"
   $reason = "Candidate or paired break-even-off report is missing."
   if($candidateStatus -eq "UNPARSED" -or $baselineStatus -eq "UNPARSED") { $decision = "REPAIR_REPORT"; $reason = "At least one paired report exists but could not be parsed." }
   elseif($candidateStatus -eq "PARSED" -and $baselineStatus -eq "PARSED") {
      if($candidateNet -lt 0) { $decision = "FAIL_CANDIDATE_LOSS"; $reason = "Break-even candidate lost money." }
      elseif($candidateDd -gt $MaxAllowedDrawdownPercent) { $decision = "REVIEW_DRAWDOWN"; $reason = "Break-even candidate profit is non-negative but drawdown needs review." }
      elseif($candidateNet -ge $baselineNet) { $decision = "PASS_BREAKEVEN_PROBE"; $reason = "Break-even candidate was profitable and matched or beat paired baseline net profit." }
      elseif($candidateDd -lt $baselineDd -and [Math]::Abs($netDelta) -le $allowedTradeoff) { $decision = "PASS_RISK_REDUCTION_REVIEW"; $reason = "Break-even reduced drawdown with an acceptable profit tradeoff. Expand only after broader validation." }
      else { $decision = "FAIL_BELOW_BASELINE"; $reason = "Break-even reduced net profit without enough drawdown improvement." }
   }

   $rows.Add([pscustomobject]@{
      Pair = $pair.Pair
      CandidateProfile = $pair.Candidate
      BaselineProfile = $pair.Baseline
      CandidateStatus = $candidateStatus
      BaselineStatus = $baselineStatus
      CandidateNetProfit = $candidateNet
      BaselineNetProfit = $baselineNet
      NetProfitDelta = $netDelta
      CandidateDrawdownPercent = $candidateDd
      BaselineDrawdownPercent = $baselineDd
      DrawdownDeltaPercent = $ddDelta
      Decision = $decision
      Reason = $reason
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$hasPass = @($rows | Where-Object { $_.Decision -in @("PASS_BREAKEVEN_PROBE", "PASS_RISK_REDUCTION_REVIEW") }).Count -gt 0
$hasFail = @($rows | Where-Object { $_.Decision -like "FAIL_*" }).Count -gt 0
$hasRepair = @($rows | Where-Object { $_.Decision -eq "REPAIR_REPORT" }).Count -gt 0
$hasWaiting = @($rows | Where-Object { $_.Decision -eq "WAITING_FOR_REPORTS" }).Count -gt 0
$hasReview = @($rows | Where-Object { $_.Decision -eq "REVIEW_DRAWDOWN" }).Count -gt 0
$overall = if($hasPass) { "HAS_BREAKEVEN_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($hasFail) { "NO_BREAKEVEN_CANDIDATE" } else { "REVIEW_REQUIRED" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Break-Even Probe Decision") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline decision gate only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Pair | Candidate Net | Baseline Net | Delta | Candidate DD % | Baseline DD % | DD Delta | Decision | Reason |") | Out-Null
$md.Add("|---|---:|---:|---:|---:|---:|---:|---|---|") | Out-Null
foreach($row in $rows) { $md.Add("| $($row.Pair) | $($row.CandidateNetProfit) | $($row.BaselineNetProfit) | $($row.NetProfitDelta) | $($row.CandidateDrawdownPercent) | $($row.BaselineDrawdownPercent) | $($row.DrawdownDeltaPercent) | $($row.Decision) | $($row.Reason) |") | Out-Null }
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
if($overall -eq "HAS_BREAKEVEN_CANDIDATE") { $md.Add("At least one break-even candidate deserves broader stress/recent-OOS validation. Do not promote from this probe alone.") | Out-Null }
elseif($overall -eq "NO_BREAKEVEN_CANDIDATE") { $md.Add("No tested break-even candidate beat or risk-improved its paired baseline. Keep break-even disabled in promoted profiles.") | Out-Null }
elseif($overall -eq "REPAIR_REPORTS") { $md.Add("Repair or re-export break-even probe reports before making a break-even decision.") | Out-Null }
elseif($overall -eq "REVIEW_DRAWDOWN") { $md.Add("A break-even candidate may have profit potential, but drawdown needs review before expanding validation.") | Out-Null }
else { $md.Add("Waiting for exported break-even probe reports. Keep the current promoted profile unchanged.") | Out-Null }

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$rows
