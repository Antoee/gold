' Runs the MT5 cleanup script without opening a visible PowerShell console.
' This starts no MT5, MetaTester, or MetaEditor process.
Option Explicit

Dim shell, fso, scriptDir, psScript, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "stop_mt5_stray_processes.ps1")

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & psScript & Chr(34)

' Window style 0 keeps PowerShell hidden; True waits for cleanup to finish.
WScript.Quit shell.Run(command, 0, True)
