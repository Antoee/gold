param(
   [string]$SourcePath = "work\Professional_XAUUSD_Transferable_Portfolio.mq5",
   [string]$MetaEditorPath = "C:\Program Files\MetaTrader 5\MetaEditor64.exe",
   [string]$CompileLogPath = "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_COMPILE.log",
   [int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "test_transferable_portfolio_forward_demo_package.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Join-Path $repo $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$expectedSourceHash = "5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3"
if($sourceHash -ne $expectedSourceHash) { throw "Frozen source identity changed: $sourceHash" }
if(!(Test-Path -LiteralPath $MetaEditorPath)) { throw "MetaEditor missing: $MetaEditorPath" }
if(@(Get-Process terminal,terminal64,metatester,metatester64 -ErrorAction SilentlyContinue).Count -ne 0) {
   throw "Refusing additive install while MT5 is running."
}

$terminalRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
$experts = Join-Path $terminalRoot "MQL5\Experts"
$targetSource = Join-Path $experts "Professional_XAUUSD_Transferable_Portfolio.mq5"
$targetBinary = Join-Path $experts "Professional_XAUUSD_Transferable_Portfolio.ex5"
$logFull = Join-Path $repo $CompileLogPath
New-Item -ItemType Directory -Path $experts -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination $targetSource -Force
Remove-Item -LiteralPath $logFull -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $targetBinary -Force -ErrorAction SilentlyContinue

$arguments = "/compile:`"$targetSource`" /log:`"$logFull`""
$processId = [Mt5Audio.HiddenProcess]::StartHidden($MetaEditorPath, $arguments)
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
   Start-Sleep -Milliseconds 500
   Set-MT5BackgroundSafe
   $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
} while($process -and (Get-Date) -lt $deadline)
Get-Process MetaEditor,metaeditor64 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

if(!(Test-Path -LiteralPath $logFull)) { throw "Forward compile log not produced." }
$resultLine = Get-Content -LiteralPath $logFull -Encoding Unicode | Where-Object { $_ -match 'Result:' } | Select-Object -Last 1
if($resultLine -notmatch '0 errors, 0 warnings') { throw "Forward compile failed: $resultLine" }
if(!(Test-Path -LiteralPath $targetBinary)) { throw "Forward binary not produced." }
$installedSourceHash = (Get-FileHash -LiteralPath $targetSource -Algorithm SHA256).Hash
if($installedSourceHash -ne $expectedSourceHash) { throw "Installed source identity mismatch." }

$status = [pscustomobject]@{
   Status="INSTALLED_NOT_ATTACHED"
   InstalledSource=$targetSource
   InstalledBinary=$targetBinary
   SourceSha256=$installedSourceHash
   BinarySha256=(Get-FileHash -LiteralPath $targetBinary -Algorithm SHA256).Hash
   ProfileSha256=(Get-FileHash -LiteralPath (Join-Path $repo "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set") -Algorithm SHA256).Hash
   CompileResult=$resultLine
   RealAccountTradingDisabled=$true
}
$status | Export-Csv -LiteralPath (Join-Path $repo "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_INSTALL_STATUS.csv") -NoTypeInformation -Encoding ASCII
@(
   "# Transferable Portfolio Forward Demo Install", "",
   "- Status: **INSTALLED_NOT_ATTACHED**",
   "- Source SHA-256: ``$($status.SourceSha256)``",
   "- Binary SHA-256: ``$($status.BinarySha256)``",
   "- Forward profile SHA-256: ``$($status.ProfileSha256)``",
   "- Compile: ``$resultLine``",
   "- Existing Professional_XAUUSD_EA source/binary were not replaced.",
   "- Real-account trading remains disabled."
) | Set-Content -LiteralPath (Join-Path $repo "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_INSTALL_STATUS.md") -Encoding ASCII
$status
