param(
   [int]$TimeoutMinutesPerConfig = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

function Write-Step {
   param([string]$Message)
   Write-Output ("[{0}] {1}" -f (Get-Date).ToString("s"), $Message)
}

function Collect-Run {
   param(
      [string]$RunCsv,
      [string]$ManifestPath,
      [string]$OutResults,
      [string]$OutSummary
   )

   $testerLog = Join-Path $env:APPDATA ("MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\{0}.log" -f (Get-Date).ToString("yyyyMMdd"))
   powershell -NoProfile -ExecutionPolicy Bypass -File work\collect_local_mt5_log_results.ps1 `
      -RunCsv $RunCsv `
      -ManifestPath $ManifestPath `
      -TesterLogPath $testerLog `
      -OutResults $OutResults `
      -OutSummary $OutSummary
}

try {
   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   Remove-Item -LiteralPath work\MT5_LOCAL_LAUNCH_DISABLED.lock -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path work\ALLOW_MT5_LOCAL_LAUNCH.unlock -Force | Out-Null
   New-Item -ItemType File -Path work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock -Force | Out-Null

   Write-Step "Starting LowATR monthly stats validation."
   powershell -NoProfile -ExecutionPolicy Bypass -File work\run_external_mt5_validation_package_local.ps1 `
      -PackageDir outputs\realtick_islp_lowatr_orderflow_monthly_validation_package `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -OutCsv outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RUN.csv

   Write-Step "Collecting LowATR monthly stats."
   Collect-Run `
      -RunCsv outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RUN.csv `
      -ManifestPath outputs\realtick_islp_lowatr_orderflow_monthly_validation_package\EXPECTED_REPORTS.csv `
      -OutResults outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RESULTS.csv `
      -OutSummary outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv

   Write-Step "Starting LowATR quarterly stats validation."
   powershell -NoProfile -ExecutionPolicy Bypass -File work\run_external_mt5_validation_package_local.ps1 `
      -PackageDir outputs\realtick_islp_lowatr_orderflow_quarterly_validation_package `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -OutCsv outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RUN.csv

   Write-Step "Collecting LowATR quarterly stats."
   Collect-Run `
      -RunCsv outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RUN.csv `
      -ManifestPath outputs\realtick_islp_lowatr_orderflow_quarterly_validation_package\EXPECTED_REPORTS.csv `
      -OutResults outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RESULTS.csv `
      -OutSummary outputs\REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv

   Write-Step "LowATR stats validation finished."
}
finally {
   Get-Process terminal64,metatester64,MetaEditor,metaeditor64,terminal,metatester -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath work\ALLOW_MT5_LOCAL_LAUNCH.unlock -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path work\MT5_LOCAL_LAUNCH_DISABLED.lock -Force | Out-Null
   Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   powershell -NoProfile -ExecutionPolicy Bypass -File work\audit_mt5_local_safety.ps1
}
