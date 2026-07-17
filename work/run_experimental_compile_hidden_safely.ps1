param(
   [Parameter(Mandatory=$true)][string]$SourcePath,
   [Parameter(Mandatory=$true)][string]$LogPath,
   [int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$hardLockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
$oldFocusRisk = $env:ALLOW_MT5_FOCUS_RISK
$oldHiddenAck = $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK
$terminalDataRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
$expertsDir = Join-Path $terminalDataRoot "MQL5\Experts"
$installedSource = Join-Path $expertsDir "Professional_XAUUSD_EA.mq5"
$installedBinary = Join-Path $expertsDir "Professional_XAUUSD_EA.ex5"
$backupDir = Join-Path $PSScriptRoot ("mt5_restore_experimental_compile_{0}" -f $PID)
$sourceExisted = Test-Path -LiteralPath $installedSource
$binaryExisted = Test-Path -LiteralPath $installedBinary
$preSourceHash = if($sourceExisted) { (Get-FileHash -LiteralPath $installedSource -Algorithm SHA256).Hash } else { "MISSING" }
$preBinaryHash = if($binaryExisted) { (Get-FileHash -LiteralPath $installedBinary -Algorithm SHA256).Hash } else { "MISSING" }

function Stop-MT5LocalFamily {
   $stopHelper = Join-Path $PSScriptRoot "stop_mt5_stray_processes.ps1"
   if(Test-Path -LiteralPath $stopHelper) {
      & $stopHelper | Out-Null
      return
   }
   foreach($name in @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")) {
      Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
   }
}

function Remove-BackupDirSafe {
   if(!(Test-Path -LiteralPath $backupDir)) { return }
   $workRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path.TrimEnd('\') + '\'
   $resolved = (Resolve-Path -LiteralPath $backupDir).Path
   if(!$resolved.StartsWith($workRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove compile backup outside work directory: $resolved"
   }
   Remove-Item -LiteralPath $resolved -Recurse -Force
}

try {
   New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
   if($sourceExisted) { Copy-Item -LiteralPath $installedSource -Destination (Join-Path $backupDir "Professional_XAUUSD_EA.mq5") -Force }
   if($binaryExisted) { Copy-Item -LiteralPath $installedBinary -Destination (Join-Path $backupDir "Professional_XAUUSD_EA.ex5") -Force }

   Remove-Item -LiteralPath $hardLockFile -Force -ErrorAction SilentlyContinue
   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   Set-Content -LiteralPath $unlockFile -Value "Controlled hidden experimental compile." -Encoding ASCII
   Set-Content -LiteralPath $hiddenAckFile -Value "Hidden desktop acknowledged for controlled experimental compile." -Encoding ASCII

   & (Join-Path $PSScriptRoot "compile_mt5_expert_hidden.ps1") `
      -SourcePath $SourcePath `
      -LogPath $LogPath `
      -TimeoutSeconds $TimeoutSeconds
}
finally {
   Stop-MT5LocalFamily
   if($sourceExisted -and (Test-Path -LiteralPath (Join-Path $backupDir "Professional_XAUUSD_EA.mq5"))) {
      Copy-Item -LiteralPath (Join-Path $backupDir "Professional_XAUUSD_EA.mq5") -Destination $installedSource -Force
   } elseif(!$sourceExisted) {
      Remove-Item -LiteralPath $installedSource -Force -ErrorAction SilentlyContinue
   }
   if($binaryExisted -and (Test-Path -LiteralPath (Join-Path $backupDir "Professional_XAUUSD_EA.ex5"))) {
      Copy-Item -LiteralPath (Join-Path $backupDir "Professional_XAUUSD_EA.ex5") -Destination $installedBinary -Force
   } elseif(!$binaryExisted) {
      Remove-Item -LiteralPath $installedBinary -Force -ErrorAction SilentlyContinue
   }
   Remove-Item -LiteralPath $unlockFile -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $hiddenAckFile -Force -ErrorAction SilentlyContinue
   if([string]::IsNullOrWhiteSpace($oldFocusRisk)) { Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue }
   else { $env:ALLOW_MT5_FOCUS_RISK = $oldFocusRisk }
   if([string]::IsNullOrWhiteSpace($oldHiddenAck)) { Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue }
   else { $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = $oldHiddenAck }
   Set-Content -LiteralPath $hardLockFile -Value "Restored after controlled hidden experimental compile." -Encoding ASCII
}

$postSourceHash = if(Test-Path -LiteralPath $installedSource) { (Get-FileHash -LiteralPath $installedSource -Algorithm SHA256).Hash } else { "MISSING" }
$postBinaryHash = if(Test-Path -LiteralPath $installedBinary) { (Get-FileHash -LiteralPath $installedBinary -Algorithm SHA256).Hash } else { "MISSING" }
if($postSourceHash -ne $preSourceHash -or $postBinaryHash -ne $preBinaryHash) {
   throw "Experimental compile changed the installed MT5 source/binary state."
}
Remove-BackupDirSafe
