param(
   [string]$RankingPath = "outputs\PROFIT_SEARCH_RANKING.csv",
   [string]$OutCsv = "outputs\RESULT_IMPORT_DECISION_MATRIX.csv",
   [string]$OutReport = "outputs\RESULT_IMPORT_DECISION_MATRIX.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-BoolText {
   param([object]$Value)
   return ([string]$Value).Trim().ToLowerInvariant() -eq "true"
}

function To-Int {
   param([object]$Value)
   if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return 0 }
   return [int][double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-Decision {
   param([object]$Row)

   $phase = [string]$Row.Phase
   $grade = [string]$Row.Grade
   $complete = To-BoolText $Row.EvidenceComplete
   $missing = To-Int $Row.MissingReports
   $unparsed = To-Int $Row.UnparsedReports
   $losing = To-Int $Row.LosingWindows

   if(-not $complete) {
      if($unparsed -gt 0) {
         return @("RepairReport", "Fix or re-export unparsed MT5 reports before judging the profile.")
      }
      if($missing -gt 0) {
         return @("RunMissingReports", "Run or import the missing reports for this profile and phase.")
      }
      return @("IncompleteEvidence", "Evidence is incomplete; do not promote or reject yet.")
   }

   if($grade -eq "PromotionReview" -and $phase -eq "phase2_real_tick_validation") {
      return @("BuildPromotionPacket", "Build the promotion packet and review drawdown, trade count, data quality, and overfitting risk.")
   }

   if($grade -eq "Phase2Candidate" -and $phase -eq "phase1_fast_triage") {
      return @("AdvanceToPhase2", "Queue phase-2 real-tick validation; phase-1 cannot promote a profile.")
   }

   if($grade -eq "ResearchReview") {
      return @("KeepForResearch", "Profitable and non-losing, but below the replacement profit target.")
   }

   if($grade -eq "ProfitButRisky" -or $losing -gt 0) {
      return @("RejectForLossRisk", "Profit exists, but losing windows violate the risk-first rule.")
   }

   if($grade -eq "Rejected") {
      return @("Reject", "Complete evidence does not justify more tester time.")
   }

   return @("ManualReview", "No automatic decision matched; inspect the row manually.")
}

if(!(Test-Path -LiteralPath $RankingPath)) {
   throw "Ranking file not found: $RankingPath"
}

$ranking = Import-Csv -LiteralPath $RankingPath
$rows = New-Object System.Collections.Generic.List[object]

foreach($row in $ranking) {
   $decision = Get-Decision $row
   $rows.Add([pscustomobject]@{
      Rank = $row.Rank
      Profile = $row.Profile
      Phase = $row.Phase
      Grade = $row.Grade
      EvidenceComplete = $row.EvidenceComplete
      Parsed = "$($row.ReportsParsed)/$($row.ReportsExpected)"
      MissingReports = $row.MissingReports
      UnparsedReports = $row.UnparsedReports
      TotalNetProfit = $row.TotalNetProfit
      WorstWindowNetProfit = $row.WorstWindowNetProfit
      LosingWindows = $row.LosingWindows
      Decision = $decision[0]
      Reason = $decision[1]
   }) | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Result Import Decision Matrix") | Out-Null
$report.Add("") | Out-Null
$report.Add("Generated from normalized ranking evidence only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Ranking source: ``$RankingPath``") | Out-Null
$report.Add("- Rows reviewed: $($rows.Count)") | Out-Null
$report.Add("") | Out-Null
$report.Add("## Decision Counts") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Decision | Rows |") | Out-Null
$report.Add("|---|---:|") | Out-Null
foreach($group in ($rows | Group-Object Decision | Sort-Object Name)) {
   $report.Add("| $($group.Name) | $($group.Count) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Immediate Queue") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Rank | Profile | Phase | Grade | Parsed | Decision | Reason |") | Out-Null
$report.Add("|---:|---|---|---|---:|---|---|") | Out-Null
$top = @($rows | Where-Object { $_.Decision -in @("BuildPromotionPacket", "AdvanceToPhase2", "RepairReport", "RunMissingReports") } | Select-Object -First 25)
if($top.Count -eq 0) {
   $report.Add("|  |  |  |  |  | No immediate queue items |  |") | Out-Null
} else {
   foreach($row in $top) {
      $report.Add("| $($row.Rank) | ``$($row.Profile)`` | $($row.Phase) | $($row.Grade) | $($row.Parsed) | $($row.Decision) | $($row.Reason) |") | Out-Null
   }
}

$report.Add("") | Out-Null
$report.Add("## Rules") | Out-Null
$report.Add("") | Out-Null
$report.Add("- `RunMissingReports`: evidence is missing; run/import those reports before judging.") | Out-Null
$report.Add("- `RepairReport`: a report exists but did not parse; fix export format or parser coverage.") | Out-Null
$report.Add("- `AdvanceToPhase2`: phase-1 evidence is complete and clean enough to justify real-tick validation.") | Out-Null
$report.Add("- `BuildPromotionPacket`: phase-2 evidence passed automatic profit/no-loss gates; still requires promotion packet review.") | Out-Null
$report.Add("- `RejectForLossRisk`: any losing validation window blocks promotion, even if net profit is positive.") | Out-Null
$report.Add("- `KeepForResearch`: useful clue, but not a replacement for the promoted default.") | Out-Null

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$rows | Select-Object -First 20
