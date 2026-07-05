param(
   [int]$MonitorSeconds = 5,
   [int]$PollMilliseconds = 250,
   [switch]$StopProcesses = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Cleanup-only watchdog. It starts nothing and only targets MT5-family executable processes.
# Default mode is intentionally bounded so it cannot remain resident during normal PC use.
$repo = Split-Path -Parent $PSScriptRoot
$logPath = Join-Path $PSScriptRoot "mt5_focus_watchdog.log"
$stopFile = Join-Path $PSScriptRoot "STOP_MT5_FOCUS_WATCHDOG"
$processNames = @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")

if(-not ("Mt5Safe.WatchdogWindowControl" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace Mt5Safe {
  public static class WatchdogWindowControl {
    public static int HideWindows(string[] processNames) {
      int hidden = 0;
      EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
        if(hWnd == IntPtr.Zero || !IsWindowVisible(hWnd)) { return true; }
        uint pid;
        GetWindowThreadProcessId(hWnd, out pid);
        if(pid == 0) { return true; }
        Process p;
        try { p = Process.GetProcessById((int)pid); } catch { return true; }
        foreach(string name in processNames) {
          if(String.Equals(p.ProcessName, name, StringComparison.OrdinalIgnoreCase)) {
            ShowWindow(hWnd, 0);
            SetWindowPos(hWnd, new IntPtr(-2), -32000, -32000, 1, 1, 0x0010 | 0x0004 | 0x0001 | 0x0080);
            hidden++;
            break;
          }
        }
        return true;
      }, IntPtr.Zero);
      return hidden;
    }

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }
}
"@
}

function Get-MT5WatchdogTargets {
   @(Get-Process -Name $processNames -ErrorAction SilentlyContinue)
}

function Invoke-MT5WatchdogPass {
   $targets = @(Get-MT5WatchdogTargets)
   $hidden = 0
   try { $hidden = [Mt5Safe.WatchdogWindowControl]::HideWindows($processNames) } catch {}

   $stopped = 0
   $errors = New-Object System.Collections.Generic.List[string]
   if($StopProcesses) {
      foreach($target in $targets) {
         try {
            Stop-Process -Id ([int]$target.Id) -Force -ErrorAction Stop
            $stopped++
         } catch {
            $errors.Add("Could not stop $($target.ProcessName):$($target.Id): $($_.Exception.Message)") | Out-Null
         }
      }
   }

   $line = "$(Get-Date -Format o) targets=$($targets.Count) hidden=$hidden stopped=$stopped errors=$($errors.Count)"
   Add-Content -LiteralPath $logPath -Value $line

   [pscustomobject]@{
      StartedNothing = $true
      Targets = $targets.Count
      HiddenWindows = $hidden
      Stopped = $stopped
      Errors = ($errors -join " | ")
   }
}

"$(Get-Date -Format o) MT5 focus watchdog started." | Add-Content -LiteralPath $logPath
$deadline = if($MonitorSeconds -gt 0) { (Get-Date).AddSeconds($MonitorSeconds) } else { [datetime]::MaxValue }
$rows = New-Object System.Collections.Generic.List[object]
do {
   $rows.Add((Invoke-MT5WatchdogPass)) | Out-Null
   if(Test-Path -LiteralPath $stopFile) { break }
   Start-Sleep -Milliseconds $PollMilliseconds
} while((Get-Date) -lt $deadline)

"$(Get-Date -Format o) MT5 focus watchdog stopped." | Add-Content -LiteralPath $logPath
$rows
if(@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Errors) }).Count -gt 0) { exit 1 }
