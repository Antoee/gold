$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$helperPath = Join-Path $PSScriptRoot "mt5_background_helpers.ps1"
$hardLockPath = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockPath = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckPath = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
# Static audit marker: this smoke test intentionally exercises
# mt5_background_helpers.ps1 while assert_mt5_launch_allowed.ps1 policy is locked.

if(!(Test-Path -LiteralPath $helperPath)) {
   throw "Missing helper: $helperPath"
}

New-Item -ItemType File -Path $hardLockPath -Force | Out-Null
Remove-Item -LiteralPath $unlockPath,$hiddenAckPath -Force -ErrorAction SilentlyContinue

$before = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

. $helperPath

$blocked = $false
try {
   Start-MT5Hidden -TerminalPath "C:\Program Files\MetaTrader 5\terminal64.exe" -ConfigPath (Join-Path $repo "work\nonexistent.ini") | Out-Null
}
catch {
   $blocked = $_.Exception.Message -like "*hard-locked*"
}

$after = @(Get-Process -Name terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue)

if(!$blocked) {
   throw "Start-MT5Hidden did not fail closed while MT5_LOCAL_LAUNCH_DISABLED.lock is present."
}

if($after.Count -gt $before.Count) {
   throw "Start-MT5Hidden created an MT5-family process while locked."
}

"MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS"
