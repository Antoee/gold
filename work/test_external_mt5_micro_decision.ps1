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

function New-MetricRow {
   param(
      [string]$Profile,
      [string]$Window,
      [string]$Status,
      [string]$NetProfit,
      [string]$Drawdown
   )

   [pscustomobject]@{
      Priority = 1
      Phase = "phase1_fast_triage"
      Profile = $Profile
      Set = "stress"
      Window = $Window
      From = "2024.01.01"
      To = "2024.03.31"
      Status = $Status
      ReportPath = ""
      NetProfit = $NetProfit
      Balance = ""
      ProfitFactor = ""
      ExpectedPayoff = ""
      TotalTrades = ""
      MaxDrawdownMoney = $Drawdown
      MaxDrawdownPercent = ""
      BalanceDrawdownMaximal = ""
      EquityDrawdownMaximal = ""
      RecoveryFactor = ""
   }
}

function Invoke-DecisionCase {
   param(
      [string]$CaseName,
      [object[]]$Rows,
      [string]$ExpectedOverall,
      [hashtable]$ExpectedWindowDecisions
   )

   $caseDir = Join-Path $tempRoot $CaseName
   New-Item -ItemType Directory -Path $caseDir -Force | Out-Null
   $metricsPath = Join-Path $caseDir "metrics.csv"
   $outCsv = Join-Path $caseDir "decision.csv"
   $outMd = Join-Path $caseDir "decision.md"
   $Rows | Export-Csv -LiteralPath $metricsPath -NoTypeInformation

   $decisionScript = Join-Path $resolvedRepo "work\build_external_mt5_micro_decision.ps1"
   & powershell -NoProfile -ExecutionPolicy Bypass -File $decisionScript `
      -MetricsPath $metricsPath `
      -OutCsv $outCsv `
      -OutMarkdown $outMd | Out-Null

   $markdown = Get-Content -LiteralPath $outMd -Raw
   $overallMatch = [regex]::Match($markdown, 'Overall:\s+\*\*([^*]+)\*\*')
   if(!$overallMatch.Success) { throw "$CaseName overall status was not written to markdown." }
   $overall = $overallMatch.Groups[1].Value
   Assert-Equal $overall $ExpectedOverall "$CaseName overall"

   $decisions = @(Import-Csv -LiteralPath $outCsv)
   foreach($window in $ExpectedWindowDecisions.Keys) {
      $row = $decisions | Where-Object { $_.Window -eq $window } | Select-Object -First 1
      if($null -eq $row) { throw "$CaseName missing decision row for $window" }
      Assert-Equal $row.Decision $ExpectedWindowDecisions[$window] "$CaseName $window decision"
   }
}

$resolvedRepo = (Resolve-Path -LiteralPath $RepoRoot).Path
$workRoot = Join-Path $resolvedRepo "work"
$tempRoot = Join-Path $workRoot ("external_micro_decision_tmp_{0}" -f $PID)

if(Test-Path -LiteralPath $tempRoot) {
   $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
   $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
   if(!$resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to clean unexpected path: $resolvedTemp"
   }
   Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
   Invoke-DecisionCase -CaseName "pass_micro" -Rows @(
      New-MetricRow "tp38_sl18" "2024_Q1" "PARSED" "120" "30"
      New-MetricRow "baseline_promoted" "2024_Q1" "PARSED" "100" "35"
      New-MetricRow "tp38_sl18" "2024_Q3" "PARSED" "80" "20"
      New-MetricRow "baseline_promoted" "2024_Q3" "PARSED" "80" "25"
   ) -ExpectedOverall "PASS_MICRO" -ExpectedWindowDecisions @{
      "2024_Q1" = "PASS_WINDOW"
      "2024_Q3" = "PASS_WINDOW"
   }

   Invoke-DecisionCase -CaseName "candidate_loss" -Rows @(
      New-MetricRow "tp38_sl18" "2024_Q1" "PARSED" "-1" "10"
      New-MetricRow "baseline_promoted" "2024_Q1" "PARSED" "0" "12"
   ) -ExpectedOverall "REJECT_CANDIDATE" -ExpectedWindowDecisions @{
      "2024_Q1" = "FAIL_CANDIDATE_LOSS"
   }

   Invoke-DecisionCase -CaseName "underperform_baseline" -Rows @(
      New-MetricRow "tp38_sl18" "2024_Q1" "PARSED" "50" "10"
      New-MetricRow "baseline_promoted" "2024_Q1" "PARSED" "60" "12"
   ) -ExpectedOverall "REJECT_CANDIDATE" -ExpectedWindowDecisions @{
      "2024_Q1" = "FAIL_UNDERPERFORM_BASELINE"
   }

   Invoke-DecisionCase -CaseName "repair_report" -Rows @(
      New-MetricRow "tp38_sl18" "2024_Q1" "UNPARSED" "" ""
      New-MetricRow "baseline_promoted" "2024_Q1" "PARSED" "60" "12"
   ) -ExpectedOverall "REPAIR_REPORTS" -ExpectedWindowDecisions @{
      "2024_Q1" = "REPAIR_REPORT"
   }

   Invoke-DecisionCase -CaseName "waiting_report" -Rows @(
      New-MetricRow "tp38_sl18" "2024_Q1" "MISSING_REPORT" "" ""
      New-MetricRow "baseline_promoted" "2024_Q1" "MISSING_REPORT" "" ""
   ) -ExpectedOverall "WAITING_FOR_REPORTS" -ExpectedWindowDecisions @{
      "2024_Q1" = "WAITING_FOR_REPORTS"
   }
} finally {
   if(Test-Path -LiteralPath $tempRoot) {
      $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
      $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
      if($resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $tempRoot -Recurse -Force
      }
   }
}

"EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS"
