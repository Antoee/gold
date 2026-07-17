param(
   [Parameter(Mandatory=$true)][string]$SourcePath,
   [Parameter(Mandatory=$true)][string]$LogPath,
   [Parameter(Mandatory=$true)][switch]$UserAuthorizedFocusRisk,
   [int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

if(!$UserAuthorizedFocusRisk) { throw "Explicit focus-risk authorization is required." }
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = (Resolve-Path (Join-Path $repo $SourcePath)).Path
$log = Join-Path $repo $LogPath
$metaEditor = "C:\Program Files\MetaTrader 5\MetaEditor64.exe"
$expertsDir = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts"
$installedSource = Join-Path $expertsDir "Professional_XAUUSD_EA.mq5"
$installedBinary = Join-Path $expertsDir "Professional_XAUUSD_EA.ex5"

if(!(Test-Path -LiteralPath $metaEditor -PathType Leaf)) { throw "MetaEditor missing: $metaEditor" }
if([IO.Path]::GetExtension($source) -ne ".mq5") { throw "Only an MQ5 source may be compiled." }
if(!$source.StartsWith($repo + "\", [StringComparison]::OrdinalIgnoreCase)) { throw "Source is outside the workspace." }

function Get-OptionalHash([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return "MISSING" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$preInstalledSourceHash = Get-OptionalHash $installedSource
$preInstalledBinaryHash = Get-OptionalHash $installedBinary
$terminalIds = @(Get-Process terminal,terminal64 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
$compiledBinary = [IO.Path]::ChangeExtension($source, ".ex5")
Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $compiledBinary -Force -ErrorAction SilentlyContinue

$arguments = "/compile:`"$source`" /log:`"$log`""
$processId = [Mt5Audio.HiddenProcess]::StartHidden($metaEditor, $arguments)
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
   Start-Sleep -Milliseconds 500
   Set-MT5ProcessMute
   $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
} while($process -and (Get-Date) -lt $deadline)

if($process) {
   Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
   throw "Isolated MetaEditor compile timed out."
}
if(!(Test-Path -LiteralPath $log -PathType Leaf)) { throw "Compile log not produced: $log" }
$resultLine = Get-Content -LiteralPath $log | Where-Object { $_ -match "Result:" } | Select-Object -Last 1
if(!$resultLine -or $resultLine -notmatch "0 errors, 0 warnings") {
   throw "Compile failed or produced warnings: $resultLine"
}
if(!(Test-Path -LiteralPath $compiledBinary -PathType Leaf)) { throw "Compiled binary missing: $compiledBinary" }
if((Get-OptionalHash $installedSource) -ne $preInstalledSourceHash -or
   (Get-OptionalHash $installedBinary) -ne $preInstalledBinaryHash) {
   throw "Isolated compile changed the installed frozen source or binary."
}
foreach($terminalId in $terminalIds) {
   if(!(Get-Process -Id $terminalId -ErrorAction SilentlyContinue)) {
      throw "Isolated compile interrupted a pre-existing terminal process."
   }
}

[pscustomobject]@{
   Source = $source
   SourceSha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
   Binary = $compiledBinary
   BinarySha256 = (Get-FileHash -LiteralPath $compiledBinary -Algorithm SHA256).Hash
   Log = $log
   Result = $resultLine
   PreservedTerminalProcesses = $terminalIds.Count
   InstalledFrozenArtifactsUnchanged = $true
}
