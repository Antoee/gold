param(
   [string]$ReportDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifest = "outputs\breakeven_probe_handoff\HANDOFF_MANIFEST.csv"
if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
   throw "Missing break-even probe manifest: $manifest"
}

powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" `
   -ManifestPath $manifest `
   -ReportDir $ReportDir `
   -ReportNameTemplate "breakeven_probe_{Profile}_{Window}" `
   -OutResults "outputs\BREAKEVEN_PROBE_REPORT_METRICS.csv" `
   -OutSummary "outputs\BREAKEVEN_PROBE_REPORT_SUMMARY.csv" `
   -OutMarkdown "outputs\BREAKEVEN_PROBE_REPORT_METRICS.md"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_breakeven_probe_decision.ps1"
