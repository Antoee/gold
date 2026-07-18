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
$resolvedWorkDir = (Resolve-Path -LiteralPath $WorkDir).Path
$outerHardLockPath = Join-Path (Split-Path -Parent (Split-Path -Parent $resolvedWorkDir)) "MT5_LOCAL_LAUNCH_DISABLED.lock"
$quietStopPath = Join-Path $WorkDir "STOP_MT5_FOCUS_WATCHDOG"
$guardPath = Join-Path $WorkDir "assert_mt5_launch_allowed.ps1"
$helperPath = Join-Path $WorkDir "mt5_background_helpers.ps1"
$reportIdentityHelperPath = Join-Path $WorkDir "mt5_report_identity_helpers.ps1"
$portableConfigRunnerPath = Join-Path $WorkDir "run_mt5_portable_config_hidden.ps1"
$portableWorkerPath = Join-Path $WorkDir "run_mt5_portable_package_worker.ps1"
$sharedBinaryPreparerPath = Join-Path $WorkDir "prepare_mt5_portable_shared_expert.ps1"
$tickCacheHelperPath = Join-Path $WorkDir "mt5_tick_cache_sync_helpers.ps1"
$tickCacheSyncPath = Join-Path $WorkDir "sync_mt5_portable_xauusd_tick_cache.ps1"
$stagedWaveRunnerPath = Join-Path $WorkDir "run_rdmc_diversified_repair_executable_gate_wave.ps1"
$stopHelperPath = Join-Path $WorkDir "stop_mt5_stray_processes.ps1"
$stopWatchdogPath = Join-Path $WorkDir "stop_mt5_focus_watchdog.ps1"
$watchdogPath = Join-Path $WorkDir "mt5_focus_watchdog.ps1"
$startWatchdogPath = Join-Path $WorkDir "start_mt5_focus_watchdog_hidden.ps1"
$offlineRefreshPath = Join-Path $WorkDir "refresh_offline_validation_state.ps1"
$moneyReadyRefreshPath = Join-Path $WorkDir "refresh_money_ready_status.ps1"
$handoffIntegrityPath = "outputs\HANDOFF_CONFIG_INTEGRITY.csv"
$forwardStatusPath = "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.csv"

$mt5Processes = @(Get-Process -Name $mt5ProcessNames -ErrorAction SilentlyContinue)
$terminalProcesses = @($mt5Processes | Where-Object { $_.ProcessName -in @("terminal", "terminal64") })
$nonTerminalProcesses = @($mt5Processes | Where-Object { $_.ProcessName -notin @("terminal", "terminal64") })
$portableTerminalProcesses = @($terminalProcesses | Where-Object {
   try { $_.Path -notlike "C:\Program Files\MetaTrader 5\*" } catch { $true }
})
$mainTerminalProcesses = @($terminalProcesses | Where-Object {
   try { $_.Path -like "C:\Program Files\MetaTrader 5\*" } catch { $false }
})

$forwardStatus = $null
if(Test-Path -LiteralPath $forwardStatusPath -PathType Leaf) {
   $forwardStatus = @(Import-Csv -LiteralPath $forwardStatusPath | Select-Object -First 1)[0]
}

$forwardTerminalSafe = $false
$forwardStatusChecks = New-Object System.Collections.Generic.List[string]
if($null -ne $forwardStatus) {
   $requiredTrueFields = @(
      "TerminalRunning",
      "SourceHashMatch",
      "ProfileHashMatch",
      "InstalledBinaryHashMatch",
      "SentinelCodeIdentityPass",
      "SentinelHeartbeatPresent",
      "SentinelHeartbeatValid",
      "SentinelHeartbeatFresh",
      "SentinelHeartbeatIdentityPass",
      "Connected",
      "AccountModePass",
      "PositionIsolationPass",
      "ProtectionPass",
      "OpenRiskPass"
   )
   foreach($field in $requiredTrueFields) {
      $passed = ([string]$forwardStatus.$field -eq "True")
      $forwardStatusChecks.Add("${field}=$passed") | Out-Null
   }

   $flatAndLocked = (
      [string]$forwardStatus.AccountTradeMode -eq "demo" -and
      [string]$forwardStatus.TerminalTradeAllowed -eq "False" -and
      [string]$forwardStatus.RealAccountTradingAllowed -eq "False" -and
      [int]$forwardStatus.AllPositions -eq 0 -and
      [int]$forwardStatus.CandidatePositions -eq 0 -and
      [int]$forwardStatus.AllUnprotectedPositions -eq 0 -and
      [int]$forwardStatus.CandidateUnprotectedPositions -eq 0 -and
      [double]$forwardStatus.CandidateOpenRiskPercent -eq 0
   )
   $allRequiredStatusChecksPass = @($requiredTrueFields | Where-Object { [string]$forwardStatus.$_ -ne "True" }).Count -eq 0
   $forwardTerminalSafe = (
      $mainTerminalProcesses.Count -eq 1 -and
      $portableTerminalProcesses.Count -eq 0 -and
      $nonTerminalProcesses.Count -eq 0 -and
      $allRequiredStatusChecksPass -and
      $flatAndLocked
   )
}

$runtimeSafe = ($mt5Processes.Count -eq 0) -or $forwardTerminalSafe
$mt5Evidence = if($mt5Processes.Count -eq 0) {
   "No matching process found."
}
elseif($forwardTerminalSafe) {
   "One registered main terminal is running read-only; demo identity and sentinel pass; global trading disabled; positions and open risk are zero."
}
else {
   "Matching processes: " + (($mt5Processes | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join "; ") + "; registered read-only forward-terminal gate failed."
}
Add-Result $rows "Runtime" "No unsafe MT5/MetaEditor process is running" $runtimeSafe `
   $mt5Evidence `
   "Stop tester/editor/portable processes, or keep only the registered flat demo terminal with valid identity, a fresh sentinel heartbeat, global trading disabled, and zero open risk."

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
Add-Result $rows "Runtime" "Outer workspace launch lock is present" (Test-Path -LiteralPath $outerHardLockPath) `
   $outerHardLockPath `
   "Restore the outer workspace MT5_LOCAL_LAUNCH_DISABLED.lock while local MT5 can steal focus on this PC."

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
Add-Result $rows "Guard" "Launch guard honors outer workspace hard lock" ((Contains-Text $guardText 'outerHardLockFile') -and (Contains-Text $guardText 'Split-Path -Parent $repoRoot')) $guardPath "Guard must stop when the outer workspace lock exists."
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
Add-Result $rows "Helper" "Background helper covers broad MT5 process variants" ((Contains-Text $helperText 'Get-MT5FamilyProcessNames') -and (Contains-Text $helperText 'terminal64') -and (Contains-Text $helperText 'terminal') -and (Contains-Text $helperText 'metatester64') -and (Contains-Text $helperText 'metatester') -and (Contains-Text $helperText 'MetaEditor') -and (Contains-Text $helperText 'metaeditor64')) $helperPath "Mute, priority, and hide-window controls should cover terminal/metatester/MetaEditor variants."

$reportIdentityHelperText = Read-TextSafe $reportIdentityHelperPath
$portableConfigRunnerText = Read-TextSafe $portableConfigRunnerPath
$portableWorkerText = Read-TextSafe $portableWorkerPath
Add-Result $rows "Report integrity" "Identity-bound report helper exists" ((Test-Path -LiteralPath $reportIdentityHelperPath) -and (Contains-Text $reportIdentityHelperText 'Read-MT5ReportIdentityEvidence') -and (Contains-Text $reportIdentityHelperText 'Write-MT5ReportIdentityEvidence') -and (Contains-Text $reportIdentityHelperText 'PortableBinarySha256') -and (Contains-Text $reportIdentityHelperText 'ReportSha256')) $reportIdentityHelperPath "Restore the schema-versioned report identity helper."
Add-Result $rows "Report integrity" "Portable runner requires fresh completed report" ((Contains-Text $portableConfigRunnerText 'Get-MatchingPortableReports') -and (Contains-Text $portableConfigRunnerText 'did not exit cleanly') -and (Contains-Text $portableConfigRunnerText 'ambiguous report set') -and (Contains-Text $portableConfigRunnerText 'still changing after terminal exit')) $portableConfigRunnerPath "Remove stale reports, wait for clean terminal exit, and require one stable report."
Add-Result $rows "Report integrity" "Portable worker resumes only identity-bound evidence" ((Contains-Text $portableWorkerText 'Read-MT5ReportIdentityEvidence') -and (Contains-Text $portableWorkerText 'Write-MT5ReportIdentityEvidence') -and (Contains-Text $portableWorkerText 'ReportIdentityReused') -and (Contains-Text $portableWorkerText 'PackageConfigSha256')) $portableWorkerPath "Require matching config, source, binary, and report identities before reusing a completed row."

$sharedBinaryPreparerText = Read-TextSafe $sharedBinaryPreparerPath
$tickCacheHelperText = Read-TextSafe $tickCacheHelperPath
$tickCacheSyncText = Read-TextSafe $tickCacheSyncPath
$tickCacheContractText = $tickCacheSyncText + "`n" + $tickCacheHelperText
$stagedWaveRunnerText = Read-TextSafe $stagedWaveRunnerPath
Add-Result $rows "Shared binary" "Compile-once preparer is guarded and exact" ((Test-Path -LiteralPath $sharedBinaryPreparerPath) -and (Contains-Text $sharedBinaryPreparerText 'assert_mt5_launch_allowed.ps1') -and (Contains-Text $sharedBinaryPreparerText 'COMPILED_ONCE_AND_DISTRIBUTED') -and (Contains-Text $sharedBinaryPreparerText 'Shared expert distribution verification failed') -and ([regex]::Matches($sharedBinaryPreparerText, [regex]::Escape('HiddenProcess]::StartHidden')).Count -eq 1)) $sharedBinaryPreparerPath "Compile once on one allowlisted leader and verify exact source, binary, and identity bytes on every root."
Add-Result $rows "Shared binary" "Staged wave prepares before parallel execution" ((Contains-Text $stagedWaveRunnerText '& $sharedBinaryPreparer') -and (Contains-Text $stagedWaveRunnerText '-ExpectedPortableBinarySha256 $sharedBinary.PortableBinarySha256') -and $stagedWaveRunnerText.LastIndexOf('& $sharedBinaryPreparer', [StringComparison]::Ordinal) -lt $stagedWaveRunnerText.IndexOf('& $parallelRunner', [StringComparison]::Ordinal)) $stagedWaveRunnerPath "Prepare and attest one shared EX5 before starting parallel workers."
Add-Result $rows "Shared binary" "Direct workers cannot compile after shared preparation" ((Contains-Text $portableConfigRunnerText 'independent worker compilation is prohibited') -and (Contains-Text $portableWorkerText 'differs from the prepared shared binary') -and (Contains-Text $portableWorkerText 'ExpectedPortableBinarySha256')) $portableWorkerPath "Fail before testing when prepared source, binary, or identity bytes drift."
Add-Result $rows "Tick cache" "Cache union is XAUUSD-only and process-free" ((Test-Path -LiteralPath $tickCacheSyncPath) -and (Test-Path -LiteralPath $tickCacheHelperPath) -and (Contains-Text $tickCacheContractText 'bases\MetaQuotes-Demo\ticks\XAUUSD') -and (Contains-Text $tickCacheSyncText 'Portable MT5 processes must be fully stopped') -and !(Contains-Text $tickCacheContractText 'Start-Process') -and !(Contains-Text $tickCacheContractText 'Start-MT5Hidden')) $tickCacheSyncPath "Restrict synchronization to allowlisted XAUUSD tick caches and require stopped portable terminals."
Add-Result $rows "Tick cache" "Cache copies are complete-month, hash-bound, and no-overwrite" ((Contains-Text $tickCacheContractText 'SKIPPED_PARTIAL_CUTOFF') -and (Contains-Text $tickCacheContractText 'MISSING_ALL_ROOTS') -and (Contains-Text $tickCacheContractText 'HASH_CONFLICT') -and (Contains-Text $tickCacheContractText 'sync.tmp.') -and (Contains-Text $tickCacheContractText 'refusing overwrite') -and (Contains-Text $tickCacheSyncText 'did not produce one exact union')) $tickCacheSyncPath "Never copy the partial cutoff month; require complete-month coverage, reject conflicts, and verify every missing-file copy."
Add-Result $rows "Tick cache" "Wave 4 warms cache before continuous real ticks" ((Contains-Text $stagedWaveRunnerText 'DISJOINT_THEN_SYNC_THEN_CONTINUOUS') -and (Contains-Text $stagedWaveRunnerText '$cacheResult = & $tickCacheSync') -and $stagedWaveRunnerText.IndexOf('& $parallelRunner -ManifestPath $broadManifest', [StringComparison]::Ordinal) -lt $stagedWaveRunnerText.IndexOf('$cacheResult = & $tickCacheSync', [StringComparison]::Ordinal) -and $stagedWaveRunnerText.IndexOf('$cacheResult = & $tickCacheSync', [StringComparison]::Ordinal) -lt $stagedWaveRunnerText.IndexOf('& $parallelRunner -ManifestPath $continuousManifest', [StringComparison]::Ordinal)) $stagedWaveRunnerPath "Run disjoint eras, union verified complete-month ticks, then run the overlapping continuous row."

$stopHelperText = Read-TextSafe $stopHelperPath
Add-Result $rows "Cleanup" "Stop-stray helper exists" (Test-Path -LiteralPath $stopHelperPath) $stopHelperPath "Restore work\stop_mt5_stray_processes.ps1."
Add-Result $rows "Cleanup" "Stop-stray helper does not launch MT5" ((Contains-Text $stopHelperText 'Stop-Process') -and !(Contains-Text $stopHelperText 'Start-Process') -and !(Contains-Text $stopHelperText 'Start-MT5Hidden')) $stopHelperPath "Cleanup helper must only stop existing processes."

$stopWatchdogText = Read-TextSafe $stopWatchdogPath
Add-Result $rows "Cleanup" "Stop-watchdog helper preserves quiet marker and avoids self-match" ((Test-Path -LiteralPath $stopWatchdogPath) -and (Contains-Text $stopWatchdogText '$needle = "mt5_focus_" + "watchdog.ps1"') -and (Contains-Text $stopWatchdogText '$_.ProcessId -ne $currentPid') -and !(Contains-Text $stopWatchdogText 'Remove-Item -LiteralPath $stopFile')) $stopWatchdogPath "Keep the quiet stop marker in place and avoid matching the stop helper command itself."

$offlineRefreshText = Read-TextSafe $offlineRefreshPath
Add-Result $rows "Offline refresh" "Offline refresh script exists" (Test-Path -LiteralPath $offlineRefreshPath) $offlineRefreshPath "Restore work\refresh_offline_validation_state.ps1."
Add-Result $rows "Offline refresh" "Offline refresh child steps run without windows" ((Contains-Text $offlineRefreshText 'function Invoke-QuietPowerShell') -and (Contains-Text $offlineRefreshText 'ProcessStartInfo') -and (Contains-Text $offlineRefreshText 'CreateNoWindow') -and (Contains-Text $offlineRefreshText 'ProcessWindowStyle]::Hidden') -and (Contains-Text $offlineRefreshText 'RedirectStandardOutput = $true') -and (Contains-Text $offlineRefreshText 'RedirectStandardError = $true') -and !(Contains-Text $offlineRefreshText 'Start-Process')) $offlineRefreshPath "Offline refresh child PowerShell steps must use ProcessStartInfo with CreateNoWindow and write logs."
Add-Result $rows "Offline refresh" "Offline refresh avoids direct visible child shells" (!(Contains-Text $offlineRefreshText 'powershell -NoProfile') -and !(Contains-Text $offlineRefreshText 'powershell -ExecutionPolicy') -and !(Contains-Text $offlineRefreshText '& powershell')) $offlineRefreshPath "Replace direct powershell child calls with Invoke-QuietPowerShell."
Add-Result $rows "Offline refresh" "Offline refresh does not launch MT5" (!(Contains-Text $offlineRefreshText 'Start-MT5Hidden') -and !(Contains-Text $offlineRefreshText 'terminal64.exe') -and !(Contains-Text $offlineRefreshText 'MetaEditor.exe')) $offlineRefreshPath "Offline refresh must rebuild state only; it must not launch MT5, MetaEditor, or Strategy Tester."

$moneyReadyRefreshText = Read-TextSafe $moneyReadyRefreshPath
Add-Result $rows "Money-ready refresh" "Money-ready refresh script exists" (Test-Path -LiteralPath $moneyReadyRefreshPath) $moneyReadyRefreshPath "Restore work\refresh_money_ready_status.ps1."
Add-Result $rows "Money-ready refresh" "Money-ready refresh child steps run without windows" ((Contains-Text $moneyReadyRefreshText 'function Invoke-QuietPowerShell') -and (Contains-Text $moneyReadyRefreshText 'ProcessStartInfo') -and (Contains-Text $moneyReadyRefreshText 'CreateNoWindow') -and (Contains-Text $moneyReadyRefreshText 'ProcessWindowStyle]::Hidden') -and (Contains-Text $moneyReadyRefreshText 'RedirectStandardOutput = $true') -and (Contains-Text $moneyReadyRefreshText 'RedirectStandardError = $true') -and !(Contains-Text $moneyReadyRefreshText 'Start-Process')) $moneyReadyRefreshPath "Money-ready refresh child PowerShell steps must use ProcessStartInfo with CreateNoWindow and write logs."
Add-Result $rows "Money-ready refresh" "Money-ready refresh avoids direct visible child shells" (!(Contains-Text $moneyReadyRefreshText 'powershell -NoProfile') -and !(Contains-Text $moneyReadyRefreshText 'powershell -ExecutionPolicy') -and !(Contains-Text $moneyReadyRefreshText '& powershell')) $moneyReadyRefreshPath "Replace direct powershell child calls with Invoke-QuietPowerShell."
Add-Result $rows "Money-ready refresh" "Money-ready refresh does not launch MT5" (!(Contains-Text $moneyReadyRefreshText 'Start-MT5Hidden') -and !(Contains-Text $moneyReadyRefreshText 'terminal64.exe') -and !(Contains-Text $moneyReadyRefreshText 'MetaEditor.exe')) $moneyReadyRefreshPath "Money-ready refresh must rebuild state only; it must not launch MT5, MetaEditor, or Strategy Tester."

$scriptFiles = @(Get-ChildItem -LiteralPath $WorkDir -Filter "*.ps1" -File)
$runnerFiles = New-Object System.Collections.Generic.List[object]
foreach($file in $scriptFiles) {
   if($file.Name -in @("assert_mt5_launch_allowed.ps1", "mt5_background_helpers.ps1", "mt5_focus_watchdog.ps1", "stop_mt5_focus_watchdog.ps1", "audit_mt5_local_safety.ps1", "stop_mt5_stray_processes.ps1", "build_report_import_preflight.ps1", "test_mt5_hidden_launcher_lock.ps1", "test_first_pass_hidden_runner_lock.ps1", "test_mt5_portable_xauusd_tick_cache_sync.ps1")) {
      continue
   }

   $text = Get-Content -LiteralPath $file.FullName -Raw
   $mentionsTerminal = (Contains-Text $text 'terminal64.exe') -or (Contains-Text $text 'terminal.exe')
   $hasProcessLaunch = (Contains-Text $text 'Start-Process') -or (Contains-Text $text 'CreateProcess') -or
      (Contains-Text $text 'ProcessStartInfo') -or (Contains-Text $text 'HiddenProcess]::StartHidden')
   $looksLikeRunner = (Contains-Text $text 'Start-MT5Hidden') -or (Contains-Text $text '/config:') -or
      ($mentionsTerminal -and $hasProcessLaunch)
   if(!$looksLikeRunner) {
      continue
   }

   $hasLegacyGuard = (Contains-Text $text 'assert_mt5_launch_allowed.ps1')
   $hasPortableIsolationGuard = (
      (Contains-Text $text 'UserAuthorizedFocusRisk') -and
      (Contains-Text $text 'PortableRoot') -and
      (Contains-Text $text 'Get-PortableProcesses') -and
      (Contains-Text $text 'Stop-PortableProcesses') -and
      (Contains-Text $text 'InstalledFrozenArtifactsUnchanged') -and
      (Contains-Text $text 'HiddenProcess]::StartHidden') -and
      (Contains-Text $text 'Portable runtime is outside the workspace work directory') -and
      (Contains-Text $text 'Portable tester changed the installed frozen artifacts')
   )
   $hasGuard = $hasLegacyGuard -or $hasPortableIsolationGuard
   $usesHiddenHelper = (Contains-Text $text 'Start-MT5Hidden')
   $usesRawTerminalStart = ((Contains-Text $text 'Start-Process') -and ((Contains-Text $text 'terminal64') -or (Contains-Text $text 'terminal.exe'))) -or ((Contains-Text $text 'CreateProcess') -and ((Contains-Text $text 'terminal64') -or (Contains-Text $text 'terminal.exe')))
   $runnerFiles.Add([pscustomobject]@{
      File = $file.Name
      HasGuard = $hasGuard
      GuardType = if($hasLegacyGuard) { "LegacyLaunchLock" } elseif($hasPortableIsolationGuard) { "PortableIsolation" } else { "None" }
      UsesHiddenHelper = $usesHiddenHelper
      UsesRawTerminalStart = $usesRawTerminalStart
   }) | Out-Null
}

$unguarded = @($runnerFiles | Where-Object { -not $_.HasGuard })
$rawStart = @($runnerFiles | Where-Object { $_.UsesRawTerminalStart })
$unguardedEvidence = "Runner scripts checked: $($runnerFiles.Count); unguarded: $($unguarded.Count)"
if($unguarded.Count -gt 0) {
   $unguardedEvidence += "; " + (($unguarded | Select-Object -ExpandProperty File) -join ", ")
}
$rawStartEvidence = "Raw terminal launch matches: $($rawStart.Count)"
if($rawStart.Count -gt 0) {
   $rawStartEvidence += "; " + (($rawStart | Select-Object -ExpandProperty File) -join ", ")
}
Add-Result $rows "Runner scripts" "All MT5 runner scripts use an approved launch guard" ($unguarded.Count -eq 0) `
   $unguardedEvidence `
   "Use the legacy hard-lock guard, or the workspace-isolated portable guard that requires focus-risk authorization, hidden launch, bounded cleanup, and frozen-artifact verification."
Add-Result $rows "Runner scripts" "No runner uses an unapproved raw terminal launch" ($rawStart.Count -eq 0) `
   $rawStartEvidence `
   "Route tester launches through Start-MT5Hidden, or the approved workspace-isolated portable hidden runner."

$watchdogExists = Test-Path -LiteralPath $watchdogPath
$watchdogText = Read-TextSafe $watchdogPath
$startWatchdogText = Read-TextSafe $startWatchdogPath
Add-Result $rows "Watchdog" "Watchdog script exists" $watchdogExists $watchdogPath "Restore work\mt5_focus_watchdog.ps1."
Add-Result $rows "Watchdog" "Watchdog targets MT5 and MetaEditor" ((Contains-Text $watchdogText 'terminal64') -and (Contains-Text $watchdogText 'metatester64') -and (Contains-Text $watchdogText 'MetaEditor')) $watchdogPath "Watchdog must stop terminal64, metatester64, and MetaEditor."
Add-Result $rows "Watchdog" "Watchdog default is bounded for quiet PC use" ((Contains-Text $watchdogText '[int]$MonitorSeconds = 5') -and (Contains-Text $watchdogText '[int]$PollMilliseconds = 250')) $watchdogPath "Keep the default watchdog run short unless the user explicitly asks for a resident safety net."
Add-Result $rows "Watchdog" "Hidden watchdog starter exists" (Test-Path -LiteralPath $startWatchdogPath) $startWatchdogPath "Restore work\start_mt5_focus_watchdog_hidden.ps1."
Add-Result $rows "Watchdog" "Hidden watchdog starter uses detached no-window launch" ((Contains-Text $startWatchdogText 'Win32_ProcessStartup') -and (Contains-Text $startWatchdogText 'ShowWindow = 0') -and (Contains-Text $startWatchdogText 'Win32_Process') -and !(Contains-Text $startWatchdogText 'Start-Process')) $startWatchdogPath "Start the focus watchdog through detached hidden process creation, not a visible shell."

$watchdogProcesses = @()
try {
   $watchdogProcesses = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*mt5_focus_watchdog.ps1*' })
}
catch {
   $watchdogProcesses = @()
}
$watchdogEvidence = if($watchdogProcesses.Count -gt 0) { "Running watchdog PIDs: " + (($watchdogProcesses | ForEach-Object { $_.ProcessId }) -join ", ") + "; stop marker present: $quietStopExists" } else { "No running watchdog process detected by CIM; stop marker present: $quietStopExists" }
$watchdogStateOk = (($watchdogProcesses.Count -eq 0 -and $quietStopExists) -or ($watchdogProcesses.Count -gt 0 -and -not $quietStopExists))
Add-Result $rows "Watchdog" "Watchdog process state matches quiet shield mode" $watchdogStateOk `
   $watchdogEvidence `
   "Use work\start_mt5_focus_watchdog_hidden.ps1 for an active hidden shield, or work\stop_mt5_focus_watchdog.ps1 for no resident helper."

if(Test-Path -LiteralPath $handoffIntegrityPath) {
   $handoffRows = @(Import-Csv -LiteralPath $handoffIntegrityPath)
   $failedHandoff = @($handoffRows | Where-Object { $_.Passed -ne "True" })
   Add-Result $rows "Handoff configs" "Current handoff integrity has no failures" ($failedHandoff.Count -eq 0 -and $handoffRows.Count -gt 0) `
      "Rows: $($handoffRows.Count); failures: $($failedHandoff.Count)" `
      "Rerun work\audit_handoff_config_integrity.ps1 and fix any failed handoff config."
}
else {
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
$md.Add("- Registered read-only forward terminal safe: $forwardTerminalSafe") | Out-Null
$md.Add("- Unlock file present: $((Test-Path -LiteralPath $unlockPath))") | Out-Null
$md.Add("- Hidden desktop ack file present: $((Test-Path -LiteralPath $hiddenDesktopAckPath))") | Out-Null
$md.Add("- Hard local launch lock present: $((Test-Path -LiteralPath $hardLockPath))") | Out-Null
$md.Add("- Quiet PC stop marker present: $((Test-Path -LiteralPath $quietStopPath))") | Out-Null
$md.Add("- `ALLOW_MT5_FOCUS_RISK=1`: $($envFlag -eq '1')") | Out-Null
$md.Add("- `ALLOW_MT5_HIDDEN_DESKTOP_ACK=1`: $($hiddenDesktopEnvFlag -eq '1')") | Out-Null
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
   $md.Add("| File | Guard | Guard Type | Hidden Helper | Raw Terminal Start |") | Out-Null
   $md.Add("|---|---|---|---|---|") | Out-Null
   foreach($runner in ($runnerFiles | Sort-Object File)) {
      $md.Add("| ``$($runner.File)`` | $($runner.HasGuard) | $($runner.GuardType) | $($runner.UsesHiddenHelper) | $($runner.UsesRawTerminalStart) |") | Out-Null
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

if($failed.Count -gt 0) {
   exit 1
}
