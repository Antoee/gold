param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-ManifestRow {
   param([string]$Profile, [string]$Set, [string]$Window, [string]$From, [string]$To)
   [pscustomobject]@{
      Priority = 1
      Phase = "phase1_fast_triage"
      Model = "2"
      Profile = $Profile
      Set = $Set
      Window = $Window
      From = $From
      To = $To
      Config = "work\fixture\$Profile`_$Set`_$Window.ini"
   }
}

function New-MetricRow {
   param([object]$ManifestRow)
   [pscustomobject]@{
      Priority = $ManifestRow.Priority
      Phase = $ManifestRow.Phase
      Profile = $ManifestRow.Profile
      Set = $ManifestRow.Set
      Window = $ManifestRow.Window
      From = $ManifestRow.From
      To = $ManifestRow.To
      Status = "MISSING_REPORT"
      ReportPath = ""
      NetProfit = ""
      Balance = ""
      ProfitFactor = ""
      ExpectedPayoff = ""
      TotalTrades = ""
      MaxDrawdownMoney = ""
      MaxDrawdownPercent = ""
      BalanceDrawdownMaximal = ""
      EquityDrawdownMaximal = ""
      RecoveryFactor = ""
   }
}

$resolvedRepo = (Resolve-Path -LiteralPath $RepoRoot).Path
$workRoot = Join-Path $resolvedRepo "work"
$tempRoot = Join-Path $workRoot ("recent_batch_priority_tmp_{0}" -f $PID)

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
   $manifestRows = @(
      New-ManifestRow "baseline_promoted" "stress" "2024_Q1" "2024.01.01" "2024.03.31"
      New-ManifestRow "baseline_promoted" "stress" "2024_Q3" "2024.07.01" "2024.09.30"
      New-ManifestRow "baseline_promoted" "opportunity" "2026_Q2" "2026.04.01" "2026.06.30"
      New-ManifestRow "tp38_sl18" "stress" "2024_Q1" "2024.01.01" "2024.03.31"
      New-ManifestRow "tp38_sl18" "stress" "2024_Q3" "2024.07.01" "2024.09.30"
      New-ManifestRow "tp38_sl18" "opportunity" "2026_Q2" "2026.04.01" "2026.06.30"
   )

   $manifestPath = Join-Path $tempRoot "manifest.csv"
   $metricsPath = Join-Path $tempRoot "metrics.csv"
   $profilesPath = Join-Path $tempRoot "profiles.csv"
   $guardrailPath = Join-Path $tempRoot "guardrails.csv"
   $outCsv = Join-Path $tempRoot "batch.csv"
   $outMd = Join-Path $tempRoot "batch.md"

   $manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation
   @($manifestRows | ForEach-Object { New-MetricRow $_ }) | Export-Csv -LiteralPath $metricsPath -NoTypeInformation
   @(
      [pscustomobject]@{ Priority = 1; Profile = "baseline_promoted"; Phase2Seed = "True" }
      [pscustomobject]@{ Priority = 2; Profile = "tp38_sl18"; Phase2Seed = "True" }
   ) | Export-Csv -LiteralPath $profilesPath -NoTypeInformation
   @(
      [pscustomobject]@{ Profile = "baseline_promoted"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 85; RiskFlags = ""; OverfitFlags = "" }
      [pscustomobject]@{ Profile = "tp38_sl18"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 85; RiskFlags = ""; OverfitFlags = "" }
   ) | Export-Csv -LiteralPath $guardrailPath -NoTypeInformation

   & (Join-Path $resolvedRepo "work\build_next_profit_search_batch.ps1") `
      -ManifestPath $manifestPath `
      -MetricsPath $metricsPath `
      -ProfilesPath $profilesPath `
      -GuardrailPath $guardrailPath `
      -OutCsv $outCsv `
      -OutReport $outMd `
      -BatchSize 2 | Out-Null

   $rows = @(Import-Csv -LiteralPath $outCsv)
   if($rows.Count -ne 2) { throw "Expected 2 selected rows but got $($rows.Count)." }
   if(@($rows | Where-Object { $_.Window -eq "2026_Q2" }).Count -ne 2) {
      throw "Expected both top rows to target 2026_Q2 recent-data checks."
   }
   if(@($rows | Where-Object { [int]$_.RecentDataBoost -le 0 }).Count -gt 0) {
      throw "Expected selected recent rows to carry a positive RecentDataBoost."
   }
}
finally {
   if(Test-Path -LiteralPath $tempRoot) {
      $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
      $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
      if($resolvedTemp.StartsWith($resolvedWork, [System.StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $tempRoot -Recurse -Force
      }
   }
}

"NEXT_PROFIT_SEARCH_BATCH_RECENT_PRIORITY_SMOKE_PASS"
