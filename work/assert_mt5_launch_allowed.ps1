$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenDesktopAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"

$isExplicitlyUnlocked = (
   $env:ALLOW_MT5_FOCUS_RISK -eq "1" -and
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq "1" -and
   (Test-Path -LiteralPath $unlockFile) -and
   (Test-Path -LiteralPath $hiddenDesktopAckFile)
)

if(-not $isExplicitlyUnlocked) {
   $running = Get-Process terminal64,metatester64,MetaEditor -ErrorAction SilentlyContinue
   if($running) {
      $running | Stop-Process -Force -ErrorAction SilentlyContinue
   }

   throw "MT5 local launch is locked because it can steal focus on this PC. No tester run was started. To run locally, set ALLOW_MT5_FOCUS_RISK=1 and ALLOW_MT5_HIDDEN_DESKTOP_ACK=1, then create work\ALLOW_MT5_LOCAL_LAUNCH.unlock and work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock only after the user explicitly allows focus risk."
}
