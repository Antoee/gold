param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Step {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Name,
      [scriptblock]$Script
   )

   $started = Get-Date
   try {
      & $Script | Out-Null
      $status = "PASS"
      $errorText = ""
   } catch {
      $status = "FAIL"
      $errorText = $_.Exception.Message
   }

   $ended = Get-Date
   $Rows.Add([pscustomobject]@{
      Step = $Name
      Status = $status
      Seconds = [Math]::Round(($ended - $started).TotalSeconds, 2)
      Error = $errorText
   }) | Out-Null

   if($status -ne "PASS") {
      throw "$Name failed: $errorText"
   }
}

function Require-File {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) {
      throw "Required file was not created: $Path"
   }
}

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$outCsv = Join-Path $repo "outputs\OFFLINE_VALIDATION_REFRESH.csv"
$outReport = Join-Path $repo "outputs\OFFLINE_VALIDATION_REFRESH.md"
$rows = New-Object System.Collections.Generic.List[object]

function Invoke-QuietPowerShell {
   param(
      [Parameter(Mandatory=$true)]
      [string[]]$Arguments
   )

   $logRoot = Join-Path $repo "outputs\offline_refresh_logs"
   New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

   $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
   $safeName = (($Arguments -join "_") -replace '[^A-Za-z0-9_.-]', '_')
   if($safeName.Length -gt 80) { $safeName = $safeName.Substring(0, 80) }
   $stdoutPath = Join-Path $logRoot "$stamp`_$safeName.out.log"
   $stderrPath = Join-Path $logRoot "$stamp`_$safeName.err.log"

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
   $stdoutText | Set-Content -LiteralPath $stdoutPath -Encoding ASCII
   $stderrText | Set-Content -LiteralPath $stderrPath -Encoding ASCII

   if($process.ExitCode -ne 0) {
      $errorText = ""
      if(Test-Path -LiteralPath $stderrPath) {
         $errorText = (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue)
      }
      if([string]::IsNullOrWhiteSpace($errorText) -and (Test-Path -LiteralPath $stdoutPath)) {
         $errorText = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue)
      }
      if($errorText.Length -gt 1200) { $errorText = $errorText.Substring(0, 1200) }
      throw "Hidden PowerShell step failed with exit code $($process.ExitCode). Log: $stderrPath. $errorText"
   }
}

Push-Location $repo
try {
   Invoke-Step $rows "Generate profit-search configs" {
      Invoke-QuietPowerShell @("-File", ".\work\generate_profit_search_configs.ps1")
      Require-File "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv"
      Require-File "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv"
   }

   Invoke-Step $rows "Collect profit-search report metrics" {
      Invoke-QuietPowerShell @(
         "-File", ".\work\collect_validation_results.ps1",
         "-ManifestPath", "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv",
         "-ReportDir", "outputs",
         "-ReportNameTemplate", "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}",
         "-OutResults", "outputs\PROFIT_SEARCH_REPORT_METRICS.csv",
         "-OutSummary", "outputs\PROFIT_SEARCH_REPORT_SUMMARY.csv",
         "-OutMarkdown", "outputs\PROFIT_SEARCH_REPORT_METRICS.md"
      )
      Require-File "outputs\PROFIT_SEARCH_REPORT_METRICS.csv"
      Require-File "outputs\PROFIT_SEARCH_REPORT_SUMMARY.csv"
   }

   Invoke-Step $rows "Analyze profit-search ranking" {
      Invoke-QuietPowerShell @("-File", ".\work\analyze_profit_search.ps1")
      Require-File "outputs\PROFIT_SEARCH_RANKING.csv"
   }

   Invoke-Step $rows "Test profit-search robust ranking" {
      Invoke-QuietPowerShell @("-File", ".\work\test_profit_search_robust_ranking.ps1")
   }

   Invoke-Step $rows "Build optimization guardrail audit" {
      Invoke-QuietPowerShell @("-File", ".\work\build_optimization_guardrail_audit.ps1")
      Require-File "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv"
   }

   Invoke-Step $rows "Build result import decision matrix" {
      Invoke-QuietPowerShell @("-File", ".\work\build_result_import_decision_matrix.ps1")
      Require-File "outputs\RESULT_IMPORT_DECISION_MATRIX.csv"
   }

   Invoke-Step $rows "Build next profit-search batch" {
      Invoke-QuietPowerShell @("-File", ".\work\build_next_profit_search_batch.ps1")
      Require-File "outputs\NEXT_PROFIT_SEARCH_BATCH.csv"
   }

   Invoke-Step $rows "Build risk-adjusted micro batch" {
      Invoke-QuietPowerShell @("-File", ".\work\build_risk_adjusted_micro_batch.ps1")
      Require-File "outputs\RISK_ADJUSTED_MICRO_BATCH.csv"
   }

   Invoke-Step $rows "Build risk-adjusted micro handoff" {
      Invoke-QuietPowerShell @(
         "-File", ".\work\build_next_test_handoff.ps1",
         "-BatchCsv", "outputs\RISK_ADJUSTED_MICRO_BATCH.csv",
         "-OutDir", "outputs\risk_adjusted_micro_handoff",
         "-ZipPath", "outputs\risk_adjusted_micro_handoff.zip"
      )
      Require-File "outputs\risk_adjusted_micro_handoff\HANDOFF_MANIFEST.csv"
      Require-File "outputs\risk_adjusted_micro_handoff.zip"
   }

   Invoke-Step $rows "Build max-stop probe handoff" {
      Invoke-QuietPowerShell @("-File", ".\work\build_max_stop_probe_batch.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\test_max_stop_probe_batch.ps1")
      Invoke-QuietPowerShell @(
         "-File", ".\work\build_next_test_handoff.ps1",
         "-BatchCsv", "outputs\MAX_STOP_PROBE_BATCH.csv",
         "-OutDir", "outputs\max_stop_probe_handoff",
         "-ZipPath", "outputs\max_stop_probe_handoff.zip"
      )
      Invoke-QuietPowerShell @(
         "-File", ".\work\audit_handoff_config_integrity.ps1",
         "-ManifestPath", "outputs\max_stop_probe_handoff\HANDOFF_MANIFEST.csv",
         "-OutCsv", "outputs\MAX_STOP_PROBE_HANDOFF_INTEGRITY.csv",
         "-OutMarkdown", "outputs\MAX_STOP_PROBE_HANDOFF_INTEGRITY.md",
         "-ZipPath", "outputs\max_stop_probe_handoff.zip"
      )
      Require-File "outputs\MAX_STOP_PROBE_BATCH.csv"
      Require-File "outputs\max_stop_probe_handoff\HANDOFF_MANIFEST.csv"
      Require-File "outputs\max_stop_probe_handoff.zip"
      Require-File "outputs\MAX_STOP_PROBE_HANDOFF_INTEGRITY.csv"
   }

   Invoke-Step $rows "Test daily trade limit guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_daily_trade_limit_guard.ps1")
   }

   Invoke-Step $rows "Test daily loss-count guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_daily_loss_count_guard.ps1")
   }

   Invoke-Step $rows "Test weekly loss-count guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_weekly_loss_count_guard.ps1")
   }

   Invoke-Step $rows "Test monthly loss-count guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_monthly_loss_count_guard.ps1")
   }

   Invoke-Step $rows "Test loss-streak risk reduction" {
      Invoke-QuietPowerShell @("-File", ".\work\test_loss_streak_risk_reduction.ps1")
   }

   Invoke-Step $rows "Test drawdown risk reduction" {
      Invoke-QuietPowerShell @("-File", ".\work\test_drawdown_risk_reduction.ps1")
   }

   Invoke-Step $rows "Test daily profit lock guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_daily_profit_lock_guard.ps1")
   }

   Invoke-Step $rows "Test price-action strategy modules" {
      Invoke-QuietPowerShell @("-File", ".\work\test_price_action_strategy_modules.ps1")
   }

   Invoke-Step $rows "Build price-action strategy batch" {
      Invoke-QuietPowerShell @("-File", ".\work\build_price_action_strategy_batch.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\test_price_action_strategy_batch.ps1")
      Invoke-QuietPowerShell @(
         "-File", ".\work\build_next_test_handoff.ps1",
         "-BatchCsv", "outputs\PRICE_ACTION_STRATEGY_BATCH.csv",
         "-OutDir", "outputs\price_action_strategy_handoff",
         "-ZipPath", "outputs\price_action_strategy_handoff.zip"
      )
      Invoke-QuietPowerShell @(
         "-File", ".\work\build_parallel_micro_lanes.ps1",
         "-BatchCsv", "outputs\PRICE_ACTION_STRATEGY_BATCH.csv",
         "-OutDir", "outputs\price_action_parallel_lanes",
         "-ZipPath", "outputs\price_action_parallel_lanes.zip"
      )
      Invoke-QuietPowerShell @("-File", ".\work\test_price_action_strategy_handoff.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\test_price_action_strategy_decision.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\import_price_action_strategy_reports.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\build_price_action_strategy_decision.ps1")
      Require-File "outputs\PRICE_ACTION_STRATEGY_BATCH.csv"
      Require-File "outputs\PRICE_ACTION_STRATEGY_REPORT_METRICS.csv"
      Require-File "outputs\PRICE_ACTION_STRATEGY_DECISION.csv"
      Require-File "outputs\price_action_strategy_handoff\HANDOFF_MANIFEST.csv"
      Require-File "outputs\price_action_strategy_handoff.zip"
      Require-File "outputs\price_action_parallel_lanes\LANE_MANIFEST.csv"
      Require-File "outputs\price_action_parallel_lanes.zip"
   }

   Invoke-Step $rows "Test spread ATR cost guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_spread_atr_cost_guard.ps1")
   }

   Invoke-Step $rows "Test trade spacing guard" {
      Invoke-QuietPowerShell @("-File", ".\work\test_trade_spacing_guard.ps1")
   }

   Invoke-Step $rows "Build parallel micro lanes" {
      Invoke-QuietPowerShell @("-File", ".\work\build_parallel_micro_lanes.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\test_parallel_micro_lanes.ps1")
      Require-File "outputs\parallel_micro_lanes\LANE_MANIFEST.csv"
      Require-File "outputs\parallel_micro_lanes\LANE_RUN_MANIFEST.csv"
      Require-File "outputs\parallel_micro_lanes.zip"
   }

   Invoke-Step $rows "Build parallel micro lane decision" {
      Invoke-QuietPowerShell @("-File", ".\work\test_parallel_micro_lane_decision.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\build_parallel_micro_lane_decision.ps1")
      Require-File "outputs\PARALLEL_MICRO_LANE_DECISION.csv"
      Require-File "outputs\PARALLEL_MICRO_LANE_DECISION.md"
   }

   Invoke-Step $rows "Sync EA source artifacts" {
      Invoke-QuietPowerShell @("-File", ".\work\sync_ea_source_artifacts.ps1")
      Require-File "outputs\EA_SOURCE_ARTIFACT_SYNC.csv"
      Require-File "Professional_XAUUSD_EA.mq5"
      Require-File "outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5"
   }

   Invoke-Step $rows "Build external MT5 validation package" {
      Invoke-QuietPowerShell @("-File", ".\work\build_external_mt5_validation_package.ps1")
      Require-File "outputs\external_mt5_validation_package\PACKAGE_STATUS.csv"
      Require-File "outputs\external_mt5_validation_package\COMPILE_RETURN_CHECKLIST.csv"
      Require-File "outputs\xauusd_micro_validation_package.zip"
   }

   Invoke-Step $rows "Audit external MT5 validation package" {
      Invoke-QuietPowerShell @("-File", ".\work\test_external_mt5_validation_package.ps1")
      Require-File "outputs\EXTERNAL_MT5_PACKAGE_AUDIT.csv"
   }

   Invoke-Step $rows "Import external MT5 package reports" {
      Invoke-QuietPowerShell @("-File", ".\work\import_external_mt5_validation_package_reports.ps1")
      Require-File "outputs\EXTERNAL_MT5_PACKAGE_REPORT_METRICS.csv"
   }

   Invoke-Step $rows "Audit external report return completeness" {
      Invoke-QuietPowerShell @("-File", ".\work\audit_external_report_return_completeness.ps1")
      Require-File "outputs\EXTERNAL_MT5_REPORT_RETURN_AUDIT.csv"
   }

   Invoke-Step $rows "Build external MT5 micro decision" {
      Invoke-QuietPowerShell @("-File", ".\work\build_external_mt5_micro_decision.ps1")
      Require-File "outputs\EXTERNAL_MT5_MICRO_DECISION.csv"
      Require-File "outputs\EXTERNAL_MT5_MICRO_DECISION.md"
   }

   Invoke-Step $rows "Audit risk-adjusted micro handoff" {
      Invoke-QuietPowerShell @(
         "-File", ".\work\audit_handoff_config_integrity.ps1",
         "-ManifestPath", "outputs\risk_adjusted_micro_handoff\HANDOFF_MANIFEST.csv",
         "-OutCsv", "outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv",
         "-OutMarkdown", "outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.md",
         "-ZipPath", "outputs\risk_adjusted_micro_handoff.zip"
      )
      Require-File "outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv"
   }

   Invoke-Step $rows "Build top-profile promotion packet" {
      $batch = @(Import-Csv -LiteralPath "outputs\NEXT_PROFIT_SEARCH_BATCH.csv")
      if($batch.Count -eq 0) { throw "NEXT_PROFIT_SEARCH_BATCH.csv has no rows." }
      $topProfile = ($batch | Sort-Object @{ Expression = { [int]$_.Rank }; Descending = $false } | Select-Object -First 1).Profile
      Invoke-QuietPowerShell @("-File", ".\work\build_profit_promotion_packet.ps1", "-Profile", $topProfile)
      $safeProfile = ([string]$topProfile) -replace '[^A-Za-z0-9_.-]', '_'
      Require-File ("outputs\promotion_packets\{0}_promotion_gates.csv" -f $safeProfile)
   }

   Invoke-Step $rows "Audit legacy evidence input pins" {
      Invoke-QuietPowerShell @("-File", ".\work\audit_legacy_evidence_input_pins.ps1")
      Require-File "outputs\LEGACY_EVIDENCE_INPUT_PIN_AUDIT.csv"
   }

   Invoke-Step $rows "Build fully pinned research retest package" {
      Invoke-QuietPowerShell @("-File", ".\work\test_fully_pinned_research_retest_package.ps1")
      Require-File "outputs\fully_pinned_research_retest\RESEARCH_RETEST_MANIFEST.csv"
      Require-File "outputs\fully_pinned_research_retest.zip"
   }

   Invoke-Step $rows "Collect research retest report metrics" {
      Invoke-QuietPowerShell @(
         "-File", ".\work\collect_validation_results.ps1",
         "-ManifestPath", "outputs\fully_pinned_research_retest\RESEARCH_RETEST_MANIFEST.csv",
         "-ReportDir", "outputs",
         "-ReportNameTemplate", "research_retest_{Profile}_{Window}",
         "-OutResults", "outputs\RESEARCH_RETEST_REPORT_METRICS.csv",
         "-OutSummary", "outputs\RESEARCH_RETEST_REPORT_SUMMARY.csv",
         "-OutMarkdown", "outputs\RESEARCH_RETEST_REPORT_METRICS.md"
      )
      Require-File "outputs\RESEARCH_RETEST_REPORT_METRICS.csv"
      Require-File "outputs\RESEARCH_RETEST_REPORT_SUMMARY.csv"
   }

   Invoke-Step $rows "Build research retest decision" {
      Invoke-QuietPowerShell @("-File", ".\work\build_research_retest_decision.ps1")
      Require-File "outputs\RESEARCH_RETEST_DECISION.csv"
      Require-File "outputs\RESEARCH_RETEST_DECISION.md"
   }

   Invoke-Step $rows "Build profit readiness snapshot" {
      Invoke-QuietPowerShell @("-File", ".\work\build_profit_readiness_snapshot.ps1")
      Require-File "outputs\PROFIT_READINESS_SNAPSHOT.csv"
   }

   Invoke-Step $rows "Audit local MT5 safety" {
      Invoke-QuietPowerShell @("-File", ".\work\audit_mt5_local_safety.ps1")
      Require-File "outputs\MT5_LOCAL_SAFETY_AUDIT.csv"
   }

   Invoke-Step $rows "Audit MT5 autostart sources" {
      Invoke-QuietPowerShell @("-File", ".\work\test_mt5_autostart_source_audit.ps1")
      Invoke-QuietPowerShell @("-File", ".\work\audit_mt5_autostart_sources.ps1")
      Require-File "outputs\MT5_AUTOSTART_SOURCE_AUDIT.csv"
   }

   Invoke-Step $rows "Build local pipeline manifest" {
      Invoke-QuietPowerShell @("-File", ".\work\build_local_pipeline_manifest.ps1")
      Require-File "outputs\LOCAL_PIPELINE_MANIFEST.csv"
   }

   Invoke-Step $rows "Build report import preflight" {
      Invoke-QuietPowerShell @("-File", ".\work\build_report_import_preflight.ps1")
      Require-File "outputs\REPORT_IMPORT_PREFLIGHT.csv"
   }
}
finally {
   Pop-Location
}

$rows | Export-Csv -LiteralPath $outCsv -NoTypeInformation

$failed = @($rows | Where-Object { $_.Status -ne "PASS" })
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Offline Validation Refresh") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline refresh only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$(if($failed.Count -eq 0) { "PASS" } else { "FAIL" })**") | Out-Null
$md.Add("- Steps: $($rows.Count)") | Out-Null
$md.Add("- Failed: $($failed.Count)") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Step | Status | Seconds | Error |") | Out-Null
$md.Add("|---|---|---:|---|") | Out-Null
foreach($row in $rows) {
   $errorText = ([string]$row.Error) -replace '\|', '/'
   $md.Add("| $($row.Step) | $($row.Status) | $($row.Seconds) | $errorText |") | Out-Null
}
Set-Content -LiteralPath $outReport -Value $md -Encoding UTF8

[pscustomobject]@{
   Overall = if($failed.Count -eq 0) { "PASS" } else { "FAIL" }
   Steps = $rows.Count
   Failed = $failed.Count
   OutCsv = $outCsv
   OutReport = $outReport
}
