param(
   [string]$ManifestPath = "outputs\PEAK_R20_DRAWDOWN_SWEEP_PACKAGE_MANIFEST.csv",
   [string]$OutCsv = "outputs\PEAK_R20_DRAWDOWN_HIDDEN_RUN_PLAN.csv",
   [string]$OutMarkdown = "outputs\PEAK_R20_DRAWDOWN_HIDDEN_RUN_PLAN.md",
   [int]$TimeoutMinutesPerConfig = 10,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 95
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$lockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"

function Stop-MT5LocalProcesses {
   foreach($name in @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")) {
      Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
   }
}

try {
   Stop-MT5LocalProcesses
   Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path $unlockFile -Force | Out-Null
   New-Item -ItemType File -Path $hiddenAckFile -Force | Out-Null
   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"

   & (Join-Path $PSScriptRoot "run_first_pass_package_hidden.ps1") `
      -ManifestPath $ManifestPath `
      -OutCsv $OutCsv `
      -OutMarkdown $OutMarkdown `
      -Run `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -MaxCpuPercent $MaxCpuPercent
}
finally {
   Stop-MT5LocalProcesses
   Remove-Item -LiteralPath $unlockFile -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $hiddenAckFile -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path $lockFile -Force | Out-Null
   Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
}
