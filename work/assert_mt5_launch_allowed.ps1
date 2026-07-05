$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"

if($env:ALLOW_MT5_FOCUS_RISK -ne "1" -or !(Test-Path -LiteralPath $unlockFile)) {
   $running = Get-Process terminal64,metatester64,MetaEditor -ErrorAction SilentlyContinue
   if($running) {
      $running | Stop-Process -Force -ErrorAction SilentlyContinue
   }

   throw "MT5 local launch is locked because it can steal focus on this PC. No tester run was started. To run locally, set ALLOW_MT5_FOCUS_RISK=1 and create work\ALLOW_MT5_LOCAL_LAUNCH.unlock only after the user explicitly allows focus risk."
}
