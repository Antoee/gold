param(
   [int]$MonitorSeconds = 0,
   [int]$PollMilliseconds = 500,
   [switch]$StopProcesses = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Cleanup-only watchdog. It starts nothing and only targets MT5-family executable processes.
$targetNameRegex = '^(terminal64|terminal|metatester64|metatester|metaeditor64|metaeditor)\.exe$'
$targetPathRegex = '\\(MetaTrader|MT5|MetaQuotes|MQL5)\\|terminal64\.exe$|terminal\.exe$|metatester64\.exe$|metatester\.exe$|metaeditor64\.exe$|metaeditor\.exe$'
$excludeNameRegex = '^(powershell|pwsh|cmd|conhost|OpenAI|Codex|Code|WindowsTerminal)\.exe$'

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
   @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $_.Name -notmatch $excludeNameRegex -and (
         $_.Name -match $targetNameRegex -or
         ([string]$_.ExecutablePath) -match $targetPathRegex
      )
   })
}

function Invoke-MT5WatchdogPass {
   $targets = @(Get-MT5WatchdogTargets)
   $hidden = 0
   try { $hidden = [Mt5Safe.WatchdogWindowControl]::HideWindows(@("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")) } catch {}

   $stopped = 0
   $errors = New-Object System.Collections.Generic.List[string]
   if($StopProcesses) {
      foreach($target in $targets) {
         try {
            Stop-Process -Id ([int]$target.ProcessId) -Force -ErrorAction Stop
            $stopped++
         } catch {
            $errors.Add("Could not stop $($target.Name):$($target.ProcessId): $($_.Exception.Message)") | Out-Null
         }
      }
   }

   [pscustomobject]@{
      StartedNothing = $true
      Targets = $targets.Count
      HiddenWindows = $hidden
      Stopped = $stopped
      Errors = ($errors -join " | ")
   }
}

$deadline = if($MonitorSeconds -gt 0) { (Get-Date).AddSeconds($MonitorSeconds) } else { Get-Date }
$rows = New-Object System.Collections.Generic.List[object]
do {
   $rows.Add((Invoke-MT5WatchdogPass)) | Out-Null
   if($MonitorSeconds -le 0) { break }
   Start-Sleep -Milliseconds $PollMilliseconds
} while((Get-Date) -lt $deadline)

$rows
if(@($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Errors) }).Count -gt 0) { exit 1 }
