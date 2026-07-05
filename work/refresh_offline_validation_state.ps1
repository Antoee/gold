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

Push-Location $repo
try {
   Invoke-Step $rows "Generate profit-search configs" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\generate_profit_search_configs.ps1
      Require-File "work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv"
      Require-File "work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv"
   }

   Invoke-Step $rows "Collect profit-search report metrics" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 `
         -ManifestPath work\generated_profit_search\PROFIT_SEARCH_CONFIG_MANIFEST.csv `
         -ReportDir outputs `
         -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" `
         -OutResults outputs\PROFIT_SEARCH_REPORT_METRICS.csv `
         -OutSummary outputs\PROFIT_SEARCH_REPORT_SUMMARY.csv `
         -OutMarkdown outputs\PROFIT_SEARCH_REPORT_METRICS.md
      Require-File "outputs\PROFIT_SEARCH_REPORT_METRICS.csv"
      Require-File "outputs\PROFIT_SEARCH_REPORT_SUMMARY.csv"
   }

   Invoke-Step $rows "Analyze profit-search ranking" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\analyze_profit_search.ps1
      Require-File "outputs\PROFIT_SEARCH_RANKING.csv"
   }

   Invoke-Step $rows "Build optimization guardrail audit" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_optimization_guardrail_audit.ps1
      Require-File "outputs\OPTIMIZATION_GUARDRAIL_AUDIT.csv"
   }

   Invoke-Step $rows "Build result import decision matrix" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_result_import_decision_matrix.ps1
      Require-File "outputs\RESULT_IMPORT_DECISION_MATRIX.csv"
   }

   Invoke-Step $rows "Build next profit-search batch" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_next_profit_search_batch.ps1
      Require-File "outputs\NEXT_PROFIT_SEARCH_BATCH.csv"
   }

   Invoke-Step $rows "Build risk-adjusted micro batch" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_risk_adjusted_micro_batch.ps1
      Require-File "outputs\RISK_ADJUSTED_MICRO_BATCH.csv"
   }

   Invoke-Step $rows "Build risk-adjusted micro handoff" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_next_test_handoff.ps1 `
         -BatchCsv outputs\RISK_ADJUSTED_MICRO_BATCH.csv `
         -OutDir outputs\risk_adjusted_micro_handoff `
         -ZipPath outputs\risk_adjusted_micro_handoff.zip
      Require-File "outputs\risk_adjusted_micro_handoff\HANDOFF_MANIFEST.csv"
      Require-File "outputs\risk_adjusted_micro_handoff.zip"
   }

   Invoke-Step $rows "Audit risk-adjusted micro handoff" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\audit_handoff_config_integrity.ps1 `
         -ManifestPath outputs\risk_adjusted_micro_handoff\HANDOFF_MANIFEST.csv `
         -OutCsv outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv `
         -OutMarkdown outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.md `
         -ZipPath outputs\risk_adjusted_micro_handoff.zip
      Require-File "outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv"
   }

   Invoke-Step $rows "Build top-profile promotion packet" {
      $batch = @(Import-Csv -LiteralPath "outputs\NEXT_PROFIT_SEARCH_BATCH.csv")
      if($batch.Count -eq 0) { throw "NEXT_PROFIT_SEARCH_BATCH.csv has no rows." }
      $topProfile = ($batch | Sort-Object @{ Expression = { [int]$_.Rank }; Descending = $false } | Select-Object -First 1).Profile
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_profit_promotion_packet.ps1 -Profile $topProfile
      $safeProfile = ([string]$topProfile) -replace '[^A-Za-z0-9_.-]', '_'
      Require-File ("outputs\promotion_packets\{0}_promotion_gates.csv" -f $safeProfile)
   }

   Invoke-Step $rows "Build profit readiness snapshot" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_profit_readiness_snapshot.ps1
      Require-File "outputs\PROFIT_READINESS_SNAPSHOT.csv"
   }

   Invoke-Step $rows "Build report import preflight" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_report_import_preflight.ps1
      Require-File "outputs\REPORT_IMPORT_PREFLIGHT.csv"
   }

   Invoke-Step $rows "Audit local MT5 safety" {
      powershell -NoProfile -ExecutionPolicy Bypass -File .\work\audit_mt5_local_safety.ps1
      Require-File "outputs\MT5_LOCAL_SAFETY_AUDIT.csv"
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
