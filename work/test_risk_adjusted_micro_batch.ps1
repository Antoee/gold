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

function New-ManifestRow {
   param([int]$Priority, [string]$Profile, [string]$Set, [string]$Window, [string]$Status = "MISSING_REPORT")
   [pscustomobject]@{
      Phase = "phase1_fast_triage"
      Model = "2"
      Priority = $Priority
      Profile = $Profile
      Set = $Set
      Window = $Window
      From = "2024.01.01"
      To = "2024.03.31"
      Config = "work\fixture\$Profile`_$Set`_$Window.ini"
      Status = $Status
   }
}

function New-MetricRow {
   param([object]$ManifestRow, [string]$Status)
   [pscustomobject]@{
      Priority = $ManifestRow.Priority
      Phase = $ManifestRow.Phase
      Profile = $ManifestRow.Profile
      Set = $ManifestRow.Set
      Window = $ManifestRow.Window
      From = $ManifestRow.From
      To = $ManifestRow.To
      Status = $Status
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
$tempRoot = Join-Path $workRoot ("risk_micro_selector_tmp_{0}" -f $PID)

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
      New-ManifestRow 1 "baseline_promoted" "stress" "2024_Q1"
      New-ManifestRow 1 "baseline_promoted" "stress" "2024_Q3"
      New-ManifestRow 2 "baseline_dd4" "stress" "2024_Q1"
      New-ManifestRow 2 "tp38_sl18" "stress" "2024_Q1"
      New-ManifestRow 2 "tp38_sl18" "stress" "2024_Q3"
      New-ManifestRow 3 "giveback25_tp38" "stress" "2024_Q1"
      New-ManifestRow 20 "risk20_tp38_sl18" "stress" "2024_Q1"
      New-ManifestRow 99 "bad_profile" "stress" "2024_Q1"
   )

   $manifestPath = Join-Path $tempRoot "manifest.csv"
   $metricsPath = Join-Path $tempRoot "metrics.csv"
   $profilesPath = Join-Path $tempRoot "profiles.csv"
   $guardrailPath = Join-Path $tempRoot "guardrails.csv"
   $outCsv = Join-Path $tempRoot "micro.csv"
   $outMd = Join-Path $tempRoot "micro.md"

   $manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation
   @($manifestRows | ForEach-Object {
      $status = if($_.Profile -eq "bad_profile") { "UNPARSED" } else { "MISSING_REPORT" }
      New-MetricRow $_ $status
   }) | Export-Csv -LiteralPath $metricsPath -NoTypeInformation

   @(
      [pscustomobject]@{ Priority = 1; Profile = "baseline_promoted"; Phase2Seed = "True"; Settings = ""; Overrides = "" }
      [pscustomobject]@{ Priority = 2; Profile = "baseline_dd4"; Phase2Seed = "True"; Settings = ""; Overrides = "InpMaxEquityDrawdownPercent=4.00" }
      [pscustomobject]@{ Priority = 2; Profile = "tp38_sl18"; Phase2Seed = "True"; Settings = ""; Overrides = "" }
      [pscustomobject]@{ Priority = 3; Profile = "giveback25_tp38"; Phase2Seed = "False"; Settings = ""; Overrides = "" }
      [pscustomobject]@{ Priority = 20; Profile = "risk20_tp38_sl18"; Phase2Seed = "False"; Settings = ""; Overrides = "" }
      [pscustomobject]@{ Priority = 99; Profile = "bad_profile"; Phase2Seed = "False"; Settings = ""; Overrides = "" }
   ) | Export-Csv -LiteralPath $profilesPath -NoTypeInformation

   @(
      [pscustomobject]@{ Profile = "baseline_promoted"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 82; RiskPercent = 1.6; UsesGivebackGuard = "False"; RiskFlags = ""; OverfitFlags = "adaptive_reverse_requires_walk_forward" }
      [pscustomobject]@{ Profile = "baseline_dd4"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 90; RiskPercent = 1.6; UsesGivebackGuard = "False"; RiskFlags = ""; OverfitFlags = "adaptive_reverse_requires_walk_forward" }
      [pscustomobject]@{ Profile = "tp38_sl18"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 90; RiskPercent = 1.6; UsesGivebackGuard = "False"; RiskFlags = ""; OverfitFlags = "" }
      [pscustomobject]@{ Profile = "giveback25_tp38"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 95; RiskPercent = 1.6; UsesGivebackGuard = "True"; RiskFlags = ""; OverfitFlags = "" }
      [pscustomobject]@{ Profile = "risk20_tp38_sl18"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 90; RiskPercent = 2.0; UsesGivebackGuard = "False"; RiskFlags = "risk_percent_above_promoted"; OverfitFlags = "" }
      [pscustomobject]@{ Profile = "bad_profile"; GuardrailStatus = "REVIEW_REQUIRED"; GuardrailScore = 60; RiskPercent = 1.6; UsesGivebackGuard = "False"; RiskFlags = ""; OverfitFlags = "" }
   ) | Export-Csv -LiteralPath $guardrailPath -NoTypeInformation

   $selector = Join-Path $resolvedRepo "work\build_risk_adjusted_micro_batch.ps1"
   & powershell -NoProfile -ExecutionPolicy Bypass -File $selector `
      -ManifestPath $manifestPath `
      -MetricsPath $metricsPath `
      -ProfilesPath $profilesPath `
      -GuardrailPath $guardrailPath `
      -OutCsv $outCsv `
      -OutReport $outMd `
      -BatchSize 5 `
      -MaxPerProfile 2 | Out-Null

   $rows = @(Import-Csv -LiteralPath $outCsv)
   Assert-Equal $rows.Count 5 "Selected row count"
   Assert-Equal $rows[0].Profile "bad_profile" "Repair row should come first"
   Assert-Equal $rows[0].Role "Repair" "Repair role"
   if(@($rows | Where-Object { $_.Profile -eq "baseline_promoted" }).Count -lt 1) {
      throw "Expected baseline anchor in selected rows."
   }
   if(@($rows | Where-Object { $_.Profile -eq "baseline_dd4" }).Count -lt 1) {
      throw "Expected baseline_dd4 risk-control candidate in selected rows."
   }
   if(@($rows | Where-Object { $_.Profile -eq "tp38_sl18" }).Count -lt 1) {
      throw "Expected tp38_sl18 in selected rows."
   }
   if(@($rows | Where-Object { $_.Profile -eq "risk20_tp38_sl18" }).Count -gt 0) {
      throw "Higher-risk profile should not outrank the safer micro candidates in this fixture."
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

"RISK_ADJUSTED_MICRO_BATCH_SMOKE_PASS"
