$mt5TargetNameRegex = '^(terminal64|terminal|metatester64|metatester|metaeditor64|metaeditor)\.exe$'
$mt5TargetPathRegex = '\\(MetaTrader|MT5|MetaQuotes|MQL5)\\|terminal64\.exe$|terminal\.exe$|metatester64\.exe$|metatester\.exe$|metaeditor64\.exe$|metaeditor\.exe$'
$mt5ExcludeNameRegex = '^(powershell|pwsh|cmd|conhost|OpenAI|Codex|Code|WindowsTerminal)\.exe$'
$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenDesktopAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
$hardLockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"

function Stop-MT5StrayProcesses {
   try {
      $running = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
         $_.Name -notmatch $mt5ExcludeNameRegex -and (
            $_.Name -match $mt5TargetNameRegex -or
            ([string]$_.ExecutablePath) -match $mt5TargetPathRegex
         )
      })
      foreach($process in $running) {
         Stop-Process -Id ([int]$process.ProcessId) -Force -ErrorAction SilentlyContinue
      }
   } catch {
      foreach($name in @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")) {
         Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
      }
   }
}

if(Test-Path -LiteralPath $hardLockFile) {
   Stop-MT5StrayProcesses
   throw "MT5 local launch is hard-locked for this workspace because it can still steal focus on this PC. No tester run was started. Remove work\MT5_LOCAL_LAUNCH_DISABLED.lock only after the user explicitly allows local MT5 testing again."
}

$isExplicitlyUnlocked = (
   $env:ALLOW_MT5_FOCUS_RISK -eq "1" -and
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -eq "1" -and
   (Test-Path -LiteralPath $unlockFile) -and
   (Test-Path -LiteralPath $hiddenDesktopAckFile)
)

if(-not $isExplicitlyUnlocked) {
   Stop-MT5StrayProcesses
   throw "MT5 local launch is locked because it can steal focus on this PC. No tester run was started. To run locally, set ALLOW_MT5_FOCUS_RISK=1 and ALLOW_MT5_HIDDEN_DESKTOP_ACK=1, then create work\ALLOW_MT5_LOCAL_LAUNCH.unlock and work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock only after the user explicitly allows focus risk."
}
