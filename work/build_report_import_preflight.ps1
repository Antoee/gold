param(
   [string]$ManifestPath = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
   [string]$MetricsPath = "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
   [string]$DecisionMatrixPath = "outputs\RESULT_IMPORT_DECISION_MATRIX.csv",
   [string]$ReadinessPath = "outputs\PROFIT_READINESS_SNAPSHOT.csv",
   [string]$GuardrailPath = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$HandoffIntegrityPath = "outputs\HANDOFF_CONFIG_INTEGRITY.csv",
   [string]$SafetyAuditPath = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$OutCsv = "outputs\REPORT_IMPORT_PREFLIGHT.csv",
   [string]$OutReport = "outputs\REPORT_IMPORT_PREFLIGHT.md"
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

$rows = New-Object System.Collections.Generic.List[object]
$manifest = Read-CsvSafe $ManifestPath
$metrics = Read-CsvSafe $MetricsPath
$decisions = Read-CsvSafe $DecisionMatrixPath
$readiness = Read-CsvSafe $ReadinessPath
$guardrail = Read-CsvSafe $GuardrailPath
$handoff = Read-CsvSafe $HandoffIntegrityPath
$safety = Read-CsvSafe $SafetyAuditPath

$parserStatus = "FAIL"
$parserEvidence = ""
try {
   $parserOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File "work\test_report_collector_parser.ps1" 2>&1
   if(($parserOutput | Out-String) -match "REPORT_COLLECTOR_PARSER_SMOKE_PASS") { $parserStatus = "PASS"; $parserEvidence = "REPORT_COLLECTOR_PARSER_SMOKE_PASS" } else { $parserEvidence = ($parserOutput | Out-String).Trim() }
} catch { $parserEvidence = $_.Exception.Message }
Add-Row $rows "Parser smoke" $parserStatus $parserEvidence $(if($parserStatus -eq "PASS") { "Parser can be trusted for import preflight." } else { "Fix parser smoke failure before importing reports." })

if($manifest.Count -gt 0) {
   $phase1 = @($manifest | Where-Object { (Get-Value $_ "Phase") -eq "phase1_fast_triage" }).Count
   $phase2 = @($manifest | Where-Object { (Get-Value $_ "Phase") -eq "phase2_real_tick_validation" }).Count
   Add-Row $rows "Manifest" "PASS" "$($manifest.Count) expected profit-search configs: $phase1 phase-1, $phase2 phase-2." "Use the manifest as the source of truth for expected report names."
} else { Add-Row $rows "Manifest" "FAIL" "Manifest missing or empty: $ManifestPath" "Regenerate profit-search configs before importing reports." }

if($metrics.Count -gt 0) {
   $parsed = @($metrics | Where-Object { (Get-Value $_ "Status") -eq "PARSED" }).Count
   $missing = @($metrics | Where-Object { (Get-Value $_ "Status") -eq "MISSING_REPORT" }).Count
   $unparsed = @($metrics | Where-Object { (Get-Value $_ "Status") -eq "UNPARSED" }).Count
   $status = if($parsed -gt 0 -and $unparsed -eq 0) { "HAS_PARSED_REPORTS" } elseif($unparsed -gt 0) { "HAS_UNPARSED_REPORTS" } else { "WAITING_FOR_REPORTS" }
   Add-Row $rows "Imported metrics" $status "$parsed parsed, $missing missing, $unparsed unparsed across $($metrics.Count) expected rows." $(if($parsed -gt 0) { "Rerun ranking, decision matrix, readiness snapshot, and promotion packets as needed." } else { "Export/import reports before expecting promotion decisions." })
} else { Add-Row $rows "Imported metrics" "FAIL" "Metrics missing or empty: $MetricsPath" "Run work\collect_validation_results.ps1 for the profit-search manifest." }

if($decisions.Count -gt 0) {
   $decisionCounts = ($decisions | Group-Object Decision | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
   $ready = @($decisions | Where-Object { (Get-Value $_ "Decision") -in @("AdvanceToPhase2", "BuildPromotionPacket") }).Count
   Add-Row $rows "Decision matrix" $(if($ready -gt 0) { "READY_ACTIONS" } else { "NO_READY_ACTIONS" }) $decisionCounts $(if($ready -gt 0) { "Follow decision matrix actions before changing promoted settings." } else { "Continue collecting reports; no candidate action is ready." })
} else { Add-Row $rows "Decision matrix" "FAIL" "Decision matrix missing or empty: $DecisionMatrixPath" "Run work\build_result_import_decision_matrix.ps1." }

if($readiness.Count -gt 0) {
   $replacement = $readiness | Where-Object { (Get-Value $_ "Area") -eq "Replacement readiness" } | Select-Object -First 1
   $status = if($replacement) { Get-Value $replacement "Status" } else { "UNKNOWN" }
   $evidence = if($replacement) { Get-Value $replacement "Evidence" } else { "Replacement readiness row missing." }
   Add-Row $rows "Profit readiness" $status $evidence $(if($status -eq "NOT_READY") { "Keep current promoted profile." } else { "Build promotion packet and review all gates." })
} else { Add-Row $rows "Profit readiness" "FAIL" "Readiness snapshot missing or empty: $ReadinessPath" "Run work\build_profit_readiness_snapshot.ps1." }

if($guardrail.Count -gt 0) {
   $statusCounts = ($guardrail | Group-Object GuardrailStatus | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
   $top = $guardrail | Sort-Object @{ Expression = { [int]$_.GuardrailScore }; Descending = $true }, Profile | Select-Object -First 1
   $topEvidence = if($top) { "Top score: $($top.Profile)=$($top.GuardrailScore). $statusCounts" } else { $statusCounts }
   Add-Row $rows "Optimization guardrails" "TRACKED" $topEvidence "Use guardrail status to prioritize tester time and block promotion shortcuts."
} else { Add-Row $rows "Optimization guardrails" "FAIL" "Guardrail audit missing or empty: $GuardrailPath" "Run work\build_optimization_guardrail_audit.ps1." }

$handoffFailures = @($handoff | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($handoff.Count -gt 0 -and $handoffFailures.Count -eq 0) { Add-Row $rows "Handoff integrity" "PASS" "$($handoff.Count) rows checked, 0 failures." "Handoff configs remain statically safe for a controlled tester window." }
elseif($handoff.Count -gt 0) { Add-Row $rows "Handoff integrity" "FAIL" "$($handoffFailures.Count) failed rows." "Fix handoff integrity before running tests." }
else { Add-Row $rows "Handoff integrity" "FAIL" "Handoff integrity report missing or empty: $HandoffIntegrityPath" "Run work\audit_handoff_config_integrity.ps1." }

$safetyFailures = @($safety | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($safety.Count -gt 0 -and $safetyFailures.Count -eq 0) { Add-Row $rows "Local safety" "PASS" "$($safety.Count) safety checks pass." "Keep local MT5 launch locked while the PC is in normal use." }
elseif($safety.Count -gt 0) { Add-Row $rows "Local safety" "FAIL" "$($safetyFailures.Count) safety failures." "Fix safety audit failures before any MT5-related work." }
else { Add-Row $rows "Local safety" "FAIL" "Safety audit missing or empty: $SafetyAuditPath" "Run work\audit_mt5_local_safety.ps1." }

$blocking = @($rows | Where-Object { $_.Status -in @("FAIL", "HAS_UNPARSED_REPORTS") })
$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Report Import Preflight") | Out-Null
$report.Add("") | Out-Null
$report.Add("Offline preflight only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Area | Status | Evidence | Next Action |") | Out-Null
$report.Add("|---|---|---|---|") | Out-Null
foreach($row in $rows) { $report.Add("| $($row.Area) | $($row.Status) | $($row.Evidence) | $($row.NextAction) |") | Out-Null }
$report.Add("") | Out-Null
$report.Add("## Bottom Line") | Out-Null
$report.Add("") | Out-Null
if($blocking.Count -gt 0) { $report.Add("Preflight has blocking issues. Do not promote or advance candidates until these are resolved.") | Out-Null }
elseif(@($metrics | Where-Object { (Get-Value $_ "Status") -eq "PARSED" }).Count -eq 0) { $report.Add("The import pipeline is ready, but no profit-search reports have been parsed yet. Keep the current promoted profile.") | Out-Null }
else { $report.Add("Parsed reports are present. Continue with ranking, decision matrix, readiness snapshot, and promotion packet gates.") | Out-Null }
Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8
$rows
