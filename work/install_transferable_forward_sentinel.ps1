[CmdletBinding()]
param(
   [string]$SourcePath = "work\Professional_XAUUSD_Forward_Sentinel.mq5",
   [string]$ProfilePath = "outputs\TRANSFERABLE_FORWARD_SENTINEL_PROFILE.set",
   [string]$MetaEditorPath = "C:\Program Files\MetaTrader 5\MetaEditor64.exe",
   [string]$TerminalDataPath = "",
   [string]$CompileLogPath = "outputs\TRANSFERABLE_FORWARD_SENTINEL_COMPILE.log",
   [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceFull = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$profileFull = (Resolve-Path -LiteralPath (Join-Path $repo $ProfilePath)).Path
$logFull = Join-Path $repo $CompileLogPath

if(!(Test-Path -LiteralPath $MetaEditorPath -PathType Leaf)) {
   throw "MetaEditor missing: $MetaEditorPath"
}

if([string]::IsNullOrWhiteSpace($TerminalDataPath)) {
   $terminalBase = Join-Path $env:APPDATA "MetaQuotes\Terminal"
   $installRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $MetaEditorPath)).Path.TrimEnd('\')
   $matches = [System.Collections.Generic.List[string]]::new()
   foreach($directory in @(Get-ChildItem -LiteralPath $terminalBase -Directory -ErrorAction SilentlyContinue)) {
      $originPath = Join-Path $directory.FullName "origin.txt"
      if(!(Test-Path -LiteralPath $originPath -PathType Leaf)) { continue }
      $origin = (Get-Content -Raw -LiteralPath $originPath).Trim().TrimEnd('\')
      if($origin -ieq $installRoot) { [void]$matches.Add($directory.FullName) }
   }
   if($matches.Count -ne 1) {
      throw "Could not uniquely resolve the MT5 data folder for $installRoot. Pass -TerminalDataPath explicitly."
   }
   $terminalRoot = $matches[0]
}
else {
   $terminalRoot = (Resolve-Path -LiteralPath $TerminalDataPath).Path
}

$experts = Join-Path $terminalRoot "MQL5\Experts"
$targetSource = Join-Path $experts "Professional_XAUUSD_Forward_Sentinel.mq5"
$targetBinary = Join-Path $experts "Professional_XAUUSD_Forward_Sentinel.ex5"

New-Item -ItemType Directory -Path $experts -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination $targetSource -Force
Remove-Item -LiteralPath $logFull -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $targetBinary -Force -ErrorAction SilentlyContinue

$arguments = "/compile:`"$targetSource`" /log:`"$logFull`""
$processId = [Mt5Audio.HiddenProcess]::StartHidden($MetaEditorPath, $arguments)
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
   Start-Sleep -Milliseconds 500
   Set-MT5ProcessMute -Muted $true
   Set-MT5ProcessLowImpact -MaxCpuPercent 80
   $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
} while($process -and (Get-Date) -lt $deadline)

if(Get-Process -Id $processId -ErrorAction SilentlyContinue) {
   Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
   throw "Sentinel compile timed out after $TimeoutSeconds seconds."
}
if(!(Test-Path -LiteralPath $logFull -PathType Leaf)) {
   throw "Sentinel compile log was not produced."
}
$resultLine = Get-Content -LiteralPath $logFull -Encoding Unicode |
   Where-Object { $_ -match 'Result:' } |
   Select-Object -Last 1
if($resultLine -notmatch '0 errors, 0 warnings') {
   throw "Sentinel compile failed: $resultLine"
}
if(!(Test-Path -LiteralPath $targetBinary -PathType Leaf)) {
   throw "Sentinel binary was not produced."
}

$status = [pscustomobject]@{
   Status = "INSTALLED_NOT_ATTACHED"
   SourceSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFull).Hash
   ProfileSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $profileFull).Hash
   InstalledSourceSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetSource).Hash
   InstalledBinarySha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetBinary).Hash
   CompileResult = $resultLine
   TradingFunctionsPresent = [bool](Select-String -LiteralPath $sourceFull -Pattern 'OrderSend|CTrade|\.Buy\(|\.Sell\(|PositionClose|PositionModify' -Quiet)
   AccountIdentifierWritten = [bool](Select-String -LiteralPath $sourceFull -Pattern 'ACCOUNT_LOGIN' -Quiet)
}
$status | Export-Csv -LiteralPath (Join-Path $repo "outputs\TRANSFERABLE_FORWARD_SENTINEL_INSTALL_STATUS.csv") -NoTypeInformation -Encoding ASCII
$status
