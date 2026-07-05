param(
   [string]$MetricsPath = "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
   [string]$ProfilesPath = "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv",
   [string]$OutRanking = "outputs\PROFIT_SEARCH_RANKING.csv",
   [string]$OutReport = "outputs\PROFIT_SEARCH_RANKING.md",
   [double]$BaselineFullProfit = 866.59
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-Double {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function To-Int {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return 0 }
   return [int][double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

if(!(Test-Path -LiteralPath $MetricsPath)) { throw "Metrics file not found: $MetricsPath" }
if(!(Test-Path -LiteralPath $ProfilesPath)) { throw "Profiles manifest not found: $ProfilesPath" }

$metrics = Import-Csv -LiteralPath $MetricsPath
$profiles = Import-Csv -LiteralPath $ProfilesPath
$profileMap = @{}
foreach($profile in $profiles) { $profileMap[[string]$profile.Profile] = $profile }

$phaseWeights = @{ phase1_fast_triage = 0.35; phase2_real_tick_validation = 1.00 }
$rankRows = New-Object System.Collections.Generic.List[object]

foreach($group in ($metrics | Group-Object Profile, Phase)) {
   $parts = $group.Name -split ', '
   $profileName = $parts[0]
   $phase = if($parts.Count -gt 1) { $parts[1] } else { "" }
   $profileInfo = if($profileMap.ContainsKey($profileName)) { $profileMap[$profileName] } else { $null }
   $expected = $group.Count
   $parsedRows = @($group.Group | Where-Object { $_.Status -eq "PARSED" -and "$($_.NetProfit)" -ne "" })
   $profits = @($parsedRows | ForEach-Object { To-Double $_.NetProfit } | Where-Object { $null -ne $_ })
   $drawdowns = @($parsedRows | ForEach-Object { To-Double $_.MaxDrawdownMoney } | Where-Object { $null -ne $_ })
   $profitFactors = @($parsedRows | ForEach-Object { To-Double $_.ProfitFactor } | Where-Object { $null -ne $_ })

   $total = if($profits.Count -gt 0) { ($profits | Measure-Object -Sum).Sum } else { 0.0 }
   $worst = if($profits.Count -gt 0) { ($profits | Measure-Object -Minimum).Minimum } else { $null }
   $best = if($profits.Count -gt 0) { ($profits | Measure-Object -Maximum).Maximum } else { $null }
   $losing = @($profits | Where-Object { $_ -lt 0 }).Count
   $profitable = @($profits | Where-Object { $_ -gt 0 }).Count
   $flat = @($profits | Where-Object { $_ -eq 0 }).Count
   $worstDrawdown = if($drawdowns.Count -gt 0) { ($drawdowns | Measure-Object -Maximum).Maximum } else { $null }
   $avgPf = if($profitFactors.Count -gt 0) { ($profitFactors | Measure-Object -Average).Average } else { $null }
   $coverageRatio = if($expected -gt 0) { $parsedRows.Count / $expected } else { 0.0 }
   $evidenceComplete = $parsedRows.Count -eq $expected

   $phaseWeight = if($phaseWeights.ContainsKey($phase)) { $phaseWeights[$phase] } else { 0.25 }
   $coveragePenalty = (1.0 - $coverageRatio) * 10000.0
   $lossPenalty = $losing * 2500.0
   $worstPenalty = if($null -ne $worst -and $worst -lt 0) { [Math]::Abs($worst) * 8.0 } else { 0.0 }
   $drawdownPenalty = if($null -ne $worstDrawdown) { $worstDrawdown * 0.25 } else { 0.0 }
   $pfCredit = if($null -ne $avgPf -and $avgPf -gt 1.0) { ($avgPf - 1.0) * 250.0 } else { 0.0 }
   $score = ($total * $phaseWeight) + $pfCredit - $coveragePenalty - $lossPenalty - $worstPenalty - $drawdownPenalty

   $grade = "MissingEvidence"
   if($evidenceComplete -and $profits.Count -gt 0) {
      if($total -gt $BaselineFullProfit -and $losing -eq 0 -and $null -ne $worst -and $worst -ge 0) { $grade = if($phase -eq "phase2_real_tick_validation") { "PromotionReview" } else { "Phase2Candidate" } }
      elseif($total -gt 0 -and $losing -eq 0 -and $null -ne $worst -and $worst -ge 0) { $grade = "ResearchReview" }
      elseif($total -gt 0) { $grade = "ProfitButRisky" }
      else { $grade = "Rejected" }
   }

   $rankRows.Add([pscustomobject]@{
      Rank = 0; Priority = if($null -ne $profileInfo) { To-Int $profileInfo.Priority } else { 9999 }; Score = [Math]::Round($score, 2); Grade = $grade; Profile = $profileName; Phase = $phase; Phase2Seed = if($null -ne $profileInfo) { $profileInfo.Phase2Seed } else { "" }; Overrides = if($null -ne $profileInfo) { $profileInfo.Overrides } else { "" }; ReportsExpected = $expected; ReportsParsed = $parsedRows.Count; MissingReports = @($group.Group | Where-Object { $_.Status -eq "MISSING_REPORT" }).Count; UnparsedReports = @($group.Group | Where-Object { $_.Status -eq "UNPARSED" }).Count; EvidenceComplete = $evidenceComplete; TotalNetProfit = [Math]::Round($total, 2); WorstWindowNetProfit = if($null -eq $worst) { "" } else { [Math]::Round($worst, 2) }; BestWindowNetProfit = if($null -eq $best) { "" } else { [Math]::Round($best, 2) }; LosingWindows = $losing; ProfitableWindows = $profitable; FlatWindows = $flat; WorstDrawdownMoney = if($null -eq $worstDrawdown) { "" } else { [Math]::Round($worstDrawdown, 2) }; AverageProfitFactor = if($null -eq $avgPf) { "" } else { [Math]::Round($avgPf, 4) }
   }) | Out-Null
}

$gradeOrder = @{ PromotionReview = 1; Phase2Candidate = 2; ResearchReview = 3; ProfitButRisky = 4; MissingEvidence = 5; Rejected = 6 }
$ranked = $rankRows | Sort-Object @{ Expression = { $gradeOrder[[string]$_.Grade] }; Descending = $false }, @{ Expression = "Score"; Descending = $true }, @{ Expression = "TotalNetProfit"; Descending = $true }, @{ Expression = "WorstWindowNetProfit"; Descending = $true }, @{ Expression = "Priority"; Descending = $false }
$rank = 1
$ranked = foreach($row in $ranked) { $row.Rank = $rank; $rank++; $row }
$ranked | Export-Csv -LiteralPath $OutRanking -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Profit Search Ranking") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from exported MT5 report metrics only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Metrics source: ``$MetricsPath``") | Out-Null
$report.Add("- Profiles source: ``$ProfilesPath``") | Out-Null
$report.Add("- Baseline full-period profit target: $BaselineFullProfit") | Out-Null
$report.Add("- Expected profile/phase rows: $($rankRows.Count)") | Out-Null
$report.Add("- Complete evidence rows: $(@($rankRows | Where-Object EvidenceComplete -eq $true).Count)") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Promotion Review") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Phase | Grade | Score | Parsed | Total | Worst | Losing | DD | PF |") | Out-Null
$report.Add("|---:|---|---|---|---:|---:|---:|---:|---:|---:|---:|") | Out-Null
$promotionRows = @($ranked | Where-Object { $_.Grade -in @("PromotionReview", "Phase2Candidate", "ResearchReview") } | Select-Object -First 20)
if($promotionRows.Count -eq 0) { $report.Add("|  |  |  | No complete profitable evidence yet |  |  |  |  |  |  |  |") | Out-Null } else { foreach($row in $promotionRows) { $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Phase) | $($row.Grade) | $($row.Score) | $($row.ReportsParsed)/$($row.ReportsExpected) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.WorstDrawdownMoney) | $($row.AverageProfitFactor) |") | Out-Null } }
$report.Add("") | Out-Null
$report.Add("## Missing Evidence") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Phase | Parsed/Expected | Missing |") | Out-Null
$report.Add("|---:|---|---|---:|---:|") | Out-Null
foreach($row in (@($ranked | Where-Object Grade -eq "MissingEvidence" | Sort-Object Rank | Select-Object -First 20))) { $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Phase) | $($row.ReportsParsed)/$($row.ReportsExpected) | $($row.MissingReports) |") | Out-Null }
$report.Add("") | Out-Null
$report.Add("## Promotion Rule") | Out-Null
$report.Add("") | Out-Null
$report.Add("Phase-1 rows can only become phase-2 candidates. A replacement profile needs complete phase-2 real-tick evidence, net profit above the baseline target, zero losing windows, non-negative worst window, and drawdown/profit-factor review.") | Out-Null
Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8
$ranked | Select-Object -First 20
