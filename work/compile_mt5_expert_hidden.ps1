param(
   [string]$SourcePath = "outputs\Professional_XAUUSD_EA_TESTER_COMPACT.mq5",
   [string]$MetaEditorPath = "C:\Program Files\MetaTrader 5\MetaEditor64.exe",
   [string]$LogPath = "outputs\MT5_HIDDEN_COMPILE.log",
   [int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedSource = (Resolve-Path (Join-Path $repo $SourcePath)).Path
$resolvedLog = Join-Path $repo $LogPath
$experts = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts"
$target = Join-Path $experts "Professional_XAUUSD_EA.mq5"

if(!(Test-Path -LiteralPath $MetaEditorPath)) { throw "MetaEditor not found: $MetaEditorPath" }
New-Item -ItemType Directory -Path $experts -Force | Out-Null
Copy-Item -LiteralPath $resolvedSource -Destination $target -Force
Remove-Item -LiteralPath $resolvedLog -Force -ErrorAction SilentlyContinue

$arguments = "/compile:`"$target`" /log:`"$resolvedLog`""
$processId = [Mt5Audio.HiddenProcess]::StartHidden($MetaEditorPath, $arguments)
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)

do {
   Start-Sleep -Milliseconds 500
   Set-MT5BackgroundSafe
   $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
} while($process -and (Get-Date) -lt $deadline)

Get-Process MetaEditor,metaeditor64 -ErrorAction SilentlyContinue |
   Stop-Process -Force -ErrorAction SilentlyContinue

if(!(Test-Path -LiteralPath $resolvedLog)) {
   throw "Compile log not produced: $resolvedLog"
}

$tail = Get-Content -LiteralPath $resolvedLog -Tail 40
$resultLine = $tail | Where-Object { $_ -match "Result:" } | Select-Object -Last 1
if($resultLine -and $resultLine -notmatch "0 errors, 0 warnings") {
   throw "Compile failed or produced warnings: $resultLine"
}

[pscustomobject]@{
   Source = $resolvedSource
   Target = $target
   Log = $resolvedLog
   Result = $resultLine
}
