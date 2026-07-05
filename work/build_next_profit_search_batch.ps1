param(
   [string]$ManifestPath = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
   [string]$MetricsPath = "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
   [string]$ProfilesPath = "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv",
   [string]$GuardrailPath = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$OutCsv = "outputs\NEXT_PROFIT_SEARCH_BATCH.csv",
   [string]$OutReport = "outputs\NEXT_PROFIT_SEARCH_BATCH.md",
   [int]$BatchSize = 24
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-Double {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-MetricKey {
   param([object]$Row)
   return "$($Row.Phase)|$($Row.Profile)|$($Row.Set)|$($Row.Window)"
}

function Get-ReportName {
   param([object]$Row)

   $phaseShort = if($Row.Phase -eq "phase1_fast_triage") { "phase1" } elseif($Row.Phase -eq "phase2_real_tick_validation") { "phase2" } else { $Row.Phase }
   return "profit_search_${phaseShort}_$($Row.Profile)_$($Row.Set)_$($Row.Window)"
}

if(!(Test-Path -LiteralPath $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
if(!(Test-Path -LiteralPath $MetricsPath)) { throw "Metrics file not found: $MetricsPath" }
if(!(Test-Path -LiteralPath $ProfilesPath)) { throw "Profiles file not found: $ProfilesPath" }

$manifest = Import-Csv -LiteralPath $ManifestPath
$metrics = Import-Csv -LiteralPath $MetricsPath
$profiles = Import-Csv -LiteralPath $ProfilesPath
$guardrails = if(Test-Path -LiteralPath $GuardrailPath) { @(Import-Csv -LiteralPath $GuardrailPath) } else { @() }

$profileMap = @{}
foreach($profile in $profiles) {
   $profileMap[[string]$profile.Profile] = $profile
}

$guardrailMap = @{}
foreach($guardrail in $guardrails) {
   $guardrailMap[[string]$guardrail.Profile] = $guardrail
}

$metricMap = @{}
foreach($metric in $metrics) {
   $metricMap[(Get-MetricKey $metric)] = $metric
}

$profileStats = @{}
foreach($profileName in ($profiles | ForEach-Object Profile)) {
   $phase1Rows = @($metrics | Where-Object { $_.Profile -eq $profileName -and $_.Phase -eq "phase1_fast_triage" -and $_.Status -eq "PARSED" })
   $profits = @($phase1Rows | ForEach-Object { To-Double $_.NetProfit } | Where-Object { $null -ne $_ })
   $losing = @($profits | Where-Object { $_ -lt 0 }).Count
   $worst = if($profits.Count -gt 0) { ($profits | Measure-Object -Minimum).Minimum } else { $null }
   $total = if($profits.Count -gt 0) { ($profits | Measure-Object -Sum).Sum } else { 0.0 }

   $profileStats[$profileName] = [pscustomobject]@{
      ParsedPhase1 = $phase1Rows.Count
      Phase1Losing = $losing
      Phase1Worst = $worst
      Phase1Total = $total
   }
}

$queue = New-Object System.Collections.Generic.List[object]

foreach($row in $manifest) {
   $key = Get-MetricKey $row
   $metric = if($metricMap.ContainsKey($key)) { $metricMap[$key] } else { $null }
   $status = if($null -eq $metric) { "MISSING_METRIC_ROW" } else { [string]$metric.Status }
   if($status -eq "PARSED") { continue }

   $profile = if($profileMap.ContainsKey($row.Profile)) { $profileMap[$row.Profile] } else { $null }
   $guardrail = if($guardrailMap.ContainsKey($row.Profile)) { $guardrailMap[$row.Profile] } else { $null }
   $priority = if($null -ne $profile) { [int]$profile.Priority } else { [int]$row.Priority }
   $phase2Seed = if($null -ne $profile) { [string]$profile.Phase2Seed -eq "True" } else { $false }
   $stats = $profileStats[$row.Profile]
   $guardrailScore = if($null -ne $guardrail -and -not [string]::IsNullOrWhiteSpace([string]$guardrail.GuardrailScore)) { [int]$guardrail.GuardrailScore } else { 75 }
   $guardrailStatus = if($null -ne $guardrail) { [string]$guardrail.GuardrailStatus } else { "UNKNOWN" }
   $riskFlags = if($null -ne $guardrail) { [string]$guardrail.RiskFlags } else { "" }
   $overfitFlags = if($null -ne $guardrail) { [string]$guardrail.OverfitFlags } else { "" }

   $score = 0
   $reason = ""
   $role = ""

   if($status -eq "UNPARSED") {
      $score += 50000
      $reason = "Report exists but did not parse; fix/export this before adding more evidence."
      $role = "Repair existing evidence"
   } elseif($row.Phase -eq "phase1_fast_triage") {
      $score += 20000
      $score += (($guardrailScore - 75) * 120)
      if($phase2Seed) { $score += 600 }
      if($row.Profile -eq "baseline_promoted") { $score += 1200 }
      $role = "Fast prune"
      $reason = "Cheap phase-1 coverage before spending real-tick time."
      if($row.Set -eq "stress") { $score += 1200; $reason = "Stress-window fast prune." }
      elseif($row.Set -eq "full") { $score += 950; $reason = "Fast full-period sanity check." }
      elseif($row.Set -eq "opportunity") { $score += 650; $reason = "Opportunity-window upside check." }
      if($guardrailStatus -eq "REJECT_PROMOTION") {
         $score -= 4000
         $reason = "$reason Guardrail rejects promotion; keep as low-priority research."
      } elseif($guardrailStatus -eq "REVIEW_REQUIRED" -and $guardrailScore -ge 85) {
         $score += 600
         $reason = "$reason High guardrail score; useful risk-control candidate."
      }
      $score -= ($priority * 60)
   } elseif($row.Phase -eq "phase2_real_tick_validation") {
      $score += 12000
      $score += (($guardrailScore - 75) * 80)
      $role = "Real-tick validation"
      $reason = "Required real-tick evidence for promotion."
      if($phase2Seed) { $score += 1200 }
      if($row.Profile -eq "baseline_promoted") { $score += 1000; $reason = "Baseline real-tick anchor for comparing candidate reports." }
      if($stats.Phase1Losing -gt 0) { $score -= 5000; $reason = "Phase-1 has a losing window; real-tick validation is lower priority." }
      if($null -ne $stats.Phase1Worst -and $stats.Phase1Worst -ge 0 -and $stats.ParsedPhase1 -gt 0) { $score += 900 }
      if($row.Set -eq "split") { $score += 900 }
      elseif($row.Set -eq "quarter") { $score += 500 }
      if($row.Window -eq "full") { $score += 1000 }
      if($guardrailStatus -eq "REJECT_PROMOTION") {
         $score -= 6000
         $reason = "$reason Guardrail rejects promotion; phase-2 should wait."
      }
      $score -= ($priority * 80)
   } else {
      $score += 1000
      $role = "Unknown phase"
      $reason = "Unknown manifest phase."
   }

   $queue.Add([pscustomobject]@{
      Rank = 0
      Score = [Math]::Round($score, 2)
      Priority = $priority
      Role = $role
      Reason = $reason
      Status = $status
      Phase = $row.Phase
      Model = $row.Model
      Profile = $row.Profile
      Set = $row.Set
      Window = $row.Window
      From = $row.From
      To = $row.To
      Config = $row.Config
      ExpectedReportName = Get-ReportName $row
      Phase1ParsedForProfile = $stats.ParsedPhase1
      Phase1LosingForProfile = $stats.Phase1Losing
      Phase1WorstForProfile = if($null -eq $stats.Phase1Worst) { "" } else { [Math]::Round($stats.Phase1Worst, 2) }
      Phase1TotalForProfile = [Math]::Round($stats.Phase1Total, 2)
      GuardrailStatus = $guardrailStatus
      GuardrailScore = $guardrailScore
      RiskFlags = $riskFlags
      OverfitFlags = $overfitFlags
   }) | Out-Null
}

$ranked = $queue |
   Sort-Object `
      @{ Expression = "Score"; Descending = $true },
      @{ Expression = "Priority"; Descending = $false },
      @{ Expression = "Phase"; Descending = $false },
      @{ Expression = "Profile"; Descending = $false },
      @{ Expression = "Set"; Descending = $false },
      @{ Expression = "Window"; Descending = $false } |
   Select-Object -First $BatchSize

$rank = 1
$ranked = foreach($item in $ranked) {
   $item.Rank = $rank
   $rank++
   $item
}

$ranked | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$allMissing = @($queue | Where-Object { $_.Status -ne "PARSED" }).Count
$phase1Missing = @($queue | Where-Object { $_.Phase -eq "phase1_fast_triage" }).Count
$phase2Missing = @($queue | Where-Object { $_.Phase -eq "phase2_real_tick_validation" }).Count
$unparsed = @($queue | Where-Object { $_.Status -eq "UNPARSED" }).Count

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Next Profit Search Batch") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated without launching MT5. This is a prioritized run list only.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Manifest: ``$ManifestPath``") | Out-Null
$report.Add("- Metrics: ``$MetricsPath``") | Out-Null
$report.Add("- Guardrails: ``$GuardrailPath``") | Out-Null
$report.Add("- Batch size: $BatchSize") | Out-Null
$report.Add("- Missing/unparsed configs: $allMissing") | Out-Null
$report.Add("- Phase-1 remaining: $phase1Missing") | Out-Null
$report.Add("- Phase-2 remaining: $phase2Missing") | Out-Null
$report.Add("- Unparsed reports needing repair: $unparsed") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Recommended Next Runs") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Phase | Set | Window | Model | Guardrail | Role | Reason | Config |") | Out-Null
$report.Add("|---:|---|---|---|---|---:|---:|---|---|---|") | Out-Null
foreach($item in $ranked) {
   $report.Add("| $($item.Rank) | ``$($item.Profile)`` | $($item.Phase) | $($item.Set) | $($item.Window) | $($item.Model) | $($item.GuardrailScore) | $($item.Role) | $($item.Reason) | ``$($item.Config)`` |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Rule") | Out-Null
$report.Add("") | Out-Null
$report.Add("Use this list to spend limited MT5 time on the highest-information windows first. Guardrail score can move risk-control profiles earlier, but phase 1 is pruning only; no profile can replace the current default without complete phase-2 real-tick evidence, guardrail review, and the promotion gate passing.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$ranked
