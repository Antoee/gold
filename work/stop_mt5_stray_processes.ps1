$ErrorActionPreference = "Stop"

# Cleanup-only helper. It starts nothing and only targets MT5-family processes.
$processNamePatterns = @(
   "terminal",
   "terminal64",
   "metatester",
   "metatester64",
   "metaeditor",
   "metaeditor64"
)

$targetRows = New-Object System.Collections.Generic.List[object]

foreach($name in $processNamePatterns) {
   foreach($process in @(Get-Process -Name $name -ErrorAction SilentlyContinue)) {
      $targetRows.Add([pscustomobject]@{
         Id = $process.Id
         Name = $process.ProcessName
         Source = "Get-Process"
         CommandLine = ""
      }) | Out-Null
   }
}

# Some brokers rename installs or child tester processes. Use WMI/CIM as a second pass,
# still scoped to MetaTrader/MT5 executable names or paths.
try {
   $cimProcesses = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $_.Name -match '^(terminal64|terminal|metatester64|metatester|metaeditor64|metaeditor)\.exe$' -or
      $_.ExecutablePath -match 'MetaTrader|MT5|MetaQuotes' -or
      $_.CommandLine -match 'MetaTrader|MT5|MetaQuotes|terminal64\.exe|metaeditor64\.exe|metatester64\.exe'
   })
   foreach($process in $cimProcesses) {
      if(-not ($targetRows | Where-Object { $_.Id -eq [int]$process.ProcessId })) {
         $targetRows.Add([pscustomobject]@{
            Id = [int]$process.ProcessId
            Name = [string]$process.Name
            Source = "CIM"
            CommandLine = [string]$process.CommandLine
         }) | Out-Null
      }
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
foreach($name in $processNamePatterns) {
   foreach($process in @(Get-Process -Name $name -ErrorAction SilentlyContinue)) {
      $remaining.Add([pscustomobject]@{ Id = $process.Id; Name = $process.ProcessName }) | Out-Null
   }
}

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
