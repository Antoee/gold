param(
   [string]$WorkDir = "work",
   [string]$OutCsv = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$OutMarkdown = "outputs\MT5_LOCAL_SAFETY_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$mt5ProcessNames = @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")

function Add-Result {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [Parameter(Mandatory = $true)][string]$Area,
      [Parameter(Mandatory = $true)][string]$Check,
      [Parameter(Mandatory = $true)][bool]$Passed,
      [Parameter(Mandatory = $true)][string]$Evidence,
      [Parameter(Mandatory = $true)][string]$Remediation
   )

   $Rows.Add([pscustomobject]@{
      Area = $Area
      Check = $Check
      Passed = $Passed
      Evidence = $Evidence
      Remediation = $Remediation
   }) | Out-Null
}

function Contains-Text {
   param(
      [string]$Text,
      [Parameter(Mandatory = $true)][string]$Needle
   )
   if($null -eq $Text) { return $false }
   return $Text.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Read-TextSafe {
   param([string]$Path)
   if(Test-Path -LiteralPath $Path) { return Get-Content -LiteralPath $Path -Raw }
   return ""
}

if(!(Test-Path -LiteralPath $WorkDir)) {
   throw "Work directory not found: $WorkDir"
}

$rows = New-Object System.Collections.Generic.List[object]
$unlockPath = Join-Path $WorkDir "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenDesktopAckPath = Join-Path $WorkDir "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
$hardLockPath = Join-Path $WorkDir "MT5_LOCAL_LAUNCH_DISABLED.lock"
$quietStopPath = Join-Path $WorkDir "STOP_MT5_FOCUS_WATCHDOG"
$guardPath = Join-Path $WorkDir "assert_mt5_launch_allowed.ps1"
$helperPath = Join-Path $WorkDir "mt5_background_helpers.ps1"
$stopHelperPath = Join-Path $WorkDir "stop_mt5_stray_processes.ps1"
$watchdogPath = Join-Path $WorkDir "mt5_focus_watchdog.ps1"
$offlineRefreshPath = Join-Path $WorkDir "refresh_offline_validation_state.ps1"
$handoffIntegrityPath = "outputs\HANDOFF_CONFIG_INTEGRITY.csv"

$mt5Processes = @(Get-Process -Name $mt5ProcessNames -ErrorAction SilentlyContinue)
$mt5Evidence = if($mt5Processes.Count -eq 0) { "No matching process found." } else { (($mt5Processes | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join "; ") }
Add-Result $rows "Runtime" "No MT5/MetaEditor process is running" ($mt5Processes.Count -eq 0) `
   $mt5Evidence `
   "Stop terminal64, metatester64, and MetaEditor before continuing offline work."

$envFlag = [string]$env:ALLOW_MT5_FOCUS_RISK
$envEvidence = if([string]::IsNullOrWhiteSpace($envFlag)) { "Environment variable is empty." } else { "ALLOW_MT5_FOCUS_RISK=$envFlag" }
Add-Result $rows "Runtime" "ALLOW_MT5_FOCUS_RISK is not enabled" ($envFlag -ne "1") `
   $envEvidence `
   "Unset ALLOW_MT5_FOCUS_RISK unless the user explicitly accepts focus risk for a controlled local MT5 run."

$hiddenDesktopEnvFlag = [string]$env:ALLOW_MT5_HIDDEN_DESKTOP_ACK
$hiddenDesktopEnvEvidence = if([string]::IsNullOrWhiteSpace($hiddenDesktopEnvFlag)) { "Environment variable is empty." } else { "ALLOW_MT5_HIDDEN_DESKTOP_ACK=$hiddenDesktopEnvFlag" }
Add-Result $rows "Runtime" "ALLOW_MT5_HIDDEN_DESKTOP_ACK is not enabled" ($hiddenDesktopEnvFlag -ne "1") `
   $hiddenDesktopEnvEvidence `
   "Unset ALLOW_MT5_HIDDEN_DESKTOP_ACK unless the user explicitly accepts focus risk for a controlled local MT5 run."

Add-Result $rows "Runtime" "Unlock file is absent" (!(Test-Path -LiteralPath $unlockPath)) `
   $unlockPath `
   "Remove work\ALLOW_MT5_LOCAL_LAUNCH.unlock unless a controlled local MT5 run is intentionally allowed."

Add-Result $rows "Runtime" "Hidden desktop ack file is absent" (!(Test-Path -LiteralPath $hiddenDesktopAckPath)) `
   $hiddenDesktopAckPath `
   "Remove work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock unless a controlled local MT5 run is intentionally allowed."

Add-Result $rows "Runtime" "Hard local launch lock is present" (Test-Path -LiteralPath $hardLockPath) `
   $hardLockPath `
   "Restore work\MT5_LOCAL_LAUNCH_DISABLED.lock while local MT5 can steal focus on this PC."

$quietStopExists = Test-Path -LiteralPath $quietStopPath
Add-Result $rows "Runtime" "Quiet PC mode stop marker status is recorded" $true `
   "Present: $quietStopExists; path: $quietStopPath" `
   "Create work\STOP_MT5_FOCUS_WATCHDOG while the user needs no resident watchdog or visible helper process."

$guardExists = Test-Path -LiteralPath $guardPath
$guardText = Read-TextSafe $guardPath
Add-Result $rows "Guard" "Launch guard script exists" $guardExists $guardPath "Restore work\assert_mt5_launch_allowed.ps1."
Add-Result $rows "Guard" "Launch guard has broad MT5 process list" ((Contains-Text $guardText 'terminal64') -and (Contains-Text $guardText 'metatester64') -and (Contains-Text $guardText 'MetaEditor') -and (Contains-Text $guardText 'terminal') -and (Contains-Text $guardText 'metatester')) $guardPath "Guard must stop terminal/metatester/MetaEditor variants."
Add-Result $rows "Guard" "Launch guard requires env flag" (Contains-Text $guardText 'ALLOW_MT5_FOCUS_RISK') $guardPath "Guard must require ALLOW_MT5_FOCUS_RISK=1."
Add-Result $rows "Guard" "Launch guard requires hidden desktop ack" (Contains-Text $guardText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK') $guardPath "Guard must require ALLOW_MT5_HIDDEN_DESKTOP_ACK=1."
Add-Result $rows "Guard" "Launch guard requires unlock file" (Contains-Text $guardText 'ALLOW_MT5_LOCAL_LAUNCH.unlock') $guardPath "Guard must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock."
Add-Result $rows "Guard" "Launch guard requires hidden desktop ack file" (Contains-Text $guardText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock') $guardPath "Guard must require work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock."
Add-Result $rows "Guard" "Launch guard honors hard lock" (Contains-Text $guardText 'MT5_LOCAL_LAUNCH_DISABLED.lock') $guardPath "Guard must stop when work\MT5_LOCAL_LAUNCH_DISABLED.lock exists."
Add-Result $rows "Guard" "Launch guard stops stray MT5 processes" ((Contains-Text $guardText 'Stop-MT5StrayProcesses') -and (Contains-Text $guardText 'Stop-Process') -and (Contains-Text $guardText 'terminal64') -and (Contains-Text $guardText 'metatester64') -and (Contains-Text $guardText 'metaeditor64')) $guardPath "Guard should stop stray MT5/MetaEditor processes before throwing."
Add-Result $rows "Guard" "Launch guard fails closed" (Contains-Text $guardText 'throw') $guardPath "Guard must throw when local launch is not allowed."

$helperExists = Test-Path -LiteralPath $helperPath
$helperText = Read-TextSafe $helperPath
Add-Result $rows "Helper" "Background helper exists" $helperExists $helperPath "Restore work\mt5_background_helpers.ps1."
Add-Result $rows "Helper" "Start-MT5Hidden requires env flag" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'ALLOW_MT5_FOCUS_RISK')) $helperPath "Start-MT5Hidden must require ALLOW_MT5_FOCUS_RISK=1."
Add-Result $rows "Helper" "Start-MT5Hidden requires hidden desktop ack" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK')) $helperPath "Start-MT5Hidden must require ALLOW_MT5_HIDDEN_DESKTOP_ACK=1."
Add-Result $rows "Helper" "Start-MT5Hidden requires unlock file" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'ALLOW_MT5_LOCAL_LAUNCH.unlock')) $helperPath "Start-MT5Hidden must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock."
Add-Result $rows "Helper" "Start-MT5Hidden requires hidden desktop ack file" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock')) $helperPath "Start-MT5Hidden must require work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock."
Add-Result $rows "Helper" "Start-MT5Hidden honors hard lock" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'MT5_LOCAL_LAUNCH_DISABLED.lock')) $helperPath "Start-MT5Hidden must stop when work\MT5_LOCAL_LAUNCH_DISABLED.lock exists."
Add-Result $rows "Helper" "Background helper has low-impact controls" ((Contains-Text $helperText 'Set-MT5ProcessMute') -and (Contains-Text $helperText 'Set-MT5ProcessLowImpact') -and (Contains-Text $helperText 'Hide-MT5Windows')) $helperPath "Keep mute, lower-priority, and hide-window controls in the helper."

$stopHelperText = Read-TextSafe $stopHelperPath
Add-Result $rows "Cleanup" "Stop-stray helper exists" (Test-Path -LiteralPath $stopHelperPath) $stopHelperPath "Restore work\stop_mt5_stray_processes.ps1."
Add-Result $rows "Cleanup" "Stop-stray helper does not launch MT5" ((Contains-Text $stopHelperText 'Stop-Process') -and !(Contains-Text $stopHelperText 'Start-Process') -and !(Contains-Text $stopHelperText 'Start-MT5Hidden')) $stopHelperPath "Cleanup helper must only stop existing processes."

$offlineRefreshText = Read-TextSafe $offlineRefreshPath
Add-Result $rows "Offline refresh" "Offline refresh script exists" (Test-Path -LiteralPath $offlineRefreshPath) $offlineRefreshPath "Restore work\refresh_offline_validation_state.ps1."
Add-Result $rows "Offline refresh" "Offline refresh child steps run hidden" ((Contains-Text $offlineRefreshText 'function Invoke-QuietPowerShell') -and (Contains-Text $offlineRefreshText 'Start-Process') -and (Contains-Text $offlineRefreshText '-WindowStyle Hidden') -and (Contains-Text $offlineRefreshText '-RedirectStandardOutput') -and (Contains-Text $offlineRefreshText '-RedirectStandardError')) $offlineRefreshPath "Offline refresh child PowerShell steps must run hidden and write logs."
Add-Result $rows "Offline refresh" "Offline refresh avoids direct visible child shells" (!(Contains-Text $offlineRefreshText 'powershell -NoProfile') -and !(Contains-Text $offlineRefreshText 'powershell -ExecutionPolicy') -and !(Contains-Text $offlineRefreshText '& powershell')) $offlineRefreshPath "Replace direct powershell child calls with Invoke-QuietPowerShell."
Add-Result $rows "Offline refresh" "Offline refresh does not launch MT5" (!(Contains-Text $offlineRefreshText 'Start-MT5Hidden') -and !(Contains-Text $offlineRefreshText 'terminal64.exe') -and !(Contains-Text $offlineRefreshText 'MetaEditor.exe')) $offlineRefreshPath "Offline refresh must rebuild state only; it must not launch MT5, MetaEditor, or Strategy Tester."

$scriptFiles = @(Get-ChildItem -LiteralPath $WorkDir -Filter "*.ps1" -File)
$runnerFiles = New-Object System.Collections.Generic.List[object]
foreach($file in $scriptFiles) {
   if($file.Name -in @("assert_mt5_launch_allowed.ps1", "mt5_background_helpers.ps1", "mt5_focus_watchdog.ps1", "stop_mt5_focus_watchdog.ps1", "audit_mt5_local_safety.ps1", "stop_mt5_stray_processes.ps1")) {
      continue
   }

   $text = Get-Content -LiteralPath $file.FullName -Raw
   $looksLikeRunner = (Contains-Text $text 'terminal64.exe') -or (Contains-Text $text 'terminal.exe') -or (Contains-Text $text 'Start-MT5Hidden') -or (Contains-Text $text '/config:')
   if(!$looksLikeRunner) {
      continue
   }

   $hasGuard = (Contains-Text $text 'assert_mt5_launch_allowed.ps1')
   $usesHiddenHelper = (Contains-Text $text 'Start-MT5Hidden')
   $usesRawTerminalStart = ((Contains-Text $text 'Start-Process') -and ((Contains-Text $text 'terminal64') -or (Contains-Text $text 'terminal.exe'))) -or ((Contains-Text $text 'CreateProcess') -and ((Contains-Text $text 'terminal64') -or (Contains-Text $text 'terminal.exe')))
   $runnerFiles.Add([pscustomobject]@{
      File = $file.Name
      HasGuard = $hasGuard
      UsesHiddenHelper = $usesHiddenHelper
      UsesRawTerminalStart = $usesRawTerminalStart
   }) | Out-Null
}

$unguarded = @($runnerFiles | Where-Object { -not $_.HasGuard })
$rawStarts = @($runnerFiles | Where-Object { $_.UsesRawTerminalStart })
$runnerEvidence = "Runner scripts checked: $($runnerFiles.Count); unguarded: $($unguarded.Count)"
if($unguarded.Count -gt 0) { $runnerEvidence += "; " + (($unguarded | Select-Object -ExpandProperty File) -join ", ") }
Add-Result $rows "Runner scripts" "All MT5 runner scripts source the launch guard" ($unguarded.Count -eq 0) $runnerEvidence "Add . (Join-Path `$PSScriptRoot \"assert_mt5_launch_allowed.ps1\") near the top of each runner."

$rawEvidence = "Raw terminal launch matches: $($rawStarts.Count)"
if($rawStarts.Count -gt 0) { $rawEvidence += "; " + (($rawStarts | Select-Object -ExpandProperty File) -join ", ") }
Add-Result $rows "Runner scripts" "No runner bypasses Start-MT5Hidden with raw terminal launch" ($rawStarts.Count -eq 0) $rawEvidence "Route tester launches through Start-MT5Hidden and the guard."

$watchdogExists = Test-Path -LiteralPath $watchdogPath
$watchdogText = Read-TextSafe $watchdogPath
Add-Result $rows "Watchdog" "Watchdog script exists" $watchdogExists $watchdogPath "Restore work\mt5_focus_watchdog.ps1."
Add-Result $rows "Watchdog" "Watchdog targets MT5 and MetaEditor" ((Contains-Text $watchdogText 'terminal64') -and (Contains-Text $watchdogText 'metatester64') -and (Contains-Text $watchdogText 'MetaEditor')) $watchdogPath "Watchdog must stop terminal64, metatester64, and MetaEditor."
Add-Result $rows "Watchdog" "Watchdog default is bounded for quiet PC use" ((Contains-Text $watchdogText '[int]$MonitorSeconds = 5') -and (Contains-Text $watchdogText '[int]$PollMilliseconds = 250')) $watchdogPath "Keep the default watchdog run short unless the user explicitly asks for a resident safety net."

try {
   $watchdogProcesses = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*mt5_focus_watchdog.ps1*' })
} catch {
   $watchdogProcesses = @()
}
$watchdogProcessEvidence = if($watchdogProcesses.Count -eq 0) { "No running watchdog process detected by CIM; script is present." } else { (($watchdogProcesses | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join "; ") }
Add-Result $rows "Watchdog" "No resident watchdog process during quiet PC use" ($watchdogProcesses.Count -eq 0) `
   $watchdogProcessEvidence `
   "Stop work\mt5_focus_watchdog.ps1 and leave work\STOP_MT5_FOCUS_WATCHDOG in place during normal PC use."

if(Test-Path -LiteralPath $handoffIntegrityPath) {
   $handoffRows = @(Import-Csv -LiteralPath $handoffIntegrityPath)
   $handoffFailed = @($handoffRows | Where-Object { [string]$_.Passed -ne "True" -and [string]$_.Status -ne "PASS" })
   Add-Result $rows "Handoff" "Latest handoff integrity has no failures" ($handoffFailed.Count -eq 0) "Rows: $($handoffRows.Count); failed: $($handoffFailed.Count); $handoffIntegrityPath" "Rebuild and audit handoff configs before running them externally."
} else {
   Add-Result $rows "Handoff" "Latest handoff integrity exists" $false $handoffIntegrityPath "Run work\audit_handoff_config_integrity.ps1 after building a handoff package."
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation

$failed = @($rows | Where-Object { -not $_.Passed })
$passCount = $rows.Count - $failed.Count
$overall = if($failed.Count -eq 0) { "PASS" } else { "FAIL" }

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# MT5 Local Safety Audit") | Out-Null
$md.Add("") | Out-Null
$md.Add("Offline audit only. This script does not launch MT5.") | Out-Null
$md.Add("") | Out-Null
$md.Add("- Overall: **$overall**") | Out-Null
$md.Add("- Checks passed: $passCount / $($rows.Count)") | Out-Null
$md.Add("- MT5 processes running: $($mt5Processes.Count)") | Out-Null
$md.Add("- Runner scripts checked: $($runnerFiles.Count)") | Out-Null
$md.Add("- Unguarded runner scripts: $($unguarded.Count)") | Out-Null
$md.Add("- Raw terminal launch bypasses: $($rawStarts.Count)") | Out-Null
$md.Add("- Resident watchdog processes: $($watchdogProcesses.Count)") | Out-Null
$md.Add("") | Out-Null
$md.Add("## Checks") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Area | Check | Passed | Evidence | Remediation |") | Out-Null
$md.Add("|---|---|---|---|---|") | Out-Null
foreach($row in $rows) {
   $evidence = ([string]$row.Evidence) -replace '\|', '/'
   $remediation = ([string]$row.Remediation) -replace '\|', '/'
   $md.Add("| $($row.Area) | $($row.Check) | $($row.Passed) | $evidence | $remediation |") | Out-Null
}

Set-Content -LiteralPath $OutMarkdown -Value $md -Encoding UTF8

[pscustomobject]@{
   Overall = $overall
   Checks = $rows.Count
   Passed = $passCount
   Failed = $failed.Count
   RunnerScripts = $runnerFiles.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}

if($failed.Count -gt 0) { exit 1 }
