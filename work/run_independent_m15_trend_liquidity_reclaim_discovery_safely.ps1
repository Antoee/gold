[CmdletBinding()]
param(
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateRange(1,60)][int]$TimeoutMinutesPerConfig = 8,
   [string]$ManifestPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$OutputPrefix = "TREND_LIQUIDITY_RECLAIM_PORTABLE"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
if(!$UserAuthorizedFocusRisk) { throw "Explicit focus-risk authorization is required." }
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestCandidate = if([IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath } else { Join-Path $repo $ManifestPath }
$manifest = (Resolve-Path -LiteralPath $manifestCandidate).Path
$hardLock = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlock = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAck = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
$oldFocus = $env:ALLOW_MT5_FOCUS_RISK
$oldHidden = $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK

function Stop-MT5Family {
   & (Join-Path $PSScriptRoot "stop_mt5_stray_processes.ps1") | Out-Null
}

try {
   Stop-MT5Family
   Remove-Item -LiteralPath $hardLock -Force -ErrorAction SilentlyContinue
   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   Set-Content -LiteralPath $unlock -Value "User-authorized isolated trend-liquidity discovery." -Encoding ASCII
   Set-Content -LiteralPath $hiddenAck -Value "Portable-worker focus risk acknowledged." -Encoding ASCII
   & (Join-Path $PSScriptRoot "run_mt5_portable_parallel_manifest.ps1") `
      -ManifestPath $manifest -UserAuthorizedFocusRisk -OutputPrefix $OutputPrefix `
      -MaxCpuPercent $MaxCpuPercent -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -ProgressIntervalSeconds 10
}
finally {
   Stop-MT5Family
   Remove-Item -LiteralPath $unlock -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $hiddenAck -Force -ErrorAction SilentlyContinue
   if([string]::IsNullOrWhiteSpace($oldFocus)) {
      Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   }
   else {
      $env:ALLOW_MT5_FOCUS_RISK = $oldFocus
   }
   if([string]::IsNullOrWhiteSpace($oldHidden)) {
      Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   }
   else {
      $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = $oldHidden
   }
   Set-Content -LiteralPath $hardLock -Value "Restored after isolated trend-liquidity discovery." -Encoding ASCII
}
