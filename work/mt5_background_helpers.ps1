$ErrorActionPreference = "Stop"

if(-not ("Mt5Audio.SessionMute" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace Mt5Audio {
  public static class SessionMute {
    public static int SetMute(string[] processNames, bool mute) {
      int changed = 0;
      IMMDeviceEnumerator enumerator = null;
      IMMDevice device = null;
      IAudioSessionManager2 manager = null;
      IAudioSessionEnumerator sessions = null;

      try {
        enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumerator());
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(0, 1, out device));
        Guid iid = typeof(IAudioSessionManager2).GUID;
        object obj;
        Marshal.ThrowExceptionForHR(device.Activate(ref iid, 23, IntPtr.Zero, out obj));
        manager = (IAudioSessionManager2)obj;
        Marshal.ThrowExceptionForHR(manager.GetSessionEnumerator(out sessions));

        int count;
        Marshal.ThrowExceptionForHR(sessions.GetCount(out count));
        for(int i = 0; i < count; i++) {
          IAudioSessionControl ctl = null;
          try {
            Marshal.ThrowExceptionForHR(sessions.GetSession(i, out ctl));
            IAudioSessionControl2 ctl2 = ctl as IAudioSessionControl2;
            ISimpleAudioVolume volume = ctl as ISimpleAudioVolume;
            if(ctl2 == null || volume == null) { continue; }

            uint pid;
            Marshal.ThrowExceptionForHR(ctl2.GetProcessId(out pid));
            if(pid == 0) { continue; }

            Process p;
            try { p = Process.GetProcessById((int)pid); }
            catch { continue; }

            foreach(string name in processNames) {
              if(String.Equals(p.ProcessName, name, StringComparison.OrdinalIgnoreCase)) {
                Guid eventContext = Guid.Empty;
                Marshal.ThrowExceptionForHR(volume.SetMute(mute, ref eventContext));
                changed++;
                break;
              }
            }
          }
          finally {
            if(ctl != null) Marshal.ReleaseComObject(ctl);
          }
        }
      }
      finally {
        if(sessions != null) Marshal.ReleaseComObject(sessions);
        if(manager != null) Marshal.ReleaseComObject(manager);
        if(device != null) Marshal.ReleaseComObject(device);
        if(enumerator != null) Marshal.ReleaseComObject(enumerator);
      }
      return changed;
    }
  }

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
      bool ok = CreateProcess(
        null,
        commandLine,
        IntPtr.Zero,
        IntPtr.Zero,
        false,
        0x08000000,
        IntPtr.Zero,
        null,
        ref si,
        out pi
      );

      if(!ok) {
        throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      }

      CloseHandle(pi.hThread);
      CloseHandle(pi.hProcess);
      return pi.dwProcessId;
    }

    private static void EnsureBackgroundDesktop() {
      if(backgroundDesktop != IntPtr.Zero) {
        return;
      }

      backgroundDesktop = CreateDesktop(
        BackgroundDesktopName,
        null,
        IntPtr.Zero,
        0,
        0x10000000,
        IntPtr.Zero
      );

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
    private static extern bool CreateProcess(
      string lpApplicationName,
      string lpCommandLine,
      IntPtr lpProcessAttributes,
      IntPtr lpThreadAttributes,
      bool bInheritHandles,
      int dwCreationFlags,
      IntPtr lpEnvironment,
      string lpCurrentDirectory,
      ref STARTUPINFO lpStartupInfo,
      out PROCESS_INFORMATION lpProcessInformation
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr CreateDesktop(
      string lpszDesktop,
      string lpszDevice,
      IntPtr pDevmode,
      int dwFlags,
      uint dwDesiredAccess,
      IntPtr lpsa
    );
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
        try { p = Process.GetProcessById((int)pid); }
        catch { return true; }

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

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }

  [ComImport]
  [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
  internal class MMDeviceEnumerator {}

  [ComImport]
  [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface IMMDeviceEnumerator {
    int NotImpl1();
    [PreserveSig] int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
  }

  [ComImport]
  [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface IMMDevice {
    [PreserveSig] int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
  }

  [ComImport]
  [Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface IAudioSessionManager2 {
    int NotImpl1();
    int NotImpl2();
    [PreserveSig] int GetSessionEnumerator(out IAudioSessionEnumerator SessionEnum);
  }

  [ComImport]
  [Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface IAudioSessionEnumerator {
    [PreserveSig] int GetCount(out int SessionCount);
    [PreserveSig] int GetSession(int SessionCount, out IAudioSessionControl Session);
  }

  [ComImport]
  [Guid("F4B1A599-7266-4319-A8CA-E70ACB11E8CD")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface IAudioSessionControl {
    [PreserveSig] int GetState(out int pRetVal);
    [PreserveSig] int GetDisplayName([MarshalAs(UnmanagedType.LPWStr)] out string pRetVal);
    [PreserveSig] int SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string value, ref Guid EventContext);
    [PreserveSig] int GetIconPath([MarshalAs(UnmanagedType.LPWStr)] out string pRetVal);
    [PreserveSig] int SetIconPath([MarshalAs(UnmanagedType.LPWStr)] string value, ref Guid EventContext);
    [PreserveSig] int GetGroupingParam(out Guid pRetVal);
    [PreserveSig] int SetGroupingParam(ref Guid Override, ref Guid EventContext);
    [PreserveSig] int RegisterAudioSessionNotification(IntPtr NewNotifications);
    [PreserveSig] int UnregisterAudioSessionNotification(IntPtr NewNotifications);
  }

  [ComImport]
  [Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface IAudioSessionControl2 {
    [PreserveSig] int GetState(out int pRetVal);
    [PreserveSig] int GetDisplayName([MarshalAs(UnmanagedType.LPWStr)] out string pRetVal);
    [PreserveSig] int SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string value, ref Guid EventContext);
    [PreserveSig] int GetIconPath([MarshalAs(UnmanagedType.LPWStr)] out string pRetVal);
    [PreserveSig] int SetIconPath([MarshalAs(UnmanagedType.LPWStr)] string value, ref Guid EventContext);
    [PreserveSig] int GetGroupingParam(out Guid pRetVal);
    [PreserveSig] int SetGroupingParam(ref Guid Override, ref Guid EventContext);
    [PreserveSig] int RegisterAudioSessionNotification(IntPtr NewNotifications);
    [PreserveSig] int UnregisterAudioSessionNotification(IntPtr NewNotifications);
    [PreserveSig] int GetSessionIdentifier([MarshalAs(UnmanagedType.LPWStr)] out string retVal);
    [PreserveSig] int GetSessionInstanceIdentifier([MarshalAs(UnmanagedType.LPWStr)] out string retVal);
    [PreserveSig] int GetProcessId(out uint retVal);
  }

  [ComImport]
  [Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  internal interface ISimpleAudioVolume {
    [PreserveSig] int SetMasterVolume(float fLevel, ref Guid EventContext);
    [PreserveSig] int GetMasterVolume(out float pfLevel);
    [PreserveSig] int SetMute(bool bMute, ref Guid EventContext);
    [PreserveSig] int GetMute(out bool pbMute);
  }
}
"@
}

function Set-MT5ProcessMute {
   param([bool]$Muted = $true)

   try {
      [Mt5Audio.SessionMute]::SetMute(@("terminal64", "metatester64"), $Muted) | Out-Null
   }
   catch {
      Write-Warning "Could not update MT5 audio session mute state: $($_.Exception.Message)"
   }
}

function Set-MT5ProcessLowImpact {
   $processes = Get-Process terminal64,metatester64 -ErrorAction SilentlyContinue
   foreach($process in $processes) {
      try {
         $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
      }
      catch {
         Write-Warning "Could not lower MT5 process priority for $($process.ProcessName) $($process.Id): $($_.Exception.Message)"
      }
   }
}

function Hide-MT5Windows {
   try {
      [Mt5Audio.WindowControl]::HideProcessWindows(@("terminal64", "metatester64")) | Out-Null
   }
   catch {
      Write-Warning "Could not hide MT5 windows: $($_.Exception.Message)"
   }
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
   if($env:ALLOW_MT5_FOCUS_RISK -ne "1") {
      throw "MT5 local tester launch is disabled because terminal64 can still steal focus on this PC. Set ALLOW_MT5_FOCUS_RISK=1 and create work\ALLOW_MT5_LOCAL_LAUNCH.unlock only when the user explicitly allows local MT5 to run."
   }
   if(!(Test-Path -LiteralPath $unlockFile)) {
      throw "MT5 local tester launch is disabled. Create work\ALLOW_MT5_LOCAL_LAUNCH.unlock only after verifying the launcher will not affect normal PC use."
   }

   $processId = [Mt5Audio.HiddenProcess]::StartHidden($TerminalPath, "/config:`"$ConfigPath`"")
   for($i = 0; $i -lt 10; $i++) {
      Start-Sleep -Milliseconds 200
      Set-MT5BackgroundSafe
   }
   return $processId
}
