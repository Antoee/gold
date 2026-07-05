param(
   [string]$ReportDir = "outputs",
   [switch]$SkipStressSmoke,
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

function Add-Step { param([System.Collections.Generic.List[object]]$Rows, [string]$Step, [string]$Status, [string]$Evidence, [string]$NextAction) $Rows.Add([pscustomobject]@{ Step = $Step; Status = $Status; Evidence = $Evidence; NextAction = $NextAction }) | Out-Null }
function Invoke-Step { param([System.Collections.Generic.List[object]]$Rows, [string]$Step, [scriptblock]$Body, [string]$PassAction = "Continue.", [string]$FailAction = "Fix the failed step and rerun this wrapper.") try { $output = & $Body 2>&1; $evidence = ($output | Out-String).Trim(); if([string]::IsNullOrWhiteSpace($evidence)) { $evidence = "Completed without console output." }; Add-Step $Rows $Step "PASS" $evidence $PassAction } catch { Add-Step $Rows $Step "FAIL" $_.Exception.Message $FailAction } }
function Test-File { param([string]$Path) return Test-Path -LiteralPath $Path -PathType Leaf }

$rows = New-Object System.Collections.Generic.List[object]
Add-Step $rows "Start" "INFO" "Offline report import wrapper. No MT5 process is launched by this script." "Process available exported reports only."

if(-not $SkipStressSmoke) {
   $manifest = "outputs\stress_smoke_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import stress smoke reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "stress_smoke_phase1_{Profile}_{Window}" -OutResults "outputs\STRESS_SMOKE_REPORT_METRICS.csv" -OutSummary "outputs\STRESS_SMOKE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\STRESS_SMOKE_REPORT_METRICS.md" } "Run stress smoke decision next." "Check smoke report file names and parser coverage."
      if(Test-File "work\build_micro_test_decision.ps1") { Invoke-Step $rows "Build stress smoke decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_micro_test_decision.ps1" -MetricsPath "outputs\STRESS_SMOKE_REPORT_METRICS.csv" -ManifestPath $manifest -OutCsv "outputs\STRESS_SMOKE_DECISION.csv" -OutReport "outputs\STRESS_SMOKE_DECISION.md" } "Review outputs\STRESS_SMOKE_DECISION.md." "Fix smoke decision script inputs or report metrics." }
   } else { Add-Step $rows "Import stress smoke reports" "SKIP" "Manifest not found: $manifest" "Create the stress smoke handoff before importing smoke reports." }
}

if(-not $SkipMicro) {
   $manifest = "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv"
   if(Test-File $manifest) {
      Invoke-Step $rows "Import stress micro reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" -OutResults "outputs\MICRO_TEST_REPORT_METRICS.csv" -OutSummary "outputs\MICRO_TEST_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MICRO_TEST_REPORT_METRICS.md" } "Run micro decision next." "Check report file names and parser coverage."
      if(Test-File "work\build_micro_test_decision.ps1") { Invoke-Step $rows "Build stress micro decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_micro_test_decision.ps1" } "Review outputs\MICRO_TEST_DECISION.md." "Fix decision script inputs or report metrics." }
   } else { Add-Step $rows "Import stress micro reports" "SKIP" "Manifest not found: $manifest" "Create the micro handoff before importing micro reports." }
}

$probeBlocks = @(
   @{ Skip=$SkipRecentOos; Manifest="outputs\recent_oos_handoff\HANDOFF_MANIFEST.csv"; Step="recent-OOS"; Template="recent_oos_{Profile}_{Window}"; Out="RECENT_OOS"; Decision="work\build_recent_oos_decision.ps1" },
   @{ Skip=$SkipConfirmationProbe; Manifest="outputs\confirmation_probe_handoff\HANDOFF_MANIFEST.csv"; Step="confirmation probe"; Template="confirmation_probe_{Profile}_{Window}"; Out="CONFIRMATION_PROBE"; Decision="work\build_confirmation_probe_decision.ps1" },
   @{ Skip=$SkipBreakEvenProbe; Manifest="outputs\breakeven_probe_handoff\HANDOFF_MANIFEST.csv"; Step="break-even probe"; Template="breakeven_probe_{Profile}_{Window}"; Out="BREAKEVEN_PROBE"; Decision="work\build_breakeven_probe_decision.ps1" },
   @{ Skip=$SkipADXFilterProbe; Manifest="outputs\adx_filter_probe_handoff\HANDOFF_MANIFEST.csv"; Step="ADX filter probe"; Template="adx_probe_{Profile}_{Window}"; Out="ADX_FILTER_PROBE"; Decision="work\build_adx_filter_probe_decision.ps1" },
   @{ Skip=$SkipSpreadGuardProbe; Manifest="outputs\spread_guard_probe_handoff\HANDOFF_MANIFEST.csv"; Step="ATR spread guard probe"; Template="spread_probe_{Profile}_{Window}"; Out="SPREAD_GUARD_PROBE"; Decision="work\build_spread_guard_probe_decision.ps1" },
   @{ Skip=$SkipTimeExitProbe; Manifest="outputs\time_exit_probe_handoff\HANDOFF_MANIFEST.csv"; Step="time-exit probe"; Template="time_exit_probe_{Profile}_{Window}"; Out="TIME_EXIT_PROBE"; Decision="work\build_time_exit_probe_decision.ps1" },
   @{ Skip=$SkipMTFTrendProbe; Manifest="outputs\mtf_trend_probe_handoff\HANDOFF_MANIFEST.csv"; Step="MTF trend probe"; Template="mtf_probe_{Profile}_{Window}"; Out="MTF_TREND_PROBE"; Decision="work\build_mtf_trend_probe_decision.ps1" },
   @{ Skip=$SkipStructureTrailingProbe; Manifest="outputs\structure_trailing_probe_handoff\HANDOFF_MANIFEST.csv"; Step="structure trailing probe"; Template="structure_probe_{Profile}_{Window}"; Out="STRUCTURE_TRAILING_PROBE"; Decision="work\build_structure_trailing_probe_decision.ps1" },
   @{ Skip=$SkipSessionVariant; Manifest="outputs\session_variant_handoff\HANDOFF_MANIFEST.csv"; Step="session-variant"; Template="session_variant_{Profile}_{Window}"; Out="SESSION_VARIANT"; Decision="work\build_session_variant_decision.ps1" }
)
foreach($block in $probeBlocks) {
   if(-not $block.Skip) {
      $manifest = $block.Manifest
      if(Test-File $manifest) {
         Invoke-Step $rows "Import $($block.Step) reports" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" -ManifestPath $manifest -ReportDir $ReportDir -ReportNameTemplate $block.Template -OutResults "outputs\$($block.Out)_REPORT_METRICS.csv" -OutSummary "outputs\$($block.Out)_REPORT_SUMMARY.csv" -OutMarkdown "outputs\$($block.Out)_REPORT_METRICS.md" } "Run $($block.Step) decision next." "Check report file names and parser coverage."
         if(Test-File $block.Decision) { Invoke-Step $rows "Build $($block.Step) decision" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\$($block.Decision)" } "Review outputs\$($block.Out)_DECISION.md." "Fix decision script inputs or report metrics." }
      } else { Add-Step $rows "Import $($block.Step) reports" "SKIP" "Manifest not found: $manifest" "Create the handoff before importing $($block.Step) reports." }
   }
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
   if(Test-File "work\build_next_fast_batch_selector.ps1") { Invoke-Step $rows "Refresh next fast batch selection" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_next_fast_batch_selector.ps1" } "Review outputs\NEXT_FAST_BATCH_SELECTION.md." "Fix next-batch selector inputs." }
   if(Test-File "work\build_profit_readiness_snapshot.ps1") { Invoke-Step $rows "Refresh profit readiness snapshot" { powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_profit_readiness_snapshot.ps1" } "Review outputs\PROFIT_READINESS_SNAPSHOT.md." "Fix readiness script inputs." }
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
