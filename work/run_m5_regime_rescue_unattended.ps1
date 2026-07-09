param(
   [string]$PackageDir = "work\local_mt5_m5_regime_rescue_package",
   [string]$RunCsv = "outputs\LOCAL_MT5_M5_REGIME_RESCUE_RUN.csv",
   [string]$ResultsCsv = "outputs\LOCAL_MT5_M5_REGIME_RESCUE_LOG_RESULTS.csv",
   [string]$SummaryCsv = "outputs\LOCAL_MT5_M5_REGIME_RESCUE_LOG_SUMMARY.csv",
   [string]$StatusPath = "outputs\M5_REGIME_RESCUE_UNATTENDED_STATUS.txt",
   [int]$TimeoutMinutesPerConfig = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$statusFull = Join-Path $repo $StatusPath

function Write-Status {
   param([string]$Message)
   $line = "{0:s} {1}" -f (Get-Date), $Message
   Add-Content -LiteralPath $statusFull -Value $line -Encoding ASCII
}

Remove-Item -LiteralPath $statusFull -Force -ErrorAction SilentlyContinue
Write-Status "START m5 regime rescue unattended validation"

$env:ALLOW_MT5_FOCUS_RISK = "1"
$env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"

try {
   Write-Status "Compiling compact tester source"
   powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\compile_mt5_expert_hidden.ps1") `
      -SourcePath "outputs\Professional_XAUUSD_EA_TESTER_COMPACT.mq5" `
      -LogPath "outputs\M5_REGIME_RESCUE_COMPILE.log" `
      -TimeoutSeconds 240 | Out-String | Add-Content -LiteralPath $statusFull -Encoding ASCII

   Write-Status "Running hidden MT5 package $PackageDir"
   powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\run_external_mt5_validation_package_local.ps1") `
      -PackageDir $PackageDir `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -OutCsv $RunCsv | Out-String | Add-Content -LiteralPath $statusFull -Encoding ASCII

   Write-Status "Parsing tester log results"
   powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\collect_local_mt5_log_results.ps1") `
      -RunCsv $RunCsv `
      -ManifestPath "outputs\M5_REGIME_RESCUE_MANIFEST.csv" `
      -OutResults $ResultsCsv `
      -OutSummary $SummaryCsv | Out-String | Add-Content -LiteralPath $statusFull -Encoding ASCII

   Write-Status "DONE validation and parsing"
}
catch {
   Write-Status "ERROR $($_.Exception.Message)"
   throw
}
finally {
   Write-Status "Restoring full EA source to MT5 Experts"
   try {
      powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "work\compile_mt5_expert_hidden.ps1") `
         -SourcePath "outputs\Professional_XAUUSD_EA.mq5" `
         -LogPath "outputs\M5_REGIME_RESCUE_RESTORE_FULL_COMPILE.log" `
         -TimeoutSeconds 240 | Out-String | Add-Content -LiteralPath $statusFull -Encoding ASCII
      Write-Status "RESTORE_COMPILE_DONE"
   }
   catch {
      Write-Status "RESTORE_COMPILE_ERROR $($_.Exception.Message)"
   }
}
