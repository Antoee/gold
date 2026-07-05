$ErrorActionPreference = "Stop"

if(-not ("Mt5Safe.HiddenProcess" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace Mt5Safe {
  public static class HiddenProcess {
    private static IntPtr backgroundDesktop = IntPtr.Zero;
    private const string BackgroundDesktopName = "MT5BacktestDesktop";

    public static int StartHidden(string fileName, string arguments) {
      EnsureBackgroundDesktop();

      STARTUPINFO si = new STARTUPINFO();
      PROCESS_INFORMATION pi = new PROCESS_INFORMATION();
      si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
      si.dwFlags = 0x00000001;
      si.wShowWindow = 0;
      si.lpDesktop = BackgroundDesktopName;

      string commandLine = "\"" + fileName + "\" " + arguments;
      bool ok = CreateProcess(null, commandLine, IntPtr.Zero, IntPtr.Zero, false, 0x08000000, IntPtr.Zero, null, ref si, out pi);
      if(!ok) {
        throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      }

      CloseHandle(pi.hThread);
      CloseHandle(pi.hProcess);
      return pi.dwProcessId;
    }

    private static void EnsureBackgroundDesktop() {
      if(backgroundDesktop != IntPtr.Zero) { return; }
      backgroundDesktop = CreateDesktop(BackgroundDesktopName, null, IntPtr.Zero, 0, 0x10000000, IntPtr.Zero);
      if(backgroundDesktop == IntPtr.Zero) {
        throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct STARTUPINFO {
      public int cb;
      public string lpReserved;
      public string lpDesktop;
      public string lpTitle;
      public int dwX;
      public int dwY;
      public int dwXSize;
      public int dwYSize;
      public int dwXCountChars;
      public int dwYCountChars;
      public int dwFillAttribute;
      public int dwFlags;
      public short wShowWindow;
      public short cbReserved2;
      public IntPtr lpReserved2;
      public IntPtr hStdInput;
      public IntPtr hStdOutput;
      public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROCESS_INFORMATION {
      public IntPtr hProcess;
      public IntPtr hThread;
      public int dwProcessId;
      public int dwThreadId;
    }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, int dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr CreateDesktop(string lpszDesktop, string lpszDevice, IntPtr pDevmode, int dwFlags, uint dwDesiredAccess, IntPtr lpsa);
  }

  public static class WindowControl {
    public static int HideProcessWindows(string[] processNames) {
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

function Stop-MT5LocalProcesses {
   Get-Process terminal64,metatester64,MetaEditor -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Set-MT5ProcessMute {
   param([bool]$Muted = $true)
   # Audio muting is best-effort. The local workspace version can add the full audio-session implementation.
}

function Set-MT5ProcessLowImpact {
   $processes = Get-Process terminal64,metatester64,MetaEditor -ErrorAction SilentlyContinue
   foreach($process in $processes) {
      try { $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch {}
   }
}

function Hide-MT5Windows {
   try { [Mt5Safe.WindowControl]::HideProcessWindows(@("terminal64", "metatester64", "MetaEditor")) | Out-Null } catch {}
}

function Set-MT5BackgroundSafe {
   Set-MT5ProcessMute -Muted $true
   Set-MT5ProcessLowImpact
   Hide-MT5Windows
}

function Start-MT5Hidden {
   param(
      [Parameter(Mandatory=$true)][string]$TerminalPath,
      [Parameter(Mandatory=$true)][string]$ConfigPath
   )

   $unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
   $hiddenDesktopAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
   $hardLockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"

   if(Test-Path -LiteralPath $hardLockFile) {
      Stop-MT5LocalProcesses
      throw "MT5 local tester launch is hard-locked because terminal64 can still steal focus on this PC. No tester process was started. Remove work\MT5_LOCAL_LAUNCH_DISABLED.lock only after the user explicitly allows local MT5 testing again."
   }

   if($env:ALLOW_MT5_FOCUS_RISK -ne "1" -or $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK -ne "1") {
      Stop-MT5LocalProcesses
      throw "MT5 local tester launch is disabled because terminal64 can still steal focus on this PC. Set ALLOW_MT5_FOCUS_RISK=1 and ALLOW_MT5_HIDDEN_DESKTOP_ACK=1 only when the user explicitly allows local MT5 to run."
   }
   if(!(Test-Path -LiteralPath $unlockFile) -or !(Test-Path -LiteralPath $hiddenDesktopAckFile)) {
      Stop-MT5LocalProcesses
      throw "MT5 local tester launch is disabled. Create work\ALLOW_MT5_LOCAL_LAUNCH.unlock and work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock only after verifying the launcher will not affect normal PC use."
   }

   $processId = [Mt5Safe.HiddenProcess]::StartHidden($TerminalPath, "/config:`"$ConfigPath`"")
   for($i = 0; $i -lt 10; $i++) {
      Start-Sleep -Milliseconds 200
      Set-MT5BackgroundSafe
   }
   return $processId
}
