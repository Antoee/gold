param(
   [string]$OutCsv = "outputs\FAST_PROBE_READINESS_SNAPSHOT.csv",
   [string]$OutMarkdown = "outputs\FAST_PROBE_READINESS_SNAPSHOT.md"
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

function Add-Probe {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Gate,
      [string]$Path,
      [string[]]$PassDecisions,
      [string[]]$FailPrefixes,
      [string]$MissingAction,
      [string]$PassAction,
      [string]$FailAction
   )

   $data = Read-CsvSafe $Path
   if($data.Count -eq 0) {
      $Rows.Add([pscustomobject]@{
         Gate = $Gate
         Status = "WAITING_FOR_REPORTS"
         Rows = 0
         DecisionCounts = "missing=$Path"
         NextAction = $MissingAction
      }) | Out-Null
      return
   }

   $decisionRows = @($data | ForEach-Object { [pscustomobject]@{ Decision = (Get-Value $_ "Decision" "UNKNOWN") } })
   $decisionCounts = ($decisionRows | Group-Object -Property Decision | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
   $hasRepair = @($data | Where-Object { (Get-Value $_ "Decision") -eq "REPAIR_REPORT" }).Count -gt 0
   $hasWaiting = @($data | Where-Object { (Get-Value $_ "Decision") -eq "WAITING_FOR_REPORTS" }).Count -gt 0
   $hasReview = @($data | Where-Object { (Get-Value $_ "Decision") -like "*REVIEW*" }).Count -gt 0
   $hasFail = $false
   foreach($row in $data) {
      $decision = [string](Get-Value $row "Decision" "")
      foreach($prefix in $FailPrefixes) {
         if($decision -like "$prefix*") { $hasFail = $true }
      }
   }
   $passRows = @($data | Where-Object { $PassDecisions -contains (Get-Value $_ "Decision" "") })
   $allPass = $data.Count -gt 0 -and $passRows.Count -eq $data.Count
   $hasPass = $passRows.Count -gt 0

   $status = if($hasFail) { "FAIL" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($allPass) { "PASS" } elseif($hasPass) { "PARTIAL_PASS" } else { "REVIEW_REQUIRED" }
   $next = if($status -eq "PASS") { $PassAction } elseif($status -eq "PARTIAL_PASS") { "Expand only the passing paired candidate; do not promote from this fast probe alone." } elseif($status -eq "FAIL") { $FailAction } elseif($status -eq "REPAIR_REPORTS") { "Repair or re-export reports before making a gate decision." } elseif($status -eq "WAITING_FOR_REPORTS") { $MissingAction } else { "Review drawdown and paired baseline evidence before expanding tester time." }

   $Rows.Add([pscustomobject]@{
      Gate = $Gate
      Status = $status
      Rows = $data.Count
      DecisionCounts = $decisionCounts
      NextAction = $next
   }) | Out-Null
}

$rows = New-Object System.Collections.Generic.List[object]

Add-Probe $rows "STRESS_MICRO" "outputs\MICRO_TEST_DECISION.csv" @("PASS_WINDOW") @("FAIL_") "Run/import stress micro reports first." "Proceed to RECENT_OOS only if every paired stress window passed." "Reject or deprioritize the candidate that failed a stress window."
Add-Probe $rows "RECENT_OOS" "outputs\RECENT_OOS_DECISION.csv" @("PASS_RECENT_OOS", "PASS_WINDOW") @("FAIL_") "Run/import recent-OOS reports after stress micro passes." "Proceed to full handoff only after recent-OOS passes." "Reject or deprioritize the candidate that failed recent-OOS."
Add-Probe $rows "CONFIRMATION_PROBE" "outputs\CONFIRMATION_PROBE_DECISION.csv" @("PASS_CONFIRMATION_PROBE") @("FAIL_") "Run/import confirmation probe reports." "Expand passing confirmation profile into stress/recent-OOS validation." "Keep current confirmation setting for failed variants."
Add-Probe $rows "BREAKEVEN_PROBE" "outputs\BREAKEVEN_PROBE_DECISION.csv" @("PASS_BREAKEVEN_PROBE", "PASS_RISK_REDUCTION_REVIEW") @("FAIL_") "Run/import break-even probe reports." "Expand passing break-even profile into stress/recent-OOS validation." "Keep break-even disabled for failed variants."
Add-Probe $rows "ADX_FILTER_PROBE" "outputs\ADX_FILTER_PROBE_DECISION.csv" @("PASS_ADX_FILTER_PROBE") @("FAIL_") "Run/import ADX filter probe reports." "Expand passing ADX profile into stress/recent-OOS validation." "Keep ADX threshold unchanged for failed variants."
Add-Probe $rows "SPREAD_GUARD_PROBE" "outputs\SPREAD_GUARD_PROBE_DECISION.csv" @("PASS_SPREAD_GUARD_PROBE", "PASS_ATR_SPREAD_GUARD_PROBE") @("FAIL_") "Run/import ATR spread guard probe reports." "Expand passing spread-guard profile into stress/recent-OOS validation." "Keep ATR spread guard disabled for failed variants."
Add-Probe $rows "TIME_EXIT_PROBE" "outputs\TIME_EXIT_PROBE_DECISION.csv" @("PASS_TIME_EXIT_PROBE") @("FAIL_") "Run/import time-exit probe reports." "Expand passing time-exit profile into stress/recent-OOS validation." "Keep time exit disabled for failed variants."
Add-Probe $rows "MTF_TREND_PROBE" "outputs\MTF_TREND_PROBE_DECISION.csv" @("PASS_MTF_TREND_PROBE") @("FAIL_") "Run/import MTF trend probe reports." "Expand passing MTF profile into stress/recent-OOS validation." "Keep MTF trend filter disabled for failed variants."
Add-Probe $rows "STRUCTURE_TRAIL_PROBE" "outputs\STRUCTURE_TRAILING_PROBE_DECISION.csv" @("PASS_STRUCTURE_TRAILING_PROBE", "PASS_STRUCTURE_TRAIL_PROBE") @("FAIL_") "Run/import structure trailing probe reports." "Expand passing structure-trailing profile into stress/recent-OOS validation." "Keep structure trailing disabled for failed variants."
Add-Probe $rows "SESSION_PROBE" "outputs\SESSION_VARIANT_DECISION.csv" @("PASS_SESSION_VARIANT", "PASS_SESSION_PROBE") @("FAIL_") "Run/import session variant reports." "Expand passing session profile into stress/recent-OOS validation." "Keep session filter disabled for failed variants."

$blockingStatuses = @("FAIL", "REPAIR_REPORTS", "WAITING_FOR_REPORTS", "REVIEW_DRAWDOWN", "REVIEW_REQUIRED")
$blocking = @($rows | Where-Object { $blockingStatuses -contains $_.Status })
$passing = @($rows | Where-Object { $_.Status -in @("PASS", "PARTIAL_PASS") })
$overall = if($blocking.Count -eq 0 -and $passing.Count -gt 0) { "FAST_GATES_READY_FOR_EXPANSION" } elseif($passing.Count -gt 0) { "PARTIAL_FAST_EVIDENCE" } else { "WAITING_FOR_FAST_REPORTS" }

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Fast Probe Readiness Snapshot") | Out-Null
$report.Add("") | Out-Null
$report.Add("Offline snapshot only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("- Overall: **$overall**") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Gate | Status | Rows | Decision Counts | Next Action |") | Out-Null
$report.Add("|---|---|---:|---|---|") | Out-Null
foreach($row in $rows) {
   $counts = ([string]$row.DecisionCounts) -replace '\|', '/'
   $next = ([string]$row.NextAction) -replace '\|', '/'
   $report.Add("| $($row.Gate) | $($row.Status) | $($row.Rows) | $counts | $next |") | Out-Null
}
$report.Add("") | Out-Null
$report.Add("## Bottom Line") | Out-Null
$report.Add("") | Out-Null
if($overall -eq "FAST_GATES_READY_FOR_EXPANSION") { $report.Add("Fast gates have usable evidence for expansion decisions, but no fast probe alone can promote a live/default profile.") | Out-Null }
elseif($overall -eq "PARTIAL_FAST_EVIDENCE") { $report.Add("Some fast probes have usable evidence. Expand only passing candidates and keep missing/failed gates out of promotion decisions.") | Out-Null }
else { $report.Add("Fast probes are still waiting for exported reports. Keep the current promoted profile unchanged.") | Out-Null }
Set-Content -LiteralPath $OutMarkdown -Value $report -Encoding UTF8
$rows
