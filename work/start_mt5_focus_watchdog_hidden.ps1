param(
   [int]$MonitorSeconds = 7200,
   [int]$PollMilliseconds = 100
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$watchdogPath = Join-Path $PSScriptRoot "mt5_focus_watchdog.ps1"
$stopFile = Join-Path $PSScriptRoot "STOP_MT5_FOCUS_WATCHDOG"
$pidFile = Join-Path $PSScriptRoot "MT5_FOCUS_WATCHDOG.pid"

if(!(Test-Path -LiteralPath $watchdogPath)) {
   throw "Watchdog script not found: $watchdogPath"
}

if(Test-Path -LiteralPath $stopFile) {
   Remove-Item -LiteralPath $stopFile -Force
}

$existing = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction SilentlyContinue |
   Where-Object { $_.CommandLine -like '*mt5_focus_watchdog.ps1*' })
foreach($process in $existing) {
   Stop-Process -Id ([int]$process.ProcessId) -Force -ErrorAction SilentlyContinue
}

$arguments = @(
   "-NoLogo",
   "-NoProfile",
   "-NonInteractive",
   "-ExecutionPolicy",
   "Bypass",
   "-File",
   $watchdogPath,
   "-MonitorSeconds",
   ([string]$MonitorSeconds),
   "-PollMilliseconds",
   ([string]$PollMilliseconds)
)

$quotedArguments = @($arguments | ForEach-Object {
   '"' + (([string]$_) -replace '"', '\"') + '"'
})

$commandLine = "powershell.exe " + ($quotedArguments -join " ")
$startup = ([wmiclass]"Win32_ProcessStartup").CreateInstance()
$startup.ShowWindow = 0
$result = ([wmiclass]"Win32_Process").Create($commandLine, $repo, $startup)
if($result.ReturnValue -ne 0) {
   throw "Failed to start hidden watchdog. Win32_Process.Create returned $($result.ReturnValue)."
}

$processId = [int]$result.ProcessId
try {
   $startedProcess = Get-Process -Id $processId -ErrorAction Stop
   $startedProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
} catch {}

Set-Content -LiteralPath $pidFile -Value ([string]$processId) -Encoding ASCII

[pscustomobject]@{
   Action = "Started hidden MT5 focus watchdog"
   StartedNothingMT5 = $true
   ProcessId = $processId
   MonitorSeconds = $MonitorSeconds
   PollMilliseconds = $PollMilliseconds
   StopMarkerPresent = (Test-Path -LiteralPath $stopFile)
   PidFile = $pidFile
   WatchdogLog = (Join-Path $PSScriptRoot "mt5_focus_watchdog.log")
}
