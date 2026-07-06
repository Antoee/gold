param(
   [string]$ManifestPath = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
   [string]$MetricsPath = "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
   [string]$DecisionMatrixPath = "outputs\RESULT_IMPORT_DECISION_MATRIX.csv",
   [string]$ReadinessPath = "outputs\PROFIT_READINESS_SNAPSHOT.csv",
   [string]$GuardrailPath = "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv",
   [string]$HandoffIntegrityPath = "outputs\HANDOFF_CONFIG_INTEGRITY.csv",
   [string]$MicroHandoffIntegrityPath = "outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv",
   [string]$SafetyAuditPath = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$CompileStatusPath = "outputs\MT5_COMPILE_STATUS.csv",
   [string]$ExternalPackageAuditPath = "outputs\EXTERNAL_MT5_PACKAGE_AUDIT.csv",
   [string]$ExternalMicroDecisionPath = "outputs\EXTERNAL_MT5_MICRO_DECISION.csv",
   [string]$PackageStatusPath = "outputs\external_mt5_validation_package\PACKAGE_STATUS.csv",
   [string]$BatchPath = "outputs\NEXT_PROFIT_SEARCH_BATCH.csv",
   [string]$PromotionPacketDir = "outputs\promotion_packets",
   [string]$OutCsv = "outputs\REPORT_IMPORT_PREFLIGHT.csv",
   [string]$OutReport = "outputs\REPORT_IMPORT_PREFLIGHT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-CsvSafe {
   param([string]$Path)
   $rows = @()
   if(Test-Path -LiteralPath $Path) {
      $rows = @(Import-Csv -LiteralPath $Path)
   }
   return ,$rows
}

function Add-Row {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Area,
      [string]$Status,
      [string]$Evidence,
      [string]$NextAction
   )

   $Rows.Add([pscustomobject]@{
      Area = $Area
      Status = $Status
      Evidence = $Evidence
      NextAction = $NextAction
   }) | Out-Null
}

function Get-Value {
   param(
      [object]$Row,
      [string]$Name,
      [object]$Default = ""
   )

   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Invoke-NoWindowPowerShell {
   param(
      [Parameter(Mandatory=$true)]
      [string[]]$Arguments
   )

   $allArguments = @("-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass") + $Arguments
   $quotedArguments = @($allArguments | ForEach-Object {
      '"' + (([string]$_) -replace '"', '\"') + '"'
   })

   $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
   $startInfo.FileName = "powershell.exe"
   $startInfo.Arguments = ($quotedArguments -join " ")
   $startInfo.UseShellExecute = $false
   $startInfo.CreateNoWindow = $true
   $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
   $startInfo.RedirectStandardOutput = $true
   $startInfo.RedirectStandardError = $true

   $process = [System.Diagnostics.Process]::new()
   $process.StartInfo = $startInfo
   [void]$process.Start()
   $stdoutText = $process.StandardOutput.ReadToEnd()
   $stderrText = $process.StandardError.ReadToEnd()
   $process.WaitForExit()

   [pscustomobject]@{
      ExitCode = $process.ExitCode
      Output = ($stdoutText + $stderrText).Trim()
   }
}

$rows = New-Object System.Collections.Generic.List[object]

$manifest = Read-CsvSafe $ManifestPath
$metrics = Read-CsvSafe $MetricsPath
$decisions = Read-CsvSafe $DecisionMatrixPath
$readiness = Read-CsvSafe $ReadinessPath
$guardrail = Read-CsvSafe $GuardrailPath
$compileStatus = Read-CsvSafe $CompileStatusPath
$externalPackageAudit = Read-CsvSafe $ExternalPackageAuditPath
$externalMicroDecision = Read-CsvSafe $ExternalMicroDecisionPath
$handoff = Read-CsvSafe $HandoffIntegrityPath
$microHandoff = Read-CsvSafe $MicroHandoffIntegrityPath
$safety = Read-CsvSafe $SafetyAuditPath
$batch = Read-CsvSafe $BatchPath

$parserStatus = "FAIL"
$parserEvidence = ""
try {
   $parserOutput = Invoke-NoWindowPowerShell @("-File", "work\test_report_collector_parser.ps1")
   if($parserOutput.ExitCode -eq 0 -and $parserOutput.Output -match "REPORT_COLLECTOR_PARSER_SMOKE_PASS") {
      $parserStatus = "PASS"
      $parserEvidence = "REPORT_COLLECTOR_PARSER_SMOKE_PASS"
   } else {
      $parserEvidence = $parserOutput.Output
   }
} catch {
   $parserEvidence = $_.Exception.Message
}

Add-Row $rows "Parser smoke" $parserStatus $parserEvidence `
   $(if($parserStatus -eq "PASS") { "Parser can be trusted for import preflight." } else { "Fix parser smoke failure before importing reports." })

$externalDecisionSmokeStatus = "FAIL"
$externalDecisionSmokeEvidence = ""
try {
   $externalDecisionSmokeOutput = Invoke-NoWindowPowerShell @("-File", "work\test_external_mt5_micro_decision.ps1")
   if($externalDecisionSmokeOutput.ExitCode -eq 0 -and $externalDecisionSmokeOutput.Output -match "EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS") {
      $externalDecisionSmokeStatus = "PASS"
      $externalDecisionSmokeEvidence = "EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS"
   } else {
      $externalDecisionSmokeEvidence = $externalDecisionSmokeOutput.Output
   }
} catch {
   $externalDecisionSmokeEvidence = $_.Exception.Message
}

Add-Row $rows "External micro decision smoke" $externalDecisionSmokeStatus $externalDecisionSmokeEvidence `
   $(if($externalDecisionSmokeStatus -eq "PASS") { "External micro decision pass/reject/repair/wait logic is covered." } else { "Fix external micro decision smoke failure before trusting returned package reports." })

$recentBatchSmokeStatus = "FAIL"
$recentBatchSmokeEvidence = ""
try {
   $recentBatchSmokeOutput = Invoke-NoWindowPowerShell @("-File", "work\test_next_profit_search_batch_recent_priority.ps1")
   if($recentBatchSmokeOutput.ExitCode -eq 0 -and $recentBatchSmokeOutput.Output -match "NEXT_PROFIT_SEARCH_BATCH_RECENT_PRIORITY_SMOKE_PASS") {
      $recentBatchSmokeStatus = "PASS"
      $recentBatchSmokeEvidence = "NEXT_PROFIT_SEARCH_BATCH_RECENT_PRIORITY_SMOKE_PASS"
   } else {
      $recentBatchSmokeEvidence = $recentBatchSmokeOutput.Output
   }
} catch {
   $recentBatchSmokeEvidence = $_.Exception.Message
}

Add-Row $rows "Recent batch priority smoke" $recentBatchSmokeStatus $recentBatchSmokeEvidence `
   $(if($recentBatchSmokeStatus -eq "PASS") { "2026-aware fast-test prioritization is covered." } else { "Fix recent-data batch priority before relying on the next-run queue." })

$riskSizingSmokeStatus = "FAIL"
$riskSizingSmokeEvidence = ""
try {
   $riskSizingSmokeOutput = Invoke-NoWindowPowerShell @("-File", "work\test_risk_lot_sizing_guard.ps1")
   if($riskSizingSmokeOutput.ExitCode -eq 0 -and $riskSizingSmokeOutput.Output -match "RISK_LOT_SIZING_GUARD_SMOKE_PASS") {
      $riskSizingSmokeStatus = "PASS"
      $riskSizingSmokeEvidence = "RISK_LOT_SIZING_GUARD_SMOKE_PASS"
   } else {
      $riskSizingSmokeEvidence = $riskSizingSmokeOutput.Output
   }
} catch {
   $riskSizingSmokeEvidence = $_.Exception.Message
}

Add-Row $rows "Risk lot-sizing guard smoke" $riskSizingSmokeStatus $riskSizingSmokeEvidence `
   $(if($riskSizingSmokeStatus -eq "PASS") { "EA rejects entries when broker minimum lot would exceed configured risk." } else { "Fix lot-sizing guard before trusting risk-controlled tests." })

$sourceHashSmokeStatus = "FAIL"
$sourceHashSmokeEvidence = ""
try {
   $sourceHashSmokeOutput = Invoke-NoWindowPowerShell @("-File", "work\test_source_hash_status.ps1")
   if($sourceHashSmokeOutput.ExitCode -eq 0 -and $sourceHashSmokeOutput.Output -match "SOURCE_HASH_STATUS_SMOKE_PASS") {
      $sourceHashSmokeStatus = "PASS"
      $sourceHashSmokeEvidence = "SOURCE_HASH_STATUS_SMOKE_PASS"
   } else {
      $sourceHashSmokeEvidence = $sourceHashSmokeOutput.Output
   }
} catch {
   $sourceHashSmokeEvidence = $_.Exception.Message
}

Add-Row $rows "Source hash status smoke" $sourceHashSmokeStatus $sourceHashSmokeEvidence `
   $(if($sourceHashSmokeStatus -eq "PASS") { "Package source hash matches the current EA source." } else { "Rebuild external package status before trusting returned compile/report evidence." })

if($manifest.Count -gt 0) {
   $phase1 = @($manifest | Where-Object { (Get-Value $_ "Phase") -eq "phase1_fast_triage" }).Count
   $phase2 = @($manifest | Where-Object { (Get-Value $_ "Phase") -eq "phase2_real_tick_validation" }).Count
   Add-Row $rows "Manifest" "PASS" "$($manifest.Count) expected profit-search configs: $phase1 phase-1, $phase2 phase-2." `
      "Use the manifest as the source of truth for expected report names."
} else {
   Add-Row $rows "Manifest" "FAIL" "Manifest missing or empty: $ManifestPath" `
      "Regenerate profit-search configs before importing reports."
}

if($metrics.Count -gt 0) {
   $parsed = @($metrics | Where-Object { (Get-Value $_ "Status") -eq "PARSED" }).Count
   $missing = @($metrics | Where-Object { (Get-Value $_ "Status") -eq "MISSING_REPORT" }).Count
   $unparsed = @($metrics | Where-Object { (Get-Value $_ "Status") -eq "UNPARSED" }).Count
   $status = if($parsed -gt 0 -and $unparsed -eq 0) { "HAS_PARSED_REPORTS" } elseif($unparsed -gt 0) { "HAS_UNPARSED_REPORTS" } else { "WAITING_FOR_REPORTS" }
   Add-Row $rows "Imported metrics" $status "$parsed parsed, $missing missing, $unparsed unparsed across $($metrics.Count) expected rows." `
      $(if($parsed -gt 0) { "Rerun ranking, decision matrix, readiness snapshot, and promotion packets as needed." } else { "Export/import reports before expecting promotion decisions." })
} else {
   Add-Row $rows "Imported metrics" "FAIL" "Metrics missing or empty: $MetricsPath" `
      "Run work\collect_validation_results.ps1 for the profit-search manifest."
}

if($decisions.Count -gt 0) {
   $decisionCounts = ($decisions | Group-Object Decision | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
   $ready = @($decisions | Where-Object { (Get-Value $_ "Decision") -in @("AdvanceToPhase2", "BuildPromotionPacket") }).Count
   Add-Row $rows "Decision matrix" $(if($ready -gt 0) { "READY_ACTIONS" } else { "NO_READY_ACTIONS" }) $decisionCounts `
      $(if($ready -gt 0) { "Follow decision matrix actions before changing promoted settings." } else { "Continue collecting reports; no candidate action is ready." })
} else {
   Add-Row $rows "Decision matrix" "FAIL" "Decision matrix missing or empty: $DecisionMatrixPath" `
      "Run work\build_result_import_decision_matrix.ps1."
}

if($readiness.Count -gt 0) {
   $replacement = $readiness | Where-Object { (Get-Value $_ "Area") -eq "Replacement readiness" } | Select-Object -First 1
   $status = if($replacement) { Get-Value $replacement "Status" } else { "UNKNOWN" }
   $evidence = if($replacement) { Get-Value $replacement "Evidence" } else { "Replacement readiness row missing." }
   Add-Row $rows "Profit readiness" $status $evidence `
      $(if($status -eq "NOT_READY") { "Keep current promoted profile." } else { "Build promotion packet and review all gates." })
} else {
   Add-Row $rows "Profit readiness" "FAIL" "Readiness snapshot missing or empty: $ReadinessPath" `
      "Run work\build_profit_readiness_snapshot.ps1."
}

if($guardrail.Count -gt 0) {
   $statusCounts = ($guardrail | Group-Object GuardrailStatus | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
   $top = $guardrail | Sort-Object @{ Expression = { [int]$_.GuardrailScore }; Descending = $true }, Profile | Select-Object -First 1
   $topEvidence = if($top) { "Top score: $($top.Profile)=$($top.GuardrailScore). $statusCounts" } else { $statusCounts }
   Add-Row $rows "Optimization guardrails" "TRACKED" $topEvidence `
      "Use guardrail status to prioritize tester time and block promotion shortcuts."
} else {
   Add-Row $rows "Optimization guardrails" "FAIL" "Guardrail audit missing or empty: $GuardrailPath" `
      "Run work\build_optimization_guardrail_audit.ps1."
}

if($batch.Count -gt 0) {
   $topBatch = $batch | Sort-Object @{ Expression = { [int]$_.Rank }; Descending = $false } | Select-Object -First 1
   $topProfile = [string]$topBatch.Profile
   $safeTopProfile = $topProfile -replace '[^A-Za-z0-9_.-]', '_'
   $packetPath = Join-Path $PromotionPacketDir ("{0}_promotion_gates.csv" -f $safeTopProfile)
   $packetRows = Read-CsvSafe $packetPath
   $guardrailGate = $packetRows | Where-Object { (Get-Value $_ "Gate") -eq "Optimization guardrail tracked" } | Select-Object -First 1
   $equityGate = $packetRows | Where-Object { (Get-Value $_ "Gate") -eq "Equity drawdown guard active or baseline anchor" } | Select-Object -First 1
   $packetOk = $packetRows.Count -gt 0 -and $null -ne $guardrailGate -and $null -ne $equityGate
   Add-Row $rows "Promotion packet" $(if($packetOk) { "TRACKED" } else { "FAIL" }) `
      $(if($packetOk) { "Top queued profile $topProfile has promotion gates with guardrail/equity checks." } else { "Missing or stale promotion gates for top queued profile $topProfile." }) `
      $(if($packetOk) { "Refresh packet after importing reports." } else { "Run work\build_profit_promotion_packet.ps1 -Profile $topProfile." })
} else {
   Add-Row $rows "Promotion packet" "FAIL" "Batch missing or empty: $BatchPath" `
      "Run work\build_next_profit_search_batch.ps1."
}

$handoffFailures = @($handoff | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($handoff.Count -gt 0 -and $handoffFailures.Count -eq 0) {
   Add-Row $rows "Handoff integrity" "PASS" "$($handoff.Count) rows checked, 0 failures." `
      "Handoff configs remain statically safe for a controlled tester window."
} elseif($handoff.Count -gt 0) {
   Add-Row $rows "Handoff integrity" "FAIL" "$($handoffFailures.Count) failed rows." `
      "Fix handoff integrity before running tests."
} else {
   Add-Row $rows "Handoff integrity" "FAIL" "Handoff integrity report missing or empty: $HandoffIntegrityPath" `
      "Run work\audit_handoff_config_integrity.ps1."
}

$microFailures = @($microHandoff | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($microHandoff.Count -gt 0 -and $microFailures.Count -eq 0) {
   Add-Row $rows "Micro handoff" "PASS" "$($microHandoff.Count) rows checked, 0 failures." `
      "Use the micro handoff first when tester time is limited."
} elseif($microHandoff.Count -gt 0) {
   Add-Row $rows "Micro handoff" "FAIL" "$($microFailures.Count) failed rows." `
      "Fix micro handoff integrity before running quick tests."
} else {
   Add-Row $rows "Micro handoff" "FAIL" "Micro handoff integrity report missing or empty: $MicroHandoffIntegrityPath" `
      "Run work\build_next_test_handoff.ps1 with outputs\RISK_ADJUSTED_MICRO_BATCH.csv, then audit it with work\audit_handoff_config_integrity.ps1."
}

$safetyFailures = @($safety | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($safety.Count -gt 0 -and $safetyFailures.Count -eq 0) {
   Add-Row $rows "Local safety" "PASS" "$($safety.Count) safety checks pass." `
      "Keep local MT5 launch locked while the PC is in normal use."
} elseif($safety.Count -gt 0) {
   Add-Row $rows "Local safety" "FAIL" "$($safetyFailures.Count) safety failures." `
      "Fix safety audit failures before any MT5-related work."
} else {
   Add-Row $rows "Local safety" "FAIL" "Safety audit missing or empty: $SafetyAuditPath" `
      "Run work\audit_mt5_local_safety.ps1."
}

$compileStatus = @($compileStatus)
$compileRow = $compileStatus | Select-Object -First 1
$compileIsStale = $false
$compileStaleEvidence = ""
if($compileStatus.Count -gt 0) {
   $sourceFile = [string](Get-Value $compileRow "SourceFile")
   if([string]::IsNullOrWhiteSpace($sourceFile)) {
      $sourceFile = "outputs\Professional_XAUUSD_EA.mq5"
   }
   $expectedSourceHash = [string](Get-Value $compileRow "ExpectedSourceHash")
   $sourceHashStatus = [string](Get-Value $compileRow "SourceHashStatus")
   if(![string]::IsNullOrWhiteSpace($expectedSourceHash) -and (Test-Path -LiteralPath "outputs\Professional_XAUUSD_EA.mq5")) {
      $currentSourceHash = (Get-FileHash -LiteralPath "outputs\Professional_XAUUSD_EA.mq5" -Algorithm SHA256).Hash
      if($expectedSourceHash -ne $currentSourceHash) {
         $compileIsStale = $true
         $compileStaleEvidence = "EA source hash changed after compile status. CurrentHash=$currentSourceHash; CompileExpectedHash=$expectedSourceHash"
      }
   }
   if($sourceHashStatus -eq "MISMATCH") {
      $compileIsStale = $true
      $compileStaleEvidence = "Compile log source hash does not match expected EA source hash."
   }
   if((Test-Path -LiteralPath $sourceFile) -and (Test-Path -LiteralPath $CompileStatusPath)) {
      $sourceTime = (Get-Item -LiteralPath $sourceFile).LastWriteTimeUtc
      $compileStatusTime = (Get-Item -LiteralPath $CompileStatusPath).LastWriteTimeUtc
      if(!$compileIsStale -and $sourceTime -gt $compileStatusTime) {
         $compileIsStale = $true
         $compileStaleEvidence = "EA source changed after compile status. SourceUtc=$sourceTime; CompileStatusUtc=$compileStatusTime"
      }
   }
}
if($compileStatus.Count -gt 0 -and $compileIsStale) {
   Add-Row $rows "Compile status" "STALE" $compileStaleEvidence `
      "Import a fresh MetaEditor compile log before trusting this EA build for tester reports."
} elseif($compileStatus.Count -gt 0 -and (Get-Value $compileRow "Status") -eq "PASS") {
   Add-Row $rows "Compile status" "PASS" "$(Get-Value $compileRow "Evidence")" `
      "Compile proof is clean for this imported log; rerun after every EA source change."
} elseif($compileStatus.Count -gt 0) {
   Add-Row $rows "Compile status" "$(Get-Value $compileRow "Status")" "$(Get-Value $compileRow "Evidence")" `
      "Resolve compile status before importing new tester reports."
} else {
   Add-Row $rows "Compile status" "FAIL" "Compile status missing or empty: $CompileStatusPath" `
      "Run work\import_mt5_compile_log.ps1 against the latest exported MetaEditor log."
}

$externalPackageFailures = @($externalPackageAudit | Where-Object { (Get-Value $_ "Passed") -eq "False" -or (Get-Value $_ "Status") -eq "FAIL" })
if($externalPackageAudit.Count -gt 0 -and $externalPackageFailures.Count -eq 0) {
   Add-Row $rows "External MT5 package" "PASS" "$($externalPackageAudit.Count) package checks pass." `
      "Use the external package on a non-interrupting MT5 setup."
} elseif($externalPackageAudit.Count -gt 0) {
   Add-Row $rows "External MT5 package" "FAIL" "$($externalPackageFailures.Count) package checks failed." `
      "Rebuild and audit the external MT5 package before running it."
} else {
   Add-Row $rows "External MT5 package" "FAIL" "External package audit missing or empty: $ExternalPackageAuditPath" `
      "Run work\build_external_mt5_validation_package.ps1 and work\test_external_mt5_validation_package.ps1."
}

if($externalMicroDecision.Count -gt 0) {
   $decisionCounts = ($externalMicroDecision | Group-Object Decision | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "; "
   $compileTrustStatus = "MISSING"
   if(Test-Path -LiteralPath $PackageStatusPath) {
      $packageStatusRows = @(Import-Csv -LiteralPath $PackageStatusPath)
      $compileTrustRow = $packageStatusRows | Where-Object { (Get-Value $_ "Area") -eq "Compile trust" } | Select-Object -First 1
      if($compileTrustRow) { $compileTrustStatus = [string](Get-Value $compileTrustRow "Status" "MISSING") }
   }
   $hasFail = @($externalMicroDecision | Where-Object { (Get-Value $_ "Decision") -like "FAIL_*" }).Count -gt 0
   $hasRepair = @($externalMicroDecision | Where-Object { (Get-Value $_ "Decision") -eq "REPAIR_REPORT" }).Count -gt 0
   $hasWaiting = @($externalMicroDecision | Where-Object { (Get-Value $_ "Decision") -eq "WAITING_FOR_REPORTS" }).Count -gt 0
   $hasReview = @($externalMicroDecision | Where-Object { (Get-Value $_ "Decision") -eq "REVIEW_DRAWDOWN" }).Count -gt 0
   $allPass = $externalMicroDecision.Count -gt 0 -and @($externalMicroDecision | Where-Object { (Get-Value $_ "Decision") -in @("PASS_WINDOW", "PASS_RISK_ADJUSTED") }).Count -eq $externalMicroDecision.Count
   $status = if($hasFail) { "REJECT_CANDIDATE" } elseif($hasRepair) { "REPAIR_REPORTS" } elseif($compileTrustStatus -ne "FRESH_PASS") { "COMPILE_REQUIRED" } elseif($hasWaiting) { "WAITING_FOR_REPORTS" } elseif($hasReview) { "REVIEW_DRAWDOWN" } elseif($allPass) { "PASS_MICRO" } else { "REVIEW_REQUIRED" }
   $next = if($status -eq "PASS_MICRO") { "Proceed to full handoff and phase-2 real ticks; do not promote from micro evidence alone." } elseif($status -eq "REJECT_CANDIDATE") { "Keep current promoted profile and deprioritize the candidate." } elseif($status -eq "REPAIR_REPORTS") { "Repair or re-export external package reports." } elseif($status -eq "COMPILE_REQUIRED") { "Compile the exact packaged source and import the compile log before trusting micro decisions." } else { "Complete external package report import before spending full-handoff tester time." }
   Add-Row $rows "External micro decision" $status "$decisionCounts; CompileTrust=$compileTrustStatus" $next
} else {
   Add-Row $rows "External micro decision" "WAITING_FOR_REPORTS" "No external micro decision rows found at $ExternalMicroDecisionPath" `
      "Run work\import_external_mt5_validation_package_reports.ps1 and work\build_external_mt5_micro_decision.ps1 after reports return."
}

$blocking = @($rows | Where-Object { $_.Status -in @("FAIL", "STALE", "HAS_UNPARSED_REPORTS", "COMPILE_REQUIRED") })
$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Report Import Preflight") | Out-Null
$report.Add("") | Out-Null
$report.Add("Offline preflight only. No MT5 process was launched.") | Out-Null
$report.Add("") | Out-Null
$report.Add("| Area | Status | Evidence | Next Action |") | Out-Null
$report.Add("|---|---|---|---|") | Out-Null
foreach($row in $rows) {
   $report.Add("| $($row.Area) | $($row.Status) | $($row.Evidence) | $($row.NextAction) |") | Out-Null
}

$report.Add("") | Out-Null
$report.Add("## Bottom Line") | Out-Null
$report.Add("") | Out-Null
if($blocking.Count -gt 0) {
   $report.Add("Preflight has blocking issues. Do not promote or advance candidates until these are resolved.") | Out-Null
} elseif(@($metrics | Where-Object { (Get-Value $_ "Status") -eq "PARSED" }).Count -eq 0) {
   $report.Add("The import pipeline is ready, but no profit-search reports have been parsed yet. Keep the current promoted profile.") | Out-Null
} else {
   $report.Add("Parsed reports are present. Continue with ranking, decision matrix, readiness snapshot, and promotion packet gates.") | Out-Null
}

Set-Content -LiteralPath $OutReport -Value $report -Encoding UTF8

$rows
