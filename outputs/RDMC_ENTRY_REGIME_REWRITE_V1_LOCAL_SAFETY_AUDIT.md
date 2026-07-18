# MT5 Local Safety Audit

Offline audit only. This script does not launch MT5.

- Overall: **PASS**
- Checks passed: 55 / 55
- Runner scripts checked: 4
- MT5 processes running: 0
- Registered read-only forward terminal safe: False
- Unlock file present: False
- Hidden desktop ack file present: False
- Hard local launch lock present: True
- Quiet PC stop marker present: True
- ALLOW_MT5_FOCUS_RISK=1: False
- ALLOW_MT5_HIDDEN_DESKTOP_ACK=1: False

## Checks

| Area | Check | Passed | Evidence | Remediation |
|---|---|---|---|---|
| Runtime | No unsafe MT5/MetaEditor process is running | True | No matching process found. | Stop tester/editor/portable processes, or keep only the registered flat demo terminal with valid identity, a fresh sentinel heartbeat, global trading disabled, and zero open risk. |
| Runtime | ALLOW_MT5_FOCUS_RISK is not enabled | True | Environment variable is empty. | Unset ALLOW_MT5_FOCUS_RISK unless the user explicitly accepts focus risk for a controlled local MT5 run. |
| Runtime | ALLOW_MT5_HIDDEN_DESKTOP_ACK is not enabled | True | Environment variable is empty. | Unset ALLOW_MT5_HIDDEN_DESKTOP_ACK unless the user explicitly accepts focus risk for a controlled local MT5 run. |
| Runtime | Unlock file is absent | True | work\ALLOW_MT5_LOCAL_LAUNCH.unlock | Remove work\ALLOW_MT5_LOCAL_LAUNCH.unlock unless a controlled local MT5 run is intentionally allowed. |
| Runtime | Hidden desktop ack file is absent | True | work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock | Remove work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock unless a controlled local MT5 run is intentionally allowed. |
| Runtime | Hard local launch lock is present | True | work\MT5_LOCAL_LAUNCH_DISABLED.lock | Restore work\MT5_LOCAL_LAUNCH_DISABLED.lock while local MT5 can steal focus on this PC. |
| Runtime | Outer workspace launch lock is present | True | C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you\work\MT5_LOCAL_LAUNCH_DISABLED.lock | Restore the outer workspace MT5_LOCAL_LAUNCH_DISABLED.lock while local MT5 can steal focus on this PC. |
| Runtime | Quiet PC mode stop marker status is recorded | True | Present: True; path: work\STOP_MT5_FOCUS_WATCHDOG | Create work\STOP_MT5_FOCUS_WATCHDOG while the user needs no resident watchdog or visible helper process. |
| Guard | Launch guard script exists | True | work\assert_mt5_launch_allowed.ps1 | Restore work\assert_mt5_launch_allowed.ps1. |
| Guard | Launch guard has broad MT5 process list | True | work\assert_mt5_launch_allowed.ps1 | Guard must stop terminal/metatester/MetaEditor variants. |
| Guard | Launch guard requires env flag | True | work\assert_mt5_launch_allowed.ps1 | Guard must require ALLOW_MT5_FOCUS_RISK=1. |
| Guard | Launch guard requires hidden desktop ack | True | work\assert_mt5_launch_allowed.ps1 | Guard must require ALLOW_MT5_HIDDEN_DESKTOP_ACK=1. |
| Guard | Launch guard requires unlock file | True | work\assert_mt5_launch_allowed.ps1 | Guard must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock. |
| Guard | Launch guard requires hidden desktop ack file | True | work\assert_mt5_launch_allowed.ps1 | Guard must require work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock. |
| Guard | Launch guard honors hard lock | True | work\assert_mt5_launch_allowed.ps1 | Guard must stop when work\MT5_LOCAL_LAUNCH_DISABLED.lock exists. |
| Guard | Launch guard honors outer workspace hard lock | True | work\assert_mt5_launch_allowed.ps1 | Guard must stop when the outer workspace lock exists. |
| Guard | Launch guard stops stray MT5 processes | True | work\assert_mt5_launch_allowed.ps1 | Guard should stop stray MT5/MetaEditor processes before throwing. |
| Guard | Launch guard fails closed | True | work\assert_mt5_launch_allowed.ps1 | Guard must throw when local launch is not allowed. |
| Helper | Background helper exists | True | work\mt5_background_helpers.ps1 | Restore work\mt5_background_helpers.ps1. |
| Helper | Start-MT5Hidden requires env flag | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must require ALLOW_MT5_FOCUS_RISK=1. |
| Helper | Start-MT5Hidden requires hidden desktop ack | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must require ALLOW_MT5_HIDDEN_DESKTOP_ACK=1. |
| Helper | Start-MT5Hidden requires unlock file | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock. |
| Helper | Start-MT5Hidden requires hidden desktop ack file | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must require work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock. |
| Helper | Start-MT5Hidden honors hard lock | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must stop when work\MT5_LOCAL_LAUNCH_DISABLED.lock exists. |
| Helper | Background helper has low-impact controls | True | work\mt5_background_helpers.ps1 | Keep mute, lower-priority, and hide-window controls in the helper. |
| Helper | Background helper covers broad MT5 process variants | True | work\mt5_background_helpers.ps1 | Mute, priority, and hide-window controls should cover terminal/metatester/MetaEditor variants. |
| Report integrity | Identity-bound report helper exists | True | work\mt5_report_identity_helpers.ps1 | Restore the schema-versioned report identity helper. |
| Report integrity | Portable runner requires fresh completed report | True | work\run_mt5_portable_config_hidden.ps1 | Remove stale reports, wait for clean terminal exit, and require one stable report. |
| Report integrity | Portable worker resumes only identity-bound evidence | True | work\run_mt5_portable_package_worker.ps1 | Require matching config, source, binary, and report identities before reusing a completed row. |
| Shared binary | Compile-once preparer is guarded and exact | True | work\prepare_mt5_portable_shared_expert.ps1 | Compile once on one allowlisted leader and verify exact source, binary, and identity bytes on every root. |
| Shared binary | Staged wave prepares before parallel execution | True | work\run_rdmc_diversified_repair_executable_gate_wave.ps1 | Prepare and attest one shared EX5 before starting parallel workers. |
| Shared binary | Direct workers cannot compile after shared preparation | True | work\run_mt5_portable_package_worker.ps1 | Fail before testing when prepared source, binary, or identity bytes drift. |
| Tick cache | Cache union is XAUUSD-only and process-free | True | work\sync_mt5_portable_xauusd_tick_cache.ps1 | Restrict synchronization to allowlisted XAUUSD tick caches and require stopped portable terminals. |
| Tick cache | Cache copies are complete-month, hash-bound, and no-overwrite | True | work\sync_mt5_portable_xauusd_tick_cache.ps1 | Never copy the partial cutoff month; require complete-month coverage, reject conflicts, and verify every missing-file copy. |
| Tick cache | Wave 4 warms cache before continuous real ticks | True | work\run_rdmc_diversified_repair_executable_gate_wave.ps1 | Run disjoint eras, union verified complete-month ticks, then run the overlapping continuous row. |
| Cleanup | Stop-stray helper exists | True | work\stop_mt5_stray_processes.ps1 | Restore work\stop_mt5_stray_processes.ps1. |
| Cleanup | Stop-stray helper does not launch MT5 | True | work\stop_mt5_stray_processes.ps1 | Cleanup helper must only stop existing processes. |
| Cleanup | Stop-watchdog helper preserves quiet marker and avoids self-match | True | work\stop_mt5_focus_watchdog.ps1 | Keep the quiet stop marker in place and avoid matching the stop helper command itself. |
| Offline refresh | Offline refresh script exists | True | work\refresh_offline_validation_state.ps1 | Restore work\refresh_offline_validation_state.ps1. |
| Offline refresh | Offline refresh child steps run without windows | True | work\refresh_offline_validation_state.ps1 | Offline refresh child PowerShell steps must use ProcessStartInfo with CreateNoWindow and write logs. |
| Offline refresh | Offline refresh avoids direct visible child shells | True | work\refresh_offline_validation_state.ps1 | Replace direct powershell child calls with Invoke-QuietPowerShell. |
| Offline refresh | Offline refresh does not launch MT5 | True | work\refresh_offline_validation_state.ps1 | Offline refresh must rebuild state only; it must not launch MT5, MetaEditor, or Strategy Tester. |
| Money-ready refresh | Money-ready refresh script exists | True | work\refresh_money_ready_status.ps1 | Restore work\refresh_money_ready_status.ps1. |
| Money-ready refresh | Money-ready refresh child steps run without windows | True | work\refresh_money_ready_status.ps1 | Money-ready refresh child PowerShell steps must use ProcessStartInfo with CreateNoWindow and write logs. |
| Money-ready refresh | Money-ready refresh avoids direct visible child shells | True | work\refresh_money_ready_status.ps1 | Replace direct powershell child calls with Invoke-QuietPowerShell. |
| Money-ready refresh | Money-ready refresh does not launch MT5 | True | work\refresh_money_ready_status.ps1 | Money-ready refresh must rebuild state only; it must not launch MT5, MetaEditor, or Strategy Tester. |
| Runner scripts | All MT5 runner scripts use an approved launch guard | True | Runner scripts checked: 4; unguarded: 0 | Use the legacy hard-lock guard, or the workspace-isolated portable guard that requires focus-risk authorization, hidden launch, bounded cleanup, and frozen-artifact verification. |
| Runner scripts | No runner uses an unapproved raw terminal launch | True | Raw terminal launch matches: 0 | Route tester launches through Start-MT5Hidden, or the approved workspace-isolated portable hidden runner. |
| Watchdog | Watchdog script exists | True | work\mt5_focus_watchdog.ps1 | Restore work\mt5_focus_watchdog.ps1. |
| Watchdog | Watchdog targets MT5 and MetaEditor | True | work\mt5_focus_watchdog.ps1 | Watchdog must stop terminal64, metatester64, and MetaEditor. |
| Watchdog | Watchdog default is bounded for quiet PC use | True | work\mt5_focus_watchdog.ps1 | Keep the default watchdog run short unless the user explicitly asks for a resident safety net. |
| Watchdog | Hidden watchdog starter exists | True | work\start_mt5_focus_watchdog_hidden.ps1 | Restore work\start_mt5_focus_watchdog_hidden.ps1. |
| Watchdog | Hidden watchdog starter uses detached no-window launch | True | work\start_mt5_focus_watchdog_hidden.ps1 | Start the focus watchdog through detached hidden process creation, not a visible shell. |
| Watchdog | Watchdog process state matches quiet shield mode | True | No running watchdog process detected by CIM; stop marker present: True | Use work\start_mt5_focus_watchdog_hidden.ps1 for an active hidden shield, or work\stop_mt5_focus_watchdog.ps1 for no resident helper. |
| Handoff configs | Current handoff integrity has no failures | True | Rows: 24; failures: 0 | Rerun work\audit_handoff_config_integrity.ps1 and fix any failed handoff config. |

## Runner Script Coverage

| File | Guard | Guard Type | Hidden Helper | Raw Terminal Start |
|---|---|---|---|---|
| `prepare_mt5_portable_shared_expert.ps1` | True | LegacyLaunchLock | False | False |
| `run_first_pass_package_hidden.ps1` | True | LegacyLaunchLock | True | False |
| `run_mt5_portable_config_hidden.ps1` | True | LegacyLaunchLock | False | False |
| `test_mt5_report_export_smoke.ps1` | True | LegacyLaunchLock | True | False |
