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
      [string]$Area,
      [string]$Check,
      [bool]$Passed,
      [string]$Evidence,
      [string]$Remediation
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
   param([string]$Text, [string]$Needle)
   if($null -eq $Text) { return $false }
   return $Text.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Read-TextSafe {
   param([string]$Path)
   if(Test-Path -LiteralPath $Path) { return Get-Content -LiteralPath $Path -Raw }
   return ""
}

if(!(Test-Path -LiteralPath $WorkDir)) { throw "Work directory not found: $WorkDir" }

$rows = New-Object System.Collections.Generic.List[object]
$unlockPath = Join-Path $WorkDir "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenDesktopAckPath = Join-Path $WorkDir "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"
$hardLockPath = Join-Path $WorkDir "MT5_LOCAL_LAUNCH_DISABLED.lock"
$guardPath = Join-Path $WorkDir "assert_mt5_launch_allowed.ps1"
$helperPath = Join-Path $WorkDir "mt5_background_helpers.ps1"
$stopHelperPath = Join-Path $WorkDir "stop_mt5_stray_processes.ps1"
$watchdogPath = Join-Path $WorkDir "mt5_focus_watchdog.ps1"

$mt5Processes = @(Get-Process -Name $mt5ProcessNames -ErrorAction SilentlyContinue)
$mt5Evidence = if($mt5Processes.Count -eq 0) { "No matching process found." } else { (($mt5Processes | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join "; ") }
Add-Result $rows "Runtime" "No MT5/MetaEditor process is running" ($mt5Processes.Count -eq 0) $mt5Evidence "Run work\stop_mt5_stray_processes.ps1 or stop terminal/metatester/MetaEditor before continuing offline work."

$envFlag = [string]$env:ALLOW_MT5_FOCUS_RISK
$hiddenEnvFlag = [string]$env:ALLOW_MT5_HIDDEN_DESKTOP_ACK
Add-Result $rows "Runtime" "ALLOW_MT5_FOCUS_RISK is not enabled" ($envFlag -ne "1") $(if([string]::IsNullOrWhiteSpace($envFlag)) { "Environment variable is empty." } else { "ALLOW_MT5_FOCUS_RISK=$envFlag" }) "Unset ALLOW_MT5_FOCUS_RISK unless the user explicitly accepts focus risk."
Add-Result $rows "Runtime" "ALLOW_MT5_HIDDEN_DESKTOP_ACK is not enabled" ($hiddenEnvFlag -ne "1") $(if([string]::IsNullOrWhiteSpace($hiddenEnvFlag)) { "Environment variable is empty." } else { "ALLOW_MT5_HIDDEN_DESKTOP_ACK=$hiddenEnvFlag" }) "Unset ALLOW_MT5_HIDDEN_DESKTOP_ACK unless the user explicitly accepts focus risk."
Add-Result $rows "Runtime" "Unlock file is absent" (!(Test-Path -LiteralPath $unlockPath)) $unlockPath "Remove work\ALLOW_MT5_LOCAL_LAUNCH.unlock unless a controlled local MT5 run is intentionally allowed."
Add-Result $rows "Runtime" "Hidden desktop ack file is absent" (!(Test-Path -LiteralPath $hiddenDesktopAckPath)) $hiddenDesktopAckPath "Remove work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock unless a controlled local MT5 run is intentionally allowed."
Add-Result $rows "Runtime" "Hard local launch lock is present" (Test-Path -LiteralPath $hardLockPath) $hardLockPath "Restore work\MT5_LOCAL_LAUNCH_DISABLED.lock while local MT5 can steal focus on this PC."

$guardText = Read-TextSafe $guardPath
Add-Result $rows "Guard" "Launch guard script exists" (Test-Path -LiteralPath $guardPath) $guardPath "Restore work\assert_mt5_launch_allowed.ps1."
Add-Result $rows "Guard" "Launch guard has broad MT5 process list" ((Contains-Text $guardText 'terminal64') -and (Contains-Text $guardText 'metatester64') -and (Contains-Text $guardText 'MetaEditor') -and (Contains-Text $guardText 'terminal') -and (Contains-Text $guardText 'metatester')) $guardPath "Guard must stop terminal/metatester/MetaEditor variants."
Add-Result $rows "Guard" "Launch guard honors hard lock" (Contains-Text $guardText 'MT5_LOCAL_LAUNCH_DISABLED.lock') $guardPath "Guard must throw while the hard lock exists."
Add-Result $rows "Guard" "Launch guard requires env flags and unlock files" ((Contains-Text $guardText 'ALLOW_MT5_FOCUS_RISK') -and (Contains-Text $guardText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK') -and (Contains-Text $guardText 'ALLOW_MT5_LOCAL_LAUNCH.unlock') -and (Contains-Text $guardText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock')) $guardPath "Guard must require both env flags and both unlock files."
Add-Result $rows "Guard" "Launch guard stops stray MT5 processes before failing" ((Contains-Text $guardText 'Stop-MT5StrayProcesses') -and (Contains-Text $guardText 'Stop-Process') -and (Contains-Text $guardText 'throw')) $guardPath "Guard should stop stray MT5 processes and fail closed."

$helperText = Read-TextSafe $helperPath
Add-Result $rows "Helper" "Background helper exists" (Test-Path -LiteralPath $helperPath) $helperPath "Restore work\mt5_background_helpers.ps1."
Add-Result $rows "Helper" "Start-MT5Hidden honors hard lock" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'MT5_LOCAL_LAUNCH_DISABLED.lock')) $helperPath "Start-MT5Hidden must stop while the hard lock exists."
Add-Result $rows "Helper" "Start-MT5Hidden requires env flags and unlock files" ((Contains-Text $helperText 'ALLOW_MT5_FOCUS_RISK') -and (Contains-Text $helperText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK') -and (Contains-Text $helperText 'ALLOW_MT5_LOCAL_LAUNCH.unlock') -and (Contains-Text $helperText 'ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock')) $helperPath "Start-MT5Hidden must require both env flags and both unlock files."
Add-Result $rows "Helper" "Background helper has cleanup and low-impact controls" ((Contains-Text $helperText 'Stop-MT5LocalProcesses') -and (Contains-Text $helperText 'Set-MT5ProcessMute') -and (Contains-Text $helperText 'Set-MT5ProcessLowImpact') -and (Contains-Text $helperText 'Hide-MT5Windows')) $helperPath "Keep cleanup, mute, lower-priority, and hide-window controls in the helper."

$stopHelperText = Read-TextSafe $stopHelperPath
Add-Result $rows "Cleanup" "Stop-stray helper exists" (Test-Path -LiteralPath $stopHelperPath) $stopHelperPath "Restore work\stop_mt5_stray_processes.ps1."
Add-Result $rows "Cleanup" "Stop-stray helper does not launch MT5" ((Contains-Text $stopHelperText 'Stop-Process') -and !(Contains-Text $stopHelperText 'Start-Process') -and !(Contains-Text $stopHelperText 'Start-MT5Hidden')) $stopHelperPath "Cleanup helper must only stop existing processes."

$scriptFiles = @(Get-ChildItem -LiteralPath $WorkDir -Filter "*.ps1" -File)
$runnerFiles = New-Object System.Collections.Generic.List[object]
foreach($file in $scriptFiles) {
   if($file.Name -in @("assert_mt5_launch_allowed.ps1", "mt5_background_helpers.ps1", "mt5_focus_watchdog.ps1", "stop_mt5_focus_watchdog.ps1", "audit_mt5_local_safety.ps1", "stop_mt5_stray_processes.ps1")) { continue }
   $text = Get-Content -LiteralPath $file.FullName -Raw
   $looksLikeRunner = (Contains-Text $text 'terminal64.exe') -or (Contains-Text $text 'terminal.exe') -or (Contains-Text $text 'Start-MT5Hidden') -or (Contains-Text $text '/config:')
   if(!$looksLikeRunner) { continue }
   $runnerFiles.Add([pscustomobject]@{
      File = $file.Name
      HasGuard = (Contains-Text $text 'assert_mt5_launch_allowed.ps1')
      UsesRawTerminalStart = (((Contains-Text $text 'Start-Process') -and ((Contains-Text $text 'terminal64') -or (Contains-Text $text 'terminal.exe'))) -or ((Contains-Text $text 'CreateProcess') -and ((Contains-Text $text 'terminal64') -or (Contains-Text $text 'terminal.exe'))))
   }) | Out-Null
}

$unguarded = @($runnerFiles | Where-Object { -not $_.HasGuard })
$rawStart = @($runnerFiles | Where-Object { $_.UsesRawTerminalStart })
Add-Result $rows "Runner scripts" "All MT5 runner scripts source the launch guard" ($unguarded.Count -eq 0) "Runner scripts checked: $($runnerFiles.Count); unguarded: $($unguarded.Count)" "Add the launch guard near the top of each runner."
Add-Result $rows "Runner scripts" "No runner bypasses Start-MT5Hidden with raw terminal launch" ($rawStart.Count -eq 0) "Raw terminal launch matches: $($rawStart.Count)" "Route tester launches through Start-MT5Hidden and the guard."

$watchdogText = Read-TextSafe $watchdogPath
Add-Result $rows "Watchdog" "Watchdog script exists" (Test-Path -LiteralPath $watchdogPath) $watchdogPath "Restore work\mt5_focus_watchdog.ps1 if local cleanup monitoring is needed."
Add-Result $rows "Watchdog" "Watchdog targets MT5 and MetaEditor" ((Contains-Text $watchdogText 'terminal64') -and (Contains-Text $watchdogText 'metatester64') -and (Contains-Text $watchdogText 'MetaEditor')) $watchdogPath "Watchdog must stop terminal64, metatester64, and MetaEditor."
Add-Result $rows "Watchdog" "Watchdog default is bounded for quiet PC use" ((Contains-Text $watchdogText '[int]$MonitorSeconds = 5') -and (Contains-Text $watchdogText '[int]$PollMilliseconds = 250')) $watchdogPath "Keep the default watchdog run short unless the user explicitly asks for a resident safety net."

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
$md.Add("- Runner scripts checked: $($runnerFiles.Count)") | Out-Null
$md.Add("- MT5 processes running: $($mt5Processes.Count)") | Out-Null
$md.Add("- Hard lock present: $((Test-Path -LiteralPath $hardLockPath))") | Out-Null
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
