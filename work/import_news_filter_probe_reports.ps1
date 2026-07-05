param(
   [string]$ReportDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifest = "outputs\news_filter_probe_handoff\HANDOFF_MANIFEST.csv"
if(!(Test-Path -LiteralPath $manifest)) { throw "Missing news filter probe manifest: $manifest" }

powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\collect_validation_results.ps1" `
   -ManifestPath $manifest `
   -ReportDir $ReportDir `
   -ReportNameTemplate "news_filter_probe_{Profile}_{Window}" `
   -OutResults "outputs\NEWS_FILTER_PROBE_REPORT_METRICS.csv" `
   -OutSummary "outputs\NEWS_FILTER_PROBE_REPORT_SUMMARY.csv" `
   -OutMarkdown "outputs\NEWS_FILTER_PROBE_REPORT_METRICS.md"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\work\build_news_filter_probe_decision.ps1"
