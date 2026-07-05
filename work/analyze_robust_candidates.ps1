param(
   [string]$OutputsDir = "outputs",
   [string]$RankingCsv = "outputs\ROBUST_CANDIDATE_RANKING.csv",
   [string]$ReportPath = "outputs\ROBUST_CANDIDATE_RANKING.md",
   [int]$MinPromotionWindows = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToDouble {
   param([object]$Value)
   if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
      return 0.0
   }
   return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Convert-ToInt {
   param([object]$Value)
   if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
      return 0
   }
   return [int][double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-Field {
   param(
      [object]$Row,
      [string[]]$Names,
      [object]$Default = $null
   )

   foreach ($name in $Names) {
      if ($Row.PSObject.Properties.Name -contains $name) {
         return $Row.$name
      }
   }
   return $Default
}

if (!(Test-Path -LiteralPath $OutputsDir)) {
   throw "Outputs directory not found: $OutputsDir"
}

$summaryFiles = Get-ChildItem -LiteralPath $OutputsDir -Filter "*SUMMARY*.csv" -File |
   Where-Object { $_.Name -notin @("ROBUST_CANDIDATE_RANKING.csv") }

$rows = New-Object System.Collections.Generic.List[object]

foreach ($file in $summaryFiles) {
   $csvRows = Import-Csv -LiteralPath $file.FullName
   foreach ($row in $csvRows) {
      if (!($row.PSObject.Properties.Name -contains "TotalNetProfit")) {
         continue
      }

      $candidate = Get-Field -Row $row -Names @("Candidate", "Set") -Default $file.BaseName
      if ([string]::IsNullOrWhiteSpace([string]$candidate)) {
         $candidate = $file.BaseName
      }

      $windows = Convert-ToInt (Get-Field -Row $row -Names @("Windows") -Default 1)
      $total = Convert-ToDouble (Get-Field -Row $row -Names @("TotalNetProfit") -Default 0)
      $worst = Convert-ToDouble (Get-Field -Row $row -Names @("WorstWindowNetProfit") -Default 0)
      $best = Convert-ToDouble (Get-Field -Row $row -Names @("BestWindowNetProfit") -Default 0)
      $profitable = Convert-ToInt (Get-Field -Row $row -Names @("ProfitableWindows") -Default 0)
      $flat = Convert-ToInt (Get-Field -Row $row -Names @("FlatWindows") -Default 0)
      $losing = Convert-ToInt (Get-Field -Row $row -Names @("LosingWindows") -Default 0)

      $avg = if ($windows -gt 0) { $total / $windows } else { $total }
      $lossPenalty = $losing * 1000.0
      $worstPenalty = if ($worst -lt 0) { [Math]::Abs($worst) * 4.0 } else { 0.0 }
      $flatPenalty = $flat * 2.0
      $profitCredit = $profitable * 10.0
      $coveragePenalty = if ($windows -lt $MinPromotionWindows) { ($MinPromotionWindows - $windows) * 250.0 } else { 0.0 }
      $score = $total - $lossPenalty - $worstPenalty - $flatPenalty - $coveragePenalty + $profitCredit

      $grade = "Rejected"
      if ($total -gt 0 -and $losing -eq 0 -and $worst -ge 0 -and $windows -ge $MinPromotionWindows) {
         $grade = "PromotionCandidate"
      }
      elseif ($total -gt 0 -and $losing -eq 0 -and $worst -ge 0) {
         $grade = "BenchmarkOnly"
      }
      elseif ($total -gt 0 -and $losing -le 1 -and $worst -ge -200) {
         $grade = "ResearchCandidate"
      }

      $rows.Add([pscustomobject]@{
         Rank = 0
         RobustScore = [Math]::Round($score, 2)
         Grade = $grade
         Candidate = [string]$candidate
         SourceFile = $file.Name
         Windows = $windows
         TotalNetProfit = [Math]::Round($total, 2)
         AverageWindowNetProfit = [Math]::Round($avg, 2)
         WorstWindowNetProfit = [Math]::Round($worst, 2)
         BestWindowNetProfit = [Math]::Round($best, 2)
         ProfitableWindows = $profitable
         FlatWindows = $flat
         LosingWindows = $losing
      }) | Out-Null
   }
}

$gradeOrder = @{
   PromotionCandidate = 1
   ResearchCandidate = 2
   BenchmarkOnly = 3
   Rejected = 4
}

$ranked = $rows |
   Sort-Object `
      @{ Expression = { $gradeOrder[[string]$_.Grade] }; Descending = $false },
      @{ Expression = "RobustScore"; Descending = $true },
      @{ Expression = "TotalNetProfit"; Descending = $true },
      @{ Expression = "WorstWindowNetProfit"; Descending = $true }

$rank = 1
$ranked = foreach ($row in $ranked) {
   $row.Rank = $rank
   $rank++
   $row
}

$ranked | Export-Csv -LiteralPath $RankingCsv -NoTypeInformation

$topPromotion = $ranked | Where-Object Grade -eq "PromotionCandidate" | Select-Object -First 10
$topResearch = $ranked | Where-Object Grade -eq "ResearchCandidate" | Select-Object -First 10

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Robust Candidate Ranking") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from existing summary CSV files only. No MT5 test was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("Scoring favors net profit, but heavily penalizes losing windows, negative worst-window results, and thin validation coverage. Promotion candidates require at least $MinPromotionWindows windows.") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Top Promotion Candidates") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Candidate | Source | Score | Total | Worst | Losing | Windows |") | Out-Null
$report.Add("| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |") | Out-Null
foreach ($row in $topPromotion) {
   $report.Add("| $($row.Rank) | ``$($row.Candidate)`` | ``$($row.SourceFile)`` | $($row.RobustScore) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.Windows) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Top Research Candidates") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Candidate | Source | Score | Total | Worst | Losing | Windows |") | Out-Null
$report.Add("| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |") | Out-Null
foreach ($row in $topResearch) {
   $report.Add("| $($row.Rank) | ``$($row.Candidate)`` | ``$($row.SourceFile)`` | $($row.RobustScore) | $($row.TotalNetProfit) | $($row.WorstWindowNetProfit) | $($row.LosingWindows) | $($row.Windows) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Recommended Next Action") | Out-Null
$report.Add("") | Out-Null
$report.Add("Validate only the highest-ranked promotion candidates across monthly, quarterly, yearly, half-year, and full-period windows once local MT5 can run without affecting normal PC use.") | Out-Null

Set-Content -LiteralPath $ReportPath -Value $report -Encoding UTF8

$ranked | Select-Object -First 15
