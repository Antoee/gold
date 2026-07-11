$ErrorActionPreference = "SilentlyContinue"

$stopFile = Join-Path $PSScriptRoot "STOP_MT5_FOCUS_WATCHDOG"
New-Item -ItemType File -Path $stopFile -Force | Out-Null
Start-Sleep -Milliseconds 300

$needle = "mt5_focus_" + "watchdog.ps1"
$currentPid = $PID
Get-CimInstance Win32_Process |
   Where-Object { $_.ProcessId -ne $currentPid -and $_.CommandLine -like "*$needle*" } |
   ForEach-Object {
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
   }

Write-Host "MT5 focus watchdog stopped. Quiet stop marker left in place."
