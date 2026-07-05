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

$logRoot = "outputs\offline_refresh_logs"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$stdoutPath = Join-Path $logRoot "$stamp`_import_external_reports.out.log"
$stderrPath = Join-Path $logRoot "$stamp`_import_external_reports.err.log"

$arguments = @(
   "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
   "-File", "work\collect_validation_results.ps1",
   "-ManifestPath", $manifestPath,
   "-ReportDir", $reportDir,
   "-ReportNameTemplate", "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}",
   "-OutResults", $OutMetrics,
   "-OutSummary", $OutSummary,
   "-OutMarkdown", $OutMarkdown
)

$process = Start-Process -FilePath "powershell.exe" `
   -ArgumentList $arguments `
   -WindowStyle Hidden `
   -RedirectStandardOutput $stdoutPath `
   -RedirectStandardError $stderrPath `
   -Wait `
   -PassThru

if($process.ExitCode -ne 0) {
   $errorText = ""
   if(Test-Path -LiteralPath $stderrPath) {
      $errorText = Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue
   }
   if([string]::IsNullOrWhiteSpace($errorText) -and (Test-Path -LiteralPath $stdoutPath)) {
      $errorText = Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue
   }
   if($errorText.Length -gt 1200) { $errorText = $errorText.Substring(0, 1200) }
   throw "External report import failed with exit code $($process.ExitCode). Log: $stderrPath. $errorText"
}

[pscustomobject]@{
   Manifest = $manifestPath
   ReportDir = $reportDir
   OutMetrics = $OutMetrics
   OutSummary = $OutSummary
   OutMarkdown = $OutMarkdown
}
