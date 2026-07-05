param(
   [string]$ManifestPath = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
   [string]$MetricsPath = "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
   [string]$ProfilesPath = "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv",
   [string]$GuardrailPath = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$OutCsv = "outputs\RISK_ADJUSTED_MICRO_BATCH.csv",
   [string]$OutReport = "outputs\RISK_ADJUSTED_MICRO_BATCH.md",
   [int]$BatchSize = 12,
   [int]$MaxPerProfile = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Key {
   param([object]$Row)
   return "$($Row.Phase)|$($Row.Profile)|$($Row.Set)|$($Row.Window)"
}

function To-Int {
   param([object]$Value, [int]$Default = 0)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $Default }
   return [int][double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function To-Double {
   param([object]$Value, [double]$Default = 0.0)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $Default }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Contains-Flag {
   param([string]$Flags, [string]$Needle)
   return -not [string]::IsNullOrWhiteSpace($Flags) -and $Flags.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Get-ExpectedReportName {
   param([object]$Row)
   $phaseShort = if($Row.Phase -eq "phase1_fast_triage") { "phase1" } elseif($Row.Phase -eq "phase2_real_tick_validation") { "phase2" } else { $Row.Phase }
   return "profit_search_${phaseShort}_$($Row.Profile)_$($Row.Set)_$($Row.Window)"
}

if(!(Test-Path -LiteralPath $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
if(!(Test-Path -LiteralPath $MetricsPath)) { throw "Metrics not found: $MetricsPath" }
if(!(Test-Path -LiteralPath $ProfilesPath)) { throw "Profiles not found: $ProfilesPath" }
if(!(Test-Path -LiteralPath $GuardrailPath)) { throw "Guardrails not found: $GuardrailPath" }

$manifest = @(Import-Csv -LiteralPath $ManifestPath)
$metrics = @(Import-Csv -LiteralPath $MetricsPath)
$profiles = @(Import-Csv -LiteralPath $ProfilesPath)
$guardrails = @(Import-Csv -LiteralPath $GuardrailPath)

$metricMap = @{}
foreach($metric in $metrics) { $metricMap[(Get-Key $metric)] = $metric }

$profileMap = @{}
foreach($profile in $profiles) { $profileMap[[string]$profile.Profile] = $profile }

$guardrailMap = @{}
foreach($guardrail in $guardrails) { $guardrailMap[[string]$guardrail.Profile] = $guardrail }

$phase1StressWindows = @("2024_Q1", "2024_Q3", "2025_Q2", "2025_Q3")
$queue = New-Object System.Collections.Generic.List[object]

foreach($row in $manifest) {
   $metric = if($metricMap.ContainsKey((Get-Key $row))) { $metricMap[(Get-Key $row)] } else { $null }
   $status = if($null -eq $metric) { "MISSING_METRIC_ROW" } else { [string]$metric.Status }
   if($status -eq "PARSED") { continue }

   $profile = if($profileMap.ContainsKey($row.Profile)) { $profileMap[$row.Profile] } else { $null }
   $guardrail = if($guardrailMap.ContainsKey($row.Profile)) { $guardrailMap[$row.Profile] } else { $null }
   $priority = if($null -ne $profile) { To-Int $profile.Priority 999 } else { To-Int $row.Priority 999 }
   $phase2Seed = if($null -ne $profile) { [string]$profile.Phase2Seed -eq "True" } else { $false }
   $guardrailStatus = if($null -ne $guardrail) { [string]$guardrail.GuardrailStatus } else { "UNKNOWN" }
   $guardrailScore = if($null -ne $guardrail) { To-Int $guardrail.GuardrailScore 50 } else { 50 }
   $riskPercent = if($null -ne $guardrail) { To-Double $guardrail.RiskPercent 99.0 } else { 99.0 }
   $riskFlags = if($null -ne $guardrail) { [string]$guardrail.RiskFlags } else { "" }
   $overfitFlags = if($null -ne $guardrail) { [string]$guardrail.OverfitFlags } else { "" }
   $usesGiveback = if($null -ne $guardrail) { [string]$guardrail.UsesGivebackGuard -eq "True" } else { $false }

   $score = 0.0
   $role = "Candidate"
   $reason = "Risk-adjusted candidate coverage."

   if($status -eq "UNPARSED") {
      $score = 90000
      $role = "Repair"
      $reason = "Report exists but did not parse; repair before adding more runs."
   } elseif($row.Phase -eq "phase1_fast_triage") {
      $score = 30000 + ($guardrailScore * 150) - ($priority * 80)
      if($row.Set -eq "stress") { $score += 2500; $reason = "Fast stress-window prune." }
      if($row.Set -eq "full") { $score += 1200; $reason = "Fast full-period sanity check." }
      if($row.Set -eq "opportunity") { $score += 500; $reason = "Opportunity-window upside check." }
      if($phase2Seed) { $score += 1500 }
      if($usesGiveback) { $score += 800 }
      if($row.Profile -eq "baseline_promoted") {
         $score += 4500
         $role = "Baseline anchor"
         $reason = "Required same-window anchor for candidate comparison."
      }
      if($row.Set -eq "stress" -and $phase1StressWindows -contains [string]$row.Window) { $score += 1500 }
      if($guardrailStatus -eq "REJECT_PROMOTION") { $score -= 12000; $reason = "$reason Guardrail rejects promotion." }
      if($riskPercent -gt 1.6) { $score -= 3000 }
      if(Contains-Flag $overfitFlags "far_tp_extension") { $score -= 1800 }
      if(Contains-Flag $overfitFlags "tighter_stop_variant") { $score -= 1600 }
      if(Contains-Flag $riskFlags "risk_percent_above_promoted") { $score -= 3000 }
   } elseif($row.Phase -eq "phase2_real_tick_validation") {
      $score = 18000 + ($guardrailScore * 80) - ($priority * 100)
      $role = "Real-tick anchor"
      $reason = "Higher-cost validation; run after micro phase-1 evidence unless it is the baseline."
      if($row.Profile -eq "baseline_promoted") { $score += 6000; $reason = "Baseline real-tick anchor." }
      if($phase2Seed) { $score += 1000 }
      if($riskPercent -gt 1.6) { $score -= 3500 }
      if($guardrailStatus -eq "REJECT_PROMOTION") { $score -= 12000 }
   } else {
      $score = 1000
      $role = "Unknown"
      $reason = "Unknown phase."
   }

   $queue.Add([pscustomobject]@{
      Rank = 0
      Score = [Math]::Round($score, 2)
      Role = $role
      Reason = $reason
      Status = $status
      Priority = $priority
      Phase = $row.Phase
      Model = $row.Model
      Profile = $row.Profile
      Set = $row.Set
      Window = $row.Window
      From = $row.From
      To = $row.To
      Config = $row.Config
      ExpectedReportName = Get-ExpectedReportName $row
      GuardrailStatus = $guardrailStatus
      GuardrailScore = $guardrailScore
      RiskPercent = $riskPercent
      UsesGivebackGuard = $usesGiveback
      RiskFlags = $riskFlags
      OverfitFlags = $overfitFlags
   }) | Out-Null
}

$selected = New-Object System.Collections.Generic.List[object]
$perProfile = @{}
foreach($item in ($queue | Sort-Object @{ Expression = "Score"; Descending = $true }, Priority, Profile, Set, Window)) {
   if($selected.Count -ge $BatchSize) { break }
   if(!$perProfile.ContainsKey($item.Profile)) { $perProfile[$item.Profile] = 0 }
   $limit = if($item.Profile -eq "baseline_promoted") { [Math]::Max($MaxPerProfile, 5) } else { $MaxPerProfile }
   if($perProfile[$item.Profile] -ge $limit) { continue }
   $selected.Add($item) | Out-Null
   $perProfile[$item.Profile]++
}

$rank = 1
$ranked = foreach($item in $selected) {
   $item.Rank = $rank
   $rank++
   $item
}

$ranked | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$byRole = $ranked | Group-Object Role | Sort-Object Name
$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Risk-Adjusted Micro Batch") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated without launching MT5. This is a compact high-information batch for limited tester time.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Batch size: $BatchSize") | Out-Null
$report.Add("- Max per profile: $MaxPerProfile") | Out-Null
$report.Add("- Candidate rows considered: $($queue.Count)") | Out-Null
$report.Add("- Selected rows: $($ranked.Count)") | Out-Null
$report.Add("- Rule: repair bad reports first, include baseline anchors, prefer stress windows, then diversify high guardrail-score candidates.") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Role Mix") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Role | Rows |") | Out-Null
$report.Add("|---|---:|") | Out-Null
foreach($role in $byRole) {
   $report.Add("| $($role.Name) | $($role.Count) |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Runs") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Phase | Set | Window | Model | Score | Guardrail | Role | Reason | Config |") | Out-Null
$report.Add("|---:|---|---|---|---|---:|---:|---:|---|---|---|") | Out-Null
foreach($item in $ranked) {
   $report.Add("| $($item.Rank) | ``$($item.Profile)`` | $($item.Phase) | $($item.Set) | $($item.Window) | $($item.Model) | $($item.Score) | $($item.GuardrailScore) | $($item.Role) | $($item.Reason) | ``$($item.Config)`` |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Promotion Discipline") | Out-Null
$report.Add("") | Out-Null
$report.Add("This batch can only produce triage evidence. Promotion still requires complete phase-2 real-tick validation, no losing validation windows, acceptable drawdown, compile PASS, local safety PASS, and the promotion gate passing.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$ranked
