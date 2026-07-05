param(
   [string]$ReportDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifest = "outputs\stress_smoke_handoff\HANDOFF_MANIFEST.csv"
if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
   throw "Missing stress smoke manifest: $manifest"
}

powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" `
   -ManifestPath $manifest `
   -ReportDir $ReportDir `
   -ReportNameTemplate "stress_smoke_phase1_{Profile}_{Window}" `
   -OutResults "outputs\STRESS_SMOKE_REPORT_METRICS.csv" `
   -OutSummary "outputs\STRESS_SMOKE_REPORT_SUMMARY.csv" `
   -OutMarkdown "outputs\STRESS_SMOKE_REPORT_METRICS.md"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_micro_test_decision.ps1" `
   -MetricsPath "outputs\STRESS_SMOKE_REPORT_METRICS.csv" `
   -ManifestPath $manifest `
   -OutCsv "outputs\STRESS_SMOKE_DECISION.csv" `
   -OutReport "outputs\STRESS_SMOKE_DECISION.md"
