$ErrorActionPreference = "Stop"

# Cleanup-only helper. It starts nothing and only targets MT5-family executable processes.
$targetNameRegex = '^(terminal64|terminal|metatester64|metatester|metaeditor64|metaeditor)\.exe$'
$targetPathRegex = '\\(MetaTrader|MT5|MetaQuotes|MQL5)\\|terminal64\.exe$|terminal\.exe$|metatester64\.exe$|metatester\.exe$|metaeditor64\.exe$|metaeditor\.exe$'
$excludeNameRegex = '^(powershell|pwsh|cmd|conhost|OpenAI|Codex|Code|WindowsTerminal)\.exe$'

$targetRows = New-Object System.Collections.Generic.List[object]

try {
   $cimProcesses = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $_.Name -notmatch $excludeNameRegex -and (
         $_.Name -match $targetNameRegex -or
         ([string]$_.ExecutablePath) -match $targetPathRegex
      )
   })

   foreach($process in $cimProcesses) {
      $targetRows.Add([pscustomobject]@{
         Id = [int]$process.ProcessId
         Name = [string]$process.Name
         Source = "CIM"
         ExecutablePath = [string]$process.ExecutablePath
      }) | Out-Null
   }
} catch {}

$stopped = 0
$errors = New-Object System.Collections.Generic.List[string]
foreach($target in $targetRows) {
   try {
      Stop-Process -Id $target.Id -Force -ErrorAction Stop
      $stopped++
   } catch {
      $errors.Add("Could not stop $($target.Name):$($target.Id): $($_.Exception.Message)") | Out-Null
   }
}

$remaining = New-Object System.Collections.Generic.List[object]
try {
   foreach($process in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $_.Name -notmatch $excludeNameRegex -and (
         $_.Name -match $targetNameRegex -or
         ([string]$_.ExecutablePath) -match $targetPathRegex
      )
   })) {
      $remaining.Add([pscustomobject]@{ Id = [int]$process.ProcessId; Name = [string]$process.Name; ExecutablePath = [string]$process.ExecutablePath }) | Out-Null
   }
} catch {}

$result = [pscustomobject]@{
   Action = "Stop MT5 stray processes only"
   StartedNothing = $true
   TargetedCount = $targetRows.Count
   StoppedCount = $stopped
   RemainingCount = $remaining.Count
   Remaining = (($remaining | ForEach-Object { "$($_.Name):$($_.Id)" }) -join "; ")
   Errors = ($errors -join " | ")
}

$result

if($remaining.Count -gt 0 -or $errors.Count -gt 0) { exit 1 }
