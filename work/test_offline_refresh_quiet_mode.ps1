param(
   [string]$RepoRoot = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
   param(
      [bool]$Condition,
      [string]$Message
   )
   if(!$Condition) { throw $Message }
}

function Contains-Text {
   param([string]$Text, [string]$Needle)
   if($null -eq $Text) { return $false }
   return $Text.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

$refreshPath = Join-Path $RepoRoot "work\refresh_offline_validation_state.ps1"
Assert-True (Test-Path -LiteralPath $refreshPath) "Offline refresh script is missing."

$text = Get-Content -LiteralPath $refreshPath -Raw

Assert-True (Contains-Text $text "function Invoke-QuietPowerShell") "Offline refresh must use Invoke-QuietPowerShell."
Assert-True (Contains-Text $text "Start-Process") "Offline refresh must launch child steps through Start-Process."
Assert-True (Contains-Text $text "-WindowStyle Hidden") "Offline refresh child PowerShell processes must run hidden."
Assert-True (Contains-Text $text "-RedirectStandardOutput") "Offline refresh should capture child stdout to logs."
Assert-True (Contains-Text $text "-RedirectStandardError") "Offline refresh should capture child stderr to logs."
Assert-True (Contains-Text $text "outputs\offline_refresh_logs") "Offline refresh should write child logs under outputs\offline_refresh_logs."

Assert-True (!(Contains-Text $text "powershell -NoProfile")) "Offline refresh must not use direct visible powershell -NoProfile calls."
Assert-True (!(Contains-Text $text "powershell -ExecutionPolicy")) "Offline refresh must not use direct visible powershell -ExecutionPolicy calls."
Assert-True (!(Contains-Text $text "& powershell")) "Offline refresh must not invoke powershell directly."

$hiddenLauncher = "Start-MT5" + "Hidden"
Assert-True (!(Contains-Text $text $hiddenLauncher)) "Offline refresh must not launch MT5."
$terminalExe = ("termi" + "nal64") + ".exe"
$metaEditorExe = "MetaEditor" + ".exe"
Assert-True (!(Contains-Text $text $terminalExe)) "Offline refresh must not reference $terminalExe."
Assert-True (!(Contains-Text $text $metaEditorExe)) "Offline refresh must not reference $metaEditorExe."

"OFFLINE_REFRESH_QUIET_MODE_SMOKE_PASS"
