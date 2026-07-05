param(
   [string]$MatrixPath = "outputs\FAST_EXPERIMENT_MATRIX.csv",
   [string]$ReadinessPath = "outputs\FAST_PROBE_READINESS_SNAPSHOT.csv",
   [string]$OutCsv = "outputs\NEXT_FAST_BATCH_SELECTION.csv",
   [string]$OutMarkdown = "outputs\NEXT_FAST_BATCH_SELECTION.md"
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

$manifestByGate = @{
   STRESS_MICRO = "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv"
   RECENT_OOS = "outputs\recent_oos_handoff\HANDOFF_MANIFEST.csv"
   CONFIRMATION_PROBE = "outputs\confirmation_probe_handoff\HANDOFF_MANIFEST.csv"
   BREAKEVEN_PROBE = "outputs\breakeven_probe_handoff\HANDOFF_MANIFEST.csv"
   ADX_FILTER_PROBE = "outputs\adx_filter_probe_handoff\HANDOFF_MANIFEST.csv"
   SPREAD_GUARD_PROBE = "outputs\spread_guard_probe_handoff\HANDOFF_MANIFEST.csv"
   TIME_EXIT_PROBE = "outputs\time_exit_probe_handoff\HANDOFF_MANIFEST.csv"
   MTF_TREND_PROBE = "outputs\mtf_trend_probe_handoff\HANDOFF_MANIFEST.csv"
   STRUCTURE_TRAIL_PROBE = "outputs\structure_trailing_probe_handoff\HANDOFF_MANIFEST.csv"
   SESSION_PROBE = "outputs\session_variant_handoff\HANDOFF_MANIFEST.csv"
   FULL_HANDOFF = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv"
}

$matrixRows = @(Read-CsvSafe $MatrixPath | Sort-Object { [int](Get-Value $_ "Priority" 999) })
$readinessRows = Read-CsvSafe $ReadinessPath
$readinessByGate = @{}
foreach($row in $readinessRows) { $readinessByGate[[string](Get-Value $row "Gate")] = $row }

$selection = $null
$reason = "No fast matrix rows were available."
$stopStatuses = @("FAIL", "REPAIR_REPORTS", "REVIEW_DRAWDOWN", "REVIEW_REQUIRED")
$waitingStatuses = @("WAITING_FOR_REPORTS")
$passStatuses = @("PASS", "PARTIAL_PASS")

foreach($matrix in $matrixRows) {
   $gate = [string](Get-Value $matrix "Experiment")
   if($gate -eq "FULL_HANDOFF") { continue }
   $ready = $readinessByGate[$gate]
   $status = [string](Get-Value $ready "Status" "WAITING_FOR_REPORTS")
   if($stopStatuses -contains $status) {
      $selection = [pscustomobject]@{
         Recommendation = "STOP_AND_REVIEW"
         Gate = $gate
         Priority = Get-Value $matrix "Priority" ""
         Rows = Get-Value $matrix "Rows" ""
         Manifest = $manifestByGate[$gate]
         Status = $status
         Reason = "Earlier gate is not clean. Review/fix this gate before running more tester batches."
         NextAction = Get-Value $ready "NextAction" "Review gate details."
      }
      break
   }
   if($waitingStatuses -contains $status) {
      $selection = [pscustomobject]@{
         Recommendation = "RUN_NEXT_FAST_BATCH"
         Gate = $gate
         Priority = Get-Value $matrix "Priority" ""
         Rows = Get-Value $matrix "Rows" ""
         Manifest = $manifestByGate[$gate]
         Status = $status
         Reason = "This is the first pending gate in priority order. Running it avoids spending time on lower-priority batches too early."
         NextAction = Get-Value $ready "NextAction" "Export this gate's MT5 reports in a non-interrupting environment, then rerun import_all_available_reports.ps1."
      }
      break
   }
}

if($null -eq $selection) {
   $selection = [pscustomobject]@{
      Recommendation = "FAST_GATES_COMPLETE_OR_PARTIAL"
      Gate = "FULL_HANDOFF"
      Priority = "11"
      Rows = "24"
      Manifest = $manifestByGate["FULL_HANDOFF"]
      Status = "READY_FOR_REVIEW"
      Reason = "No blocking or waiting fast gate was found. Review passing/partial fast evidence before any full handoff."
      NextAction = "Run full handoff only for candidates that passed their smaller gates; never promote from fast evidence alone."
   }
}

@($selection) | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Next Fast Batch Selection") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline selector only. No MT5 process was launched.") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Recommendation | Gate | Priority | Rows | Status | Manifest | Reason | Next Action |") | Out-Null
$md.Add("|---|---|---:|---:|---|---|---|---|") | Out-Null
$reasonText = ([string]$selection.Reason) -replace '\|', '/'
$nextText = ([string]$selection.NextAction) -replace '\|', '/'
$md.Add("| $($selection.Recommendation) | $($selection.Gate) | $($selection.Priority) | $($selection.Rows) | $($selection.Status) | `$($selection.Manifest)` | $reasonText | $nextText |") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Bottom Line") | Out-Null
$md.Add("") | Out-Null
if($selection.Recommendation -eq "RUN_NEXT_FAST_BATCH") { $md.Add("Run only this next batch in a non-interrupting MT5 environment, export the reports, then rerun `work/import_all_available_reports.ps1` before choosing another batch.") | Out-Null }
elseif($selection.Recommendation -eq "STOP_AND_REVIEW") { $md.Add("Do not spend more tester time until the blocking gate is fixed or rejected.") | Out-Null }
else { $md.Add("Fast-gate evidence is no longer simply waiting. Review passing candidates carefully before full validation.") | Out-Null }
Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8
$selection
