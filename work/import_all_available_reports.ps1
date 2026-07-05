param(
   [string]$ReportDir = "outputs",
   [switch]$SkipMicro,
   [switch]$SkipRecentOos,
   [switch]$SkipConfirmationProbe,
   [switch]$SkipBreakEvenProbe,
   [switch]$SkipADXFilterProbe,
   [switch]$SkipSpreadGuardProbe,
   [switch]$SkipTimeExitProbe,
   [switch]$SkipMTFTrendProbe,
   [switch]$SkipStructureTrailingProbe,
   [switch]$SkipSessionVariant,
   [switch]$SkipFullProfitSearch,
   [switch]$SkipReadinessRefresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Step {
   param([System.Collections.Generic.List[object]]$Rows, [string]$Step, [string]$Status, [string]$Evidence, [string]$NextAction)
   $Rows.Add([pscustomobject]@{ Step = $Step; Status = $Status; Evidence = $Evidence; NextAction = $NextAction }) | Out-Null
}

function Invoke-Step {
   param([System.Collections.Generic.List[object]]$Rows, [string]$Step, [scriptblock]$Body, [string]$PassAction = "Continue.", [string]$FailAction = "Fix the failed step and rerun this wrapper.")
   try {
      $output = & $Body 2>&1
      $evidence = ($output | Out-String).Trim()
      if([string]::IsNullOrWhiteSpace($evidence)) { $evidence = "Completed without console output." }
      Add-Step $Rows $Step "PASS" $evidence $PassAction
   } catch { Add-Step $Rows $Step "FAIL" $_.Exception.Message $FailAction }
}

function Test-File { param([string]$Path) return Test-Path -LiteralPath $Path -PathType Leaf }

$rows = New-Object System.Collections.Generic.List[object]
Add-Step $rows "Start" "INFO" "Offline report import wrapper. No MT5 process is launched by this script." "Process available exported reports only."

if(-not $SkipMicro) {
   $manifest = "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import stress micro reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" -OutResults "outputs\MICRO_TEST_REPORT_METRICS.csv" -OutSummary "outputs\MICRO_TEST_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MICRO_TEST_REPORT_METRICS.md" } "Run micro decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_micro_test_decision.ps1") { Invoke-Step $rows "Build stress micro decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_micro_test_decision.ps1" } "Review outputs\MICRO_TEST_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import stress micro reports" "SKIP" "Manifest not found: $manifest" "Create the micro handoff before importing micro reports." }
}

if(-not $SkipRecentOos) {
   $manifest = "outputs\recent_oos_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import recent-OOS reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "recent_oos_{Profile}_{Window}" -OutResults "outputs\RECENT_OOS_REPORT_METRICS.csv" -OutSummary "outputs\RECENT_OOS_REPORT_SUMMARY.csv" -OutMarkdown "outputs\RECENT_OOS_REPORT_METRICS.md" } "Run recent-OOS decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_recent_oos_decision.ps1") { Invoke-Step $rows "Build recent-OOS decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_recent_oos_decision.ps1" } "Review outputs\RECENT_OOS_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import recent-OOS reports" "SKIP" "Manifest not found: $manifest" "Create the recent-OOS handoff before importing recent reports." }
}

if(-not $SkipConfirmationProbe) {
   $manifest = "outputs\confirmation_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import confirmation probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "confirmation_probe_{Profile}_{Window}" -OutResults "outputs\CONFIRMATION_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\CONFIRMATION_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\CONFIRMATION_PROBE_REPORT_METRICS.md" } "Run confirmation decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_confirmation_probe_decision.ps1") { Invoke-Step $rows "Build confirmation probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_confirmation_probe_decision.ps1" } "Review outputs\CONFIRMATION_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import confirmation probe reports" "SKIP" "Manifest not found: $manifest" "Create the confirmation handoff before importing confirmation reports." }
}

if(-not $SkipBreakEvenProbe) {
   $manifest = "outputs\breakeven_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import break-even probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "breakeven_probe_{Profile}_{Window}" -OutResults "outputs\BREAKEVEN_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\BREAKEVEN_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\BREAKEVEN_PROBE_REPORT_METRICS.md" } "Run break-even decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_breakeven_probe_decision.ps1") { Invoke-Step $rows "Build break-even probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_breakeven_probe_decision.ps1" } "Review outputs\BREAKEVEN_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import break-even probe reports" "SKIP" "Manifest not found: $manifest" "Create the break-even handoff before importing break-even reports." }
}

if(-not $SkipADXFilterProbe) {
   $manifest = "outputs\adx_filter_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import ADX filter probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "adx_probe_{Profile}_{Window}" -OutResults "outputs\ADX_FILTER_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\ADX_FILTER_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\ADX_FILTER_PROBE_REPORT_METRICS.md" } "Run ADX filter decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_adx_filter_probe_decision.ps1") { Invoke-Step $rows "Build ADX filter probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_adx_filter_probe_decision.ps1" } "Review outputs\ADX_FILTER_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import ADX filter probe reports" "SKIP" "Manifest not found: $manifest" "Create the ADX filter handoff before importing ADX reports." }
}

if(-not $SkipSpreadGuardProbe) {
   $manifest = "outputs\spread_guard_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import ATR spread guard probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "spread_probe_{Profile}_{Window}" -OutResults "outputs\SPREAD_GUARD_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\SPREAD_GUARD_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\SPREAD_GUARD_PROBE_REPORT_METRICS.md" } "Run ATR spread guard decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_spread_guard_probe_decision.ps1") { Invoke-Step $rows "Build ATR spread guard probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_spread_guard_probe_decision.ps1" } "Review outputs\SPREAD_GUARD_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import ATR spread guard probe reports" "SKIP" "Manifest not found: $manifest" "Create the ATR spread guard handoff before importing spread guard reports." }
}

if(-not $SkipTimeExitProbe) {
   $manifest = "outputs\time_exit_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import time-exit probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "time_exit_probe_{Profile}_{Window}" -OutResults "outputs\TIME_EXIT_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\TIME_EXIT_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\TIME_EXIT_PROBE_REPORT_METRICS.md" } "Run time-exit decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_time_exit_probe_decision.ps1") { Invoke-Step $rows "Build time-exit probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_time_exit_probe_decision.ps1" } "Review outputs\TIME_EXIT_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import time-exit probe reports" "SKIP" "Manifest not found: $manifest" "Create the time-exit handoff before importing time-exit reports." }
}

if(-not $SkipMTFTrendProbe) {
   $manifest = "outputs\mtf_trend_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import MTF trend probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "mtf_probe_{Profile}_{Window}" -OutResults "outputs\MTF_TREND_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\MTF_TREND_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MTF_TREND_PROBE_REPORT_METRICS.md" } "Run MTF trend decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_mtf_trend_probe_decision.ps1") { Invoke-Step $rows "Build MTF trend probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_mtf_trend_probe_decision.ps1" } "Review outputs\MTF_TREND_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import MTF trend probe reports" "SKIP" "Manifest not found: $manifest" "Create the MTF trend handoff before importing MTF reports." }
}

if(-not $SkipStructureTrailingProbe) {
   $manifest = "outputs\structure_trailing_probe_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import structure trailing probe reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "structure_probe_{Profile}_{Window}" -OutResults "outputs\STRUCTURE_TRAILING_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\STRUCTURE_TRAILING_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\STRUCTURE_TRAILING_PROBE_REPORT_METRICS.md" } "Run structure trailing decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_structure_trailing_probe_decision.ps1") { Invoke-Step $rows "Build structure trailing probe decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_structure_trailing_probe_decision.ps1" } "Review outputs\STRUCTURE_TRAILING_PROBE_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import structure trailing probe reports" "SKIP" "Manifest not found: $manifest" "Create the structure trailing handoff before importing structure reports." }
}

if(-not $SkipSessionVariant) {
   $manifest = "outputs\session_variant_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import session-variant reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "session_variant_{Profile}_{Window}" -OutResults "outputs\SESSION_VARIANT_REPORT_METRICS.csv" -OutSummary "outputs\SESSION_VARIANT_REPORT_SUMMARY.csv" -OutMarkdown "outputs\SESSION_VARIANT_REPORT_METRICS.md" } "Run session decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_session_variant_decision.ps1") { Invoke-Step $rows "Build session-variant decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_session_variant_decision.ps1" } "Review outputs\SESSION_VARIANT_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import session-variant reports" "SKIP" "Manifest not found: $manifest" "Create the session handoff before importing session reports." }
}

if(-not $SkipFullProfitSearch) {
   $manifest = "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import full profit-search reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" -OutResults "outputs\PROFIT_SEARCH_REPORT_METRICS.csv" -OutSummary "outputs\PROFIT_SEARCH_REPORT_SUMMARY.csv" -OutMarkdown "outputs\PROFIT_SEARCH_REPORT_METRICS.md" } "Rebuild result-import decision matrix if reports parsed." "Check full profit-search report names and manifest."
      if(Test-File "work\build_result_import_decision_matrix.ps1") { Invoke-Step $rows "Build result-import decision matrix" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_result_import_decision_matrix.ps1" } "Review outputs\RESULT_IMPORT_DECISION_MATRIX.md." "Fix decision matrix inputs." }
   } else { Add-Step $rows "Import full profit-search reports" "SKIP" "Manifest not found: $manifest" "Generate or restore full profit-search manifest before importing full reports." }
}

if(-not $SkipReadinessRefresh) {
   if(Test-File "work\build_fast_probe_readiness_snapshot.ps1") { Invoke-Step $rows "Refresh fast-probe readiness snapshot" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_fast_probe_readiness_snapshot.ps1" } "Review outputs\FAST_PROBE_READINESS_SNAPSHOT.md." "Fix fast-probe readiness script inputs." }
   else { Add-Step $rows "Refresh fast-probe readiness snapshot" "SKIP" "work\build_fast_probe_readiness_snapshot.ps1 not found." "Restore fast-probe readiness builder if needed." }
   if(Test-File "work\build_profit_readiness_snapshot.ps1") { Invoke-Step $rows "Refresh profit readiness snapshot" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_profit_readiness_snapshot.ps1" } "Review outputs\PROFIT_READINESS_SNAPSHOT.md." "Fix readiness script inputs." }
   else { Add-Step $rows "Refresh profit readiness snapshot" "SKIP" "work\build_profit_readiness_snapshot.ps1 not found." "Restore readiness builder if needed." }
}

$outCsv = "outputs\REPORT_IMPORT_REBUILD_SUMMARY.csv"
$outMd = "outputs\REPORT_IMPORT_REBUILD_SUMMARY.md"
$rows | Export-Csv -LiteralPath $outCsv -NoTypeInformation
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Report Import Rebuild Summary") | Out-Null; $md.Add("") | Out-Null; $md.Add("Offline wrapper summary. No MT5 process was launched.") | Out-Null; $md.Add("") | Out-Null
$md.Add("| Step | Status | Evidence | Next Action |") | Out-Null; $md.Add("|---|---|---|---|") | Out-Null
foreach($row in $rows) { $evidence = ([string]$row.Evidence) -replace '\|', '/'; $evidence = $evidence -replace "`r?`n", "<br>"; $next = ([string]$row.NextAction) -replace '\|', '/'; $md.Add("| $($row.Step) | $($row.Status) | $evidence | $next |") | Out-Null }
$md.Add("") | Out-Null; $md.Add("## Bottom Line") | Out-Null; $md.Add("") | Out-Null
if(@($rows | Where-Object { $_.Status -eq "FAIL" }).Count -gt 0) { $md.Add("One or more import/rebuild steps failed. Fix those before making a candidate decision.") | Out-Null } else { $md.Add("Available reports were imported and available decision/readiness files were rebuilt. Review the generated decision reports before spending more tester time.") | Out-Null }
Set-Content -LiteralPath $outMd -Value $md -Encoding UTF8
$rows
if(@($rows | Where-Object { $_.Status -eq "FAIL" }).Count -gt 0) { exit 1 }
