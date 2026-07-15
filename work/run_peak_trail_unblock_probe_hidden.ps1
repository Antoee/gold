param(
   [int]$TimeoutMinutesPerConfig = 30,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

function Write-Step {
   param([string]$Message)
   Write-Output ("[{0}] {1}" -f (Get-Date).ToString("s"), $Message)
}

function Invoke-CheckedPowerShell {
   param([string[]]$Arguments)
   & powershell @Arguments
   if($LASTEXITCODE -ne 0) {
      throw "Child PowerShell failed with exit code ${LASTEXITCODE}: powershell $($Arguments -join ' ')"
   }
}

try {
   Write-Step "Building peak-trail unblock Model4 package."
   Invoke-CheckedPowerShell @(
      "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "work\build_peak_trail_unblock_probe_package.ps1",
      "-Model", "4",
      "-From", "2019.01.01",
      "-To", "2026.07.12",
      "-Window", "continuous_2019_2026"
   )

   Write-Step "Compiling current EA source hidden."
   Invoke-CheckedPowerShell @(
      "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "work\compile_mt5_expert_hidden.ps1",
      "-SourcePath", "Professional_XAUUSD_EA.mq5",
      "-LogPath", "outputs\MT5_HIDDEN_COMPILE_PEAK_TRAIL_UNBLOCK.log",
      "-TimeoutSeconds", "180"
   )

   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   Remove-Item -LiteralPath work\MT5_LOCAL_LAUNCH_DISABLED.lock -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path work\ALLOW_MT5_LOCAL_LAUNCH.unlock -Force | Out-Null
   New-Item -ItemType File -Path work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock -Force | Out-Null

   Write-Step "Running peak-trail unblock Model4 package hidden."
   Invoke-CheckedPowerShell @(
      "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "work\run_first_pass_package_hidden.ps1",
      "-ManifestPath", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_PACKAGE_MANIFEST.csv",
      "-TimeoutMinutesPerConfig", ([string]$TimeoutMinutesPerConfig),
      "-MaxCpuPercent", ([string]$MaxCpuPercent),
      "-Run",
      "-OutCsv", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_RUN.csv",
      "-OutMarkdown", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_RUN.md"
   )

   Write-Step "Parsing returned reports."
   Invoke-CheckedPowerShell @(
      "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "work\import_first_pass_hidden_log_results.ps1",
      "-RunCsv", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_RUN.csv",
      "-QueueManifestPath", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_PACKAGE_MANIFEST.csv",
      "-OutResults", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_RESULTS.csv",
      "-OutSummary", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_REPORT_SUMMARY.csv",
      "-OutMarkdown", "outputs\PEAK_TRAIL_UNBLOCK_PROBE_REPORT_METRICS.md"
   )

   Write-Step "Peak-trail unblock probe finished."
}
finally {
   Get-Process terminal64,terminal,metatester64,metatester,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
      Stop-Process -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath work\ALLOW_MT5_LOCAL_LAUNCH.unlock -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path work\MT5_LOCAL_LAUNCH_DISABLED.lock -Force | Out-Null
   Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   powershell -NoProfile -ExecutionPolicy Bypass -File work\audit_mt5_local_safety.ps1
}
