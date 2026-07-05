param(
   [string]$PackageDir = "outputs\external_mt5_validation_package",
   [string]$OutMetrics = "outputs\EXTERNAL_MT5_PACKAGE_REPORT_METRICS.csv",
   [string]$OutSummary = "outputs\EXTERNAL_MT5_PACKAGE_REPORT_SUMMARY.csv",
   [string]$OutMarkdown = "outputs\EXTERNAL_MT5_PACKAGE_REPORT_METRICS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $PackageDir "HANDOFF_MANIFEST.csv"
$reportDir = Join-Path $PackageDir "reports_here"

if(!(Test-Path -LiteralPath $manifestPath)) { throw "Package manifest missing: $manifestPath" }
if(!(Test-Path -LiteralPath $reportDir)) { throw "Package reports folder missing: $reportDir" }

& powershell -NoProfile -ExecutionPolicy Bypass -File "work\collect_validation_results.ps1" `
   -ManifestPath $manifestPath `
   -ReportDir $reportDir `
   -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" `
   -OutResults $OutMetrics `
   -OutSummary $OutSummary `
   -OutMarkdown $OutMarkdown

[pscustomobject]@{
   Manifest = $manifestPath
   ReportDir = $reportDir
   OutMetrics = $OutMetrics
   OutSummary = $OutSummary
   OutMarkdown = $OutMarkdown
}
