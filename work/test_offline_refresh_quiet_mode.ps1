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
Assert-True (Contains-Text $text "ProcessStartInfo") "Offline refresh must launch child steps through ProcessStartInfo."
Assert-True (Contains-Text $text "CreateNoWindow") "Offline refresh child PowerShell processes must use CreateNoWindow."
Assert-True (Contains-Text $text "ProcessWindowStyle]::Hidden") "Offline refresh child PowerShell processes must request hidden windows."
Assert-True (Contains-Text $text "RedirectStandardOutput = `$true") "Offline refresh should capture child stdout to logs."
Assert-True (Contains-Text $text "RedirectStandardError = `$true") "Offline refresh should capture child stderr to logs."
Assert-True (Contains-Text $text "outputs\offline_refresh_logs") "Offline refresh should write child logs under outputs\offline_refresh_logs."

Assert-True (!(Contains-Text $text "Start-Process")) "Offline refresh must not use Start-Process because it can blink a window."
Assert-True (!(Contains-Text $text "powershell -NoProfile")) "Offline refresh must not use direct visible powershell -NoProfile calls."
Assert-True (!(Contains-Text $text "powershell -ExecutionPolicy")) "Offline refresh must not use direct visible powershell -ExecutionPolicy calls."
Assert-True (!(Contains-Text $text "& powershell")) "Offline refresh must not invoke powershell directly."

$hiddenLauncher = "Start-MT5" + "Hidden"
Assert-True (!(Contains-Text $text $hiddenLauncher)) "Offline refresh must not launch MT5."
$terminalExe = ("termi" + "nal64") + ".exe"
$metaEditorExe = "MetaEditor" + ".exe"
Assert-True (!(Contains-Text $text $terminalExe)) "Offline refresh must not reference $terminalExe."
Assert-True (!(Contains-Text $text $metaEditorExe)) "Offline refresh must not reference $metaEditorExe."

$externalImportPath = Join-Path $RepoRoot "work\import_external_mt5_validation_package_reports.ps1"
Assert-True (Test-Path -LiteralPath $externalImportPath) "External package report importer is missing."

$externalImportText = Get-Content -LiteralPath $externalImportPath -Raw
Assert-True (Contains-Text $externalImportText "ProcessStartInfo") "External report importer must launch collector through ProcessStartInfo."
Assert-True (Contains-Text $externalImportText "CreateNoWindow") "External report importer child PowerShell process must use CreateNoWindow."
Assert-True (Contains-Text $externalImportText "ProcessWindowStyle]::Hidden") "External report importer child PowerShell process must request hidden windows."
Assert-True (Contains-Text $externalImportText "RedirectStandardOutput = `$true") "External report importer should capture child stdout to logs."
Assert-True (Contains-Text $externalImportText "RedirectStandardError = `$true") "External report importer should capture child stderr to logs."
Assert-True (!(Contains-Text $externalImportText "Start-Process")) "External report importer must not use Start-Process because it can blink a window."
Assert-True (!(Contains-Text $externalImportText "& powershell")) "External report importer must not invoke powershell directly."
Assert-True (!(Contains-Text $externalImportText "powershell -NoProfile")) "External report importer must not use direct visible powershell -NoProfile calls."

$preflightPath = Join-Path $RepoRoot "work\build_report_import_preflight.ps1"
Assert-True (Test-Path -LiteralPath $preflightPath) "Report import preflight script is missing."

$preflightText = Get-Content -LiteralPath $preflightPath -Raw
Assert-True (Contains-Text $preflightText "function Invoke-NoWindowPowerShell") "Report preflight must use Invoke-NoWindowPowerShell."
Assert-True (Contains-Text $preflightText "ProcessStartInfo") "Report preflight child smoke tests must launch through ProcessStartInfo."
Assert-True (Contains-Text $preflightText "CreateNoWindow") "Report preflight child smoke tests must use CreateNoWindow."
Assert-True (!(Contains-Text $preflightText "& powershell")) "Report preflight must not invoke powershell directly."
Assert-True (!(Contains-Text $preflightText "powershell -NoProfile")) "Report preflight must not use direct visible powershell -NoProfile calls."

"OFFLINE_REFRESH_QUIET_MODE_SMOKE_PASS"
