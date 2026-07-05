param(
   [string]$DecisionMatrixPath = "outputs\RESULT_IMPORT_DECISION_MATRIX.csv",
   [string]$PromotionGatePath = "outputs\PROMOTION_GATE_STATUS.csv",
   [string]$GuardrailPath = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$HandoffIntegrityPath = "outputs\HANDOFF_CONFIG_INTEGRITY.csv",
   [string]$SafetyAuditPath = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$OutCsv = "outputs\PROFIT_READINESS_SNAPSHOT.csv",
   [string]$OutReport = "outputs\PROFIT_READINESS_SNAPSHOT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvSafe {
   param([string]$Path)
   if(Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }
   return @()
}

function Add-Row {
   param([System.Collections.Generic.List[object]]$Rows, [string]$Area, [string]$Status, [string]$Evidence, [string]$NextAction)
   $Rows.Add([pscustomobject]@{ Area = $Area; Status = $Status; Evidence = $Evidence; NextAction = $NextAction }) | Out-Null
}

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

$decisionRows = Read-CsvSafe $DecisionMatrixPath
$promotionRows = Read-CsvSafe $PromotionGatePath
$guardrailRows = Read-CsvSafe $GuardrailPath
$handoffRows = Read-CsvSafe $HandoffIntegrityPath
$safetyRows = Read-CsvSafe $SafetyAuditPath
$rows = New-Object System.Collections.Generic.List[object]

$readyDecisions = @($decisionRows | Where-Object { $_.Decision -in @("AdvanceToPhase2", "BuildPromotionPacket") })
$missingDecisions = @($decisionRows | Where-Object { $_.Decision -eq "RunMissingReports" })
$rejectDecisions = @($decisionRows | Where-Object { $_.Decision -in @("Reject", "RejectForLossRisk") })

Add-Row $rows "Promoted profile" "KEEP_CURRENT" "Current promoted profile remains risk1p6_sl18_tp35: full-period +866.59, split aggregate +2354.65, monthly/quarter aggregate +744.03, zero losing validation windows in existing evidence." "Do not replace until a candidate passes phase-2 real ticks plus the full promotion gate."

if($decisionRows.Count -eq 0) {
   Add-Row $rows "Profit search evidence" "MISSING_MATRIX" "No result-import decision matrix was found at $DecisionMatrixPath." "Run work\build_result_import_decision_matrix.ps1 after collecting profit-search reports."
} elseif($readyDecisions.Count -gt 0) {
   Add-Row $rows "Profit search evidence" "READY_FOR_REVIEW" "$($readyDecisions.Count) profile/phase rows are ready for phase-2 advancement or promotion-packet review." "Follow RESULT_IMPORT_DECISION_MATRIX.md before changing the promoted default."
} else {
   Add-Row $rows "Profit search evidence" "WAITING_FOR_REPORTS" "$($missingDecisions.Count) of $($decisionRows.Count) profile/phase rows require missing MT5 reports; $($rejectDecisions.Count) rows are rejected." "Import/export the missing reports, then rerun collector, ranking, decision matrix, and promotion packet scripts."
}

$passingPromotion = @($promotionRows | Where-Object { (Get-Value $_ "Decision") -eq "PASS" -or (Get-Value $_ "Status") -eq "PASS" -or (Get-Value $_ "PromotionStatus") -eq "PASS" -or (Get-Value $_ "Profile") -eq "promoted_risk160_sl18_tp35" })
if($promotionRows.Count -gt 0) {
   Add-Row $rows "Promotion gate" "TRACKED" "Promotion gate rows available: $($promotionRows.Count). Current passing/default-related rows: $($passingPromotion.Count)." "Only promote a new candidate if its gate status passes all full, split, quarter, and month evidence checks."
} else {
   Add-Row $rows "Promotion gate" "MISSING_REPORT" "No promotion gate CSV found at $PromotionGatePath." "Run work\analyze_promotion_gate.ps1."
}

if($guardrailRows.Count -gt 0) {
   $rejectedGuardrails = @($guardrailRows | Where-Object { (Get-Value $_ "GuardrailStatus") -eq "REJECT_PROMOTION" })
   $reviewGuardrails = @($guardrailRows | Where-Object { (Get-Value $_ "GuardrailStatus") -eq "REVIEW_REQUIRED" })
   $topGuardrail = $guardrailRows | Sort-Object @{ Expression = { [int](Get-Value $_ "GuardrailScore" 0) }; Descending = $true }, Profile | Select-Object -First 1
   $topEvidence = if($topGuardrail) { "Top guardrail score: $(Get-Value $topGuardrail "Profile")=$(Get-Value $topGuardrail "GuardrailScore")." } else { "No top guardrail row." }
   Add-Row $rows "Optimization guardrails" "TRACKED" "$($guardrailRows.Count) profiles audited; $($reviewGuardrails.Count) require promotion review; $($rejectedGuardrails.Count) are rejected for promotion. $topEvidence" "Use guardrail status before spending tester time or building promotion packets."
} else {
   Add-Row $rows "Optimization guardrails" "MISSING_REPORT" "No guardrail audit CSV found at $GuardrailPath." "Run work\build_optimization_guardrail_audit.ps1."
}

$handoffFailures = @($handoffRows | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" -or (Get-Value $_ "Failed" 0) -gt 0 })
if($handoffRows.Count -gt 0 -and $handoffFailures.Count -eq 0) {
   Add-Row $rows "Handoff integrity" "PASS" "$($handoffRows.Count) handoff rows checked with no detected failures." "Use the handoff pack only during a controlled non-interrupting tester window."
} elseif($handoffRows.Count -gt 0) {
   Add-Row $rows "Handoff integrity" "FAIL" "$($handoffFailures.Count) handoff rows appear failed." "Fix handoff config integrity before running any tester config."
} else {
   Add-Row $rows "Handoff integrity" "MISSING_REPORT" "No handoff integrity CSV found at $HandoffIntegrityPath." "Run work\audit_handoff_config_integrity.ps1."
}

$safetyFailures = @($safetyRows | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($safetyRows.Count -gt 0 -and $safetyFailures.Count -eq 0) {
   Add-Row $rows "Local PC safety" "PASS" "$($safetyRows.Count) safety checks pass; local launch remains locked unless both MT5 unlock flags and both unlock files are set." "Keep MT5 local launch disabled while the PC is in normal use."
} elseif($safetyRows.Count -gt 0) {
   Add-Row $rows "Local PC safety" "FAIL" "$($safetyFailures.Count) safety checks appear failed." "Fix safety audit failures before any MT5-related work."
} else {
   Add-Row $rows "Local PC safety" "MISSING_REPORT" "No local safety CSV found at $SafetyAuditPath." "Run work\audit_mt5_local_safety.ps1."
}

$replacementReady = $readyDecisions.Count -gt 0 -and $safetyFailures.Count -eq 0
Add-Row $rows "Replacement readiness" $(if($replacementReady) { "REVIEW_REQUIRED" } else { "NOT_READY" }) $(if($replacementReady) { "At least one result row is ready for deeper review, but promotion still requires packet and human review." } else { "No candidate has enough imported evidence to replace the current promoted profile." }) $(if($replacementReady) { "Build promotion packets for ready candidates." } else { "Gather reports for the prioritized phase-1 batch without changing the live promoted settings." })

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Profit Readiness Snapshot") | Out-Null
$report.Add("") | Out-Null
$report.Add("Offline snapshot only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Area | Status | Evidence | Next Action |") | Out-Null
$report.Add("|---|---|---|---|") | Out-Null
foreach($row in $rows) { $report.Add("| $($row.Area) | $($row.Status) | $($row.Evidence) | $($row.NextAction) |") | Out-Null }
$report.Add("") | Out-Null
$report.Add("## Bottom Line") | Out-Null
$report.Add("") | Out-Null
if($replacementReady) { $report.Add("A candidate may be ready for deeper review, but no automatic promotion should happen until the promotion packet and full gate pass.") | Out-Null } else { $report.Add("Keep the current promoted profile. The next profit improvement is blocked by missing exported reports, not by EA code changes.") | Out-Null }
Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8
$rows
