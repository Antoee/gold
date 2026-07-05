param(
   [string]$WorkDir = "work",
   [string]$OutCsv = "outputs\MT5_LOCAL_SAFETY_AUDIT.csv",
   [string]$OutMarkdown = "outputs\MT5_LOCAL_SAFETY_AUDIT.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
   param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Needle)
   return $Text.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

if(!(Test-Path -LiteralPath $WorkDir)) { throw "Work directory not found: $WorkDir" }

$rows = New-Object System.Collections.Generic.List[object]
$unlockPath = Join-Path $WorkDir "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$guardPath = Join-Path $WorkDir "assert_mt5_launch_allowed.ps1"
$helperPath = Join-Path $WorkDir "mt5_background_helpers.ps1"
$watchdogPath = Join-Path $WorkDir "mt5_focus_watchdog.ps1"
$handoffIntegrityPath = "outputs\HANDOFF_CONFIG_INTEGRITY.csv"

$mt5Processes = @(Get-Process terminal64,metatester64,MetaEditor -ErrorAction SilentlyContinue)
$mt5Evidence = if($mt5Processes.Count -eq 0) { "No matching process found." } else { (($mt5Processes | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join "; ") }
Add-Result $rows "Runtime" "No MT5/MetaEditor process is running" ($mt5Processes.Count -eq 0) $mt5Evidence "Stop terminal64, metatester64, and MetaEditor before continuing offline work."

$envFlag = [string]$env:ALLOW_MT5_FOCUS_RISK
$envEvidence = if([string]::IsNullOrWhiteSpace($envFlag)) { "Environment variable is empty." } else { "ALLOW_MT5_FOCUS_RISK=$envFlag" }
Add-Result $rows "Runtime" "ALLOW_MT5_FOCUS_RISK is not enabled" ($envFlag -ne "1") $envEvidence "Unset ALLOW_MT5_FOCUS_RISK unless the user explicitly accepts focus risk for a controlled local MT5 run."
Add-Result $rows "Runtime" "Unlock file is absent" (!(Test-Path -LiteralPath $unlockPath)) $unlockPath "Remove work\ALLOW_MT5_LOCAL_LAUNCH.unlock unless a controlled local MT5 run is intentionally allowed."

$guardExists = Test-Path -LiteralPath $guardPath
$guardText = if($guardExists) { Get-Content -LiteralPath $guardPath -Raw } else { "" }
Add-Result $rows "Guard" "Launch guard script exists" $guardExists $guardPath "Restore work\assert_mt5_launch_allowed.ps1."
Add-Result $rows "Guard" "Launch guard requires env flag" (Contains-Text $guardText 'ALLOW_MT5_FOCUS_RISK') $guardPath "Guard must require ALLOW_MT5_FOCUS_RISK=1."
Add-Result $rows "Guard" "Launch guard requires unlock file" (Contains-Text $guardText 'ALLOW_MT5_LOCAL_LAUNCH.unlock') $guardPath "Guard must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock."
Add-Result $rows "Guard" "Launch guard stops stray MT5 processes" ((Contains-Text $guardText 'Get-Process terminal64,metatester64,MetaEditor') -and (Contains-Text $guardText 'Stop-Process')) $guardPath "Guard should stop stray MT5/MetaEditor processes before throwing."
Add-Result $rows "Guard" "Launch guard fails closed" (Contains-Text $guardText 'throw') $guardPath "Guard must throw when local launch is not allowed."

$helperExists = Test-Path -LiteralPath $helperPath
$helperText = if($helperExists) { Get-Content -LiteralPath $helperPath -Raw } else { "" }
Add-Result $rows "Helper" "Background helper exists" $helperExists $helperPath "Restore work\mt5_background_helpers.ps1."
Add-Result $rows "Helper" "Start-MT5Hidden requires env flag" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'ALLOW_MT5_FOCUS_RISK')) $helperPath "Start-MT5Hidden must require ALLOW_MT5_FOCUS_RISK=1."
Add-Result $rows "Helper" "Start-MT5Hidden requires unlock file" ((Contains-Text $helperText 'function Start-MT5Hidden') -and (Contains-Text $helperText 'ALLOW_MT5_LOCAL_LAUNCH.unlock')) $helperPath "Start-MT5Hidden must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock."
Add-Result $rows "Helper" "Background helper has low-impact controls" ((Contains-Text $helperText 'Set-MT5ProcessMute') -and (Contains-Text $helperText 'Set-MT5ProcessLowImpact') -and (Contains-Text $helperText 'Hide-MT5Windows')) $helperPath "Keep mute, lower-priority, and hide-window controls in the helper."

$scriptFiles = @(Get-ChildItem -LiteralPath $WorkDir -Filter "*.ps1" -File)
$runnerFiles = New-Object System.Collections.Generic.List[object]
foreach($file in $scriptFiles) {
   if($file.Name -in @("assert_mt5_launch_allowed.ps1", "mt5_background_helpers.ps1", "mt5_focus_watchdog.ps1", "stop_mt5_focus_watchdog.ps1", "audit_mt5_local_safety.ps1")) { continue }
   $text = Get-Content -LiteralPath $file.FullName -Raw
   $looksLikeRunner = (Contains-Text $text 'terminal64.exe') -or (Contains-Text $text 'Start-MT5Hidden') -or (Contains-Text $text '/config:')
   if(!$looksLikeRunner) { continue }
   $runnerFiles.Add([pscustomobject]@{
      File = $file.Name
      HasGuard = (Contains-Text $text 'assert_mt5_launch_allowed.ps1')
      UsesHiddenHelper = (Contains-Text $text 'Start-MT5Hidden')
      UsesRawTerminalStart = (((Contains-Text $text 'Start-Process') -and (Contains-Text $text 'terminal64')) -or ((Contains-Text $text 'CreateProcess') -and (Contains-Text $text 'terminal64')))
   }) | Out-Null
}

$unguarded = @($runnerFiles | Where-Object { -not $_.HasGuard })
$rawStart = @($runnerFiles | Where-Object { $_.UsesRawTerminalStart })
$unguardedEvidence = "Runner scripts checked: $($runnerFiles.Count); unguarded: $($unguarded.Count)"
if($unguarded.Count -gt 0) { $unguardedEvidence += "; " + (($unguarded | Select-Object -ExpandProperty File) -join ", ") }
$rawStartEvidence = "Raw terminal launch matches: $($rawStart.Count)"
if($rawStart.Count -gt 0) { $rawStartEvidence += "; " + (($rawStart | Select-Object -ExpandProperty File) -join ", ") }
Add-Result $rows "Runner scripts" "All MT5 runner scripts source the launch guard" ($unguarded.Count -eq 0) $unguardedEvidence "Add `. (Join-Path `$PSScriptRoot `"assert_mt5_launch_allowed.ps1`")` near the top of each runner."
Add-Result $rows "Runner scripts" "No runner bypasses Start-MT5Hidden with raw terminal launch" ($rawStart.Count -eq 0) $rawStartEvidence "Route tester launches through Start-MT5Hidden and the guard."

$watchdogExists = Test-Path -LiteralPath $watchdogPath
$watchdogText = if($watchdogExists) { Get-Content -LiteralPath $watchdogPath -Raw } else { "" }
Add-Result $rows "Watchdog" "Watchdog script exists" $watchdogExists $watchdogPath "Restore work\mt5_focus_watchdog.ps1."
Add-Result $rows "Watchdog" "Watchdog targets MT5 and MetaEditor" ((Contains-Text $watchdogText 'terminal64') -and (Contains-Text $watchdogText 'metatester64') -and (Contains-Text $watchdogText 'MetaEditor')) $watchdogPath "Watchdog must stop terminal64, metatester64, and MetaEditor."

$watchdogProcesses = @()
try { $watchdogProcesses = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*mt5_focus_watchdog.ps1*' }) } catch { $watchdogProcesses = @() }
$watchdogEvidence = if($watchdogProcesses.Count -gt 0) { "Running watchdog PIDs: " + (($watchdogProcesses | ForEach-Object { $_.ProcessId }) -join ", ") } else { "No running watchdog process detected by CIM; script is present." }
Add-Result $rows "Watchdog" "Watchdog process is visible or can be restarted" ($watchdogExists -and ($watchdogProcesses.Count -ge 0)) $watchdogEvidence "Start work\mt5_focus_watchdog.ps1 if a local safety net is needed."

if(Test-Path -LiteralPath $handoffIntegrityPath) {
   $handoffRows = @(Import-Csv -LiteralPath $handoffIntegrityPath)
   $failedHandoff = @($handoffRows | Where-Object { $_.Passed -ne "True" })
   Add-Result $rows "Handoff configs" "Current handoff integrity has no failures" ($failedHandoff.Count -eq 0 -and $handoffRows.Count -gt 0) "Rows: $($handoffRows.Count); failures: $($failedHandoff.Count)" "Rerun work\audit_handoff_config_integrity.ps1 and fix any failed handoff config."
} else {
   Add-Result $rows "Handoff configs" "Current handoff integrity report exists" $false $handoffIntegrityPath "Run work\audit_handoff_config_integrity.ps1."
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
$md.Add("- Runner scripts checked: $($runnerFiles.Count)") | Out-Null
$md.Add("- MT5 processes running: $($mt5Processes.Count)") | Out-Null
$md.Add("- Unlock file present: $((Test-Path -LiteralPath $unlockPath))") | Out-Null
$md.Add("- `ALLOW_MT5_FOCUS_RISK=1`: $($envFlag -eq '1')") | Out-Null
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

if($runnerFiles.Count -gt 0) {
   $md.Add("") | Out-Null
   $md.Add("## Runner Script Coverage") | Out-Null
   $md.Add("") | Out-Null
   $md.Add("| File | Guard | Hidden Helper | Raw Terminal Start |") | Out-Null
   $md.Add("|---|---|---|---|") | Out-Null
   foreach($runner in ($runnerFiles | Sort-Object File)) {
      $md.Add("| ``$($runner.File)`` | $($runner.HasGuard) | $($runner.UsesHiddenHelper) | $($runner.UsesRawTerminalStart) |") | Out-Null
   }
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
