$ErrorActionPreference = "Stop"

$processNames = @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")
$processes = @(Get-Process -Name $processNames -ErrorAction SilentlyContinue)

foreach($process in $processes) {
   try {
      Stop-Process -Id $process.Id -Force -ErrorAction Stop
   } catch {
      Write-Warning "Could not stop $($process.ProcessName):$($process.Id): $($_.Exception.Message)"
   }
}

$remaining = @(Get-Process -Name $processNames -ErrorAction SilentlyContinue)
[pscustomobject]@{
   Action = "Stop MT5 stray processes only"
   StartedNothing = $true
   StoppedCount = $processes.Count
   RemainingCount = $remaining.Count
   Remaining = (($remaining | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join "; ")
}

if($remaining.Count -gt 0) { exit 1 }
