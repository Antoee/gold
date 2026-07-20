param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Equal {
   param([object]$Actual, [object]$Expected, [string]$Label)
   if([string]$Actual -ne [string]$Expected) {
      throw "$Label expected '$Expected' but got '$Actual'"
   }
}

function Write-CsvRows {
   param(
      [string]$Path,
      [object[]]$Rows
   )
   $parent = Split-Path -Parent $Path
   if($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
   $Rows | Export-Csv -LiteralPath $Path -NoTypeInformation
}

$resolvedRepo = (Resolve-Path -LiteralPath $RepoRoot).Path
$workRoot = Join-Path $resolvedRepo "work"
$resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
$tempRoot = Join-Path $workRoot ("preflight_smoke_tmp_{0}" -f $PID)

if(Test-Path -LiteralPath $tempRoot) {
   $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
   if(!$resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean unexpected path: $resolvedTemp"
   }
   Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
   $manifestPath = Join-Path $tempRoot "manifest.csv"
   $metricsPath = Join-Path $tempRoot "metrics.csv"
   $decisionPath = Join-Path $tempRoot "decision.csv"
   $readinessPath = Join-Path $tempRoot "readiness.csv"
   $guardrailPath = Join-Path $tempRoot "guardrail.csv"
   $handoffPath = Join-Path $tempRoot "handoff.csv"
   $microHandoffPath = Join-Path $tempRoot "micro_handoff.csv"
   $safetyPath = Join-Path $tempRoot "safety.csv"
   $compilePath = Join-Path $tempRoot "compile.csv"
   $externalPackagePath = Join-Path $tempRoot "external_package.csv"
   $externalMicroPath = Join-Path $tempRoot "external_micro.csv"
   $packageStatusPath = Join-Path $tempRoot "package_status.csv"
   $batchPath = Join-Path $tempRoot "batch.csv"
   $packetDir = Join-Path $tempRoot "promotion_packets"
   $outCsv = Join-Path $tempRoot "preflight.csv"
   $outMd = Join-Path $tempRoot "preflight.md"

   Write-CsvRows $manifestPath @(
      [pscustomobject]@{ Phase = "phase1_fast_triage"; Model = "2"; Profile = "baseline_dd4"; Set = "stress"; Window = "2024_Q1" },
      [pscustomobject]@{ Phase = "phase2_real_tick_validation"; Model = "4"; Profile = "baseline_dd4"; Set = "split"; Window = "full" }
   )
   Write-CsvRows $metricsPath @(
      [pscustomobject]@{ Status = "MISSING_REPORT"; Profile = "baseline_dd4"; Phase = "phase1_fast_triage"; NetProfit = "" }
   )
   Write-CsvRows $decisionPath @(
      [pscustomobject]@{ Decision = "RunMissingReports"; Profile = "baseline_dd4"; Phase = "phase1_fast_triage" }
   )
   Write-CsvRows $readinessPath @(
      [pscustomobject]@{ Area = "Replacement readiness"; Status = "NOT_READY"; Evidence = "synthetic not ready"; NextAction = "wait" }
   )
   Write-CsvRows $guardrailPath @(
      [pscustomobject]@{ Profile = "baseline_dd4"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = "90" }
   )
   Write-CsvRows $handoffPath @(
      [pscustomobject]@{ Check = "fixture"; Passed = "True"; Status = "" }
   )
   Write-CsvRows $microHandoffPath @(
      [pscustomobject]@{ Check = "fixture"; Passed = "True"; Status = "" }
   )
   Write-CsvRows $safetyPath @(
      [pscustomobject]@{ Check = "fixture"; Passed = "True"; Status = "" }
   )
   Write-CsvRows $compilePath @(
      [pscustomobject]@{
         Status = "PASS"
         Evidence = "0 compile errors, 0 warnings."
         SourceHashStatus = "MATCH"
      }
   )
   Write-CsvRows $externalPackagePath @(
      [pscustomobject]@{ Check = "fixture"; Passed = "True"; Status = "" }
   )
   Write-CsvRows $externalMicroPath @(
      [pscustomobject]@{ Decision = "WAITING_FOR_REPORTS"; Window = "2024_Q1" }
   )
   Write-CsvRows $packageStatusPath @(
      [pscustomobject]@{ Area = "Compile trust"; Status = "FRESH_PASS"; Evidence = "synthetic fresh compile"; RequiredAction = "none" }
   )
   Write-CsvRows $batchPath @(
      [pscustomobject]@{ Rank = "1"; Profile = "baseline_dd4" }
   )
   Write-CsvRows (Join-Path $packetDir "baseline_dd4_promotion_gates.csv") @(
      [pscustomobject]@{ Gate = "Optimization guardrail tracked"; Status = "PASS"; Evidence = "fixture"; Required = "fixture" },
      [pscustomobject]@{ Gate = "Equity drawdown guard active or baseline anchor"; Status = "PASS"; Evidence = "fixture"; Required = "fixture" }
   )

   & (Join-Path $resolvedRepo "work\build_report_import_preflight.ps1") `
      -ManifestPath $manifestPath `
      -MetricsPath $metricsPath `
      -DecisionMatrixPath $decisionPath `
      -ReadinessPath $readinessPath `
      -GuardrailPath $guardrailPath `
      -HandoffIntegrityPath $handoffPath `
      -MicroHandoffIntegrityPath $microHandoffPath `
      -SafetyAuditPath $safetyPath `
      -CompileStatusPath $compilePath `
      -ExternalPackageAuditPath $externalPackagePath `
      -ExternalMicroDecisionPath $externalMicroPath `
      -PackageStatusPath $packageStatusPath `
      -BatchPath $batchPath `
      -PromotionPacketDir $packetDir `
      -OutCsv $outCsv `
      -OutReport $outMd | Out-Null

   $rows = @(Import-Csv -LiteralPath $outCsv)
   Assert-Equal (($rows | Where-Object Area -eq "Parser smoke" | Select-Object -First 1).Status) "PASS" "Parser smoke status"
   Assert-Equal (($rows | Where-Object Area -eq "External micro decision smoke" | Select-Object -First 1).Status) "PASS" "External micro decision smoke status"
   Assert-Equal (($rows | Where-Object Area -eq "Manifest" | Select-Object -First 1).Status) "PASS" "Manifest status"
   Assert-Equal (($rows | Where-Object Area -eq "Imported metrics" | Select-Object -First 1).Status) "WAITING_FOR_REPORTS" "Imported metrics status"
   Assert-Equal (($rows | Where-Object Area -eq "Promotion packet" | Select-Object -First 1).Status) "TRACKED" "Promotion packet status"
   Assert-Equal (($rows | Where-Object Area -eq "Micro handoff" | Select-Object -First 1).Status) "PASS" "Micro handoff status"
   Assert-Equal (($rows | Where-Object Area -eq "External micro decision" | Select-Object -First 1).Status) "WAITING_FOR_REPORTS" "External micro decision status"

   $markdown = Get-Content -LiteralPath $outMd -Raw
   if($markdown -notmatch "The import pipeline is ready") {
      $blockingRows = @($rows | Where-Object { $_.Status -in @("FAIL", "STALE", "HAS_UNPARSED_REPORTS", "COMPILE_REQUIRED") })
      $blockingSummary = ($blockingRows | ForEach-Object { "$($_.Area)=$($_.Status)" }) -join "; "
      throw "Expected ready-but-waiting bottom line was not written. Blocking=$blockingSummary"
   }

   "REPORT_IMPORT_PREFLIGHT_SMOKE_PASS"
}
finally {
   if(Test-Path -LiteralPath $tempRoot) {
      $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
      if($resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
      }
   }
}
