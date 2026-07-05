# MT5 Local Safety Audit

Offline audit only. This script does not launch MT5.

- Overall: **PASS**
- Checks passed: 18 / 18
- Runner scripts checked: 56
- MT5 processes running: 0
- Unlock file present: False
- ALLOW_MT5_FOCUS_RISK=1: False

## Checks

| Area | Check | Passed | Evidence | Remediation |
|---|---|---|---|---|
| Runtime | No MT5/MetaEditor process is running | True | No matching process found. | Stop terminal64, metatester64, and MetaEditor before continuing offline work. |
| Runtime | ALLOW_MT5_FOCUS_RISK is not enabled | True | Environment variable is empty. | Unset ALLOW_MT5_FOCUS_RISK unless the user explicitly accepts focus risk for a controlled local MT5 run. |
| Runtime | Unlock file is absent | True | work\ALLOW_MT5_LOCAL_LAUNCH.unlock | Remove work\ALLOW_MT5_LOCAL_LAUNCH.unlock unless a controlled local MT5 run is intentionally allowed. |
| Guard | Launch guard script exists | True | work\assert_mt5_launch_allowed.ps1 | Restore work\assert_mt5_launch_allowed.ps1. |
| Guard | Launch guard requires env flag | True | work\assert_mt5_launch_allowed.ps1 | Guard must require ALLOW_MT5_FOCUS_RISK=1. |
| Guard | Launch guard requires unlock file | True | work\assert_mt5_launch_allowed.ps1 | Guard must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock. |
| Guard | Launch guard stops stray MT5 processes | True | work\assert_mt5_launch_allowed.ps1 | Guard should stop stray MT5/MetaEditor processes before throwing. |
| Guard | Launch guard fails closed | True | work\assert_mt5_launch_allowed.ps1 | Guard must throw when local launch is not allowed. |
| Helper | Background helper exists | True | work\mt5_background_helpers.ps1 | Restore work\mt5_background_helpers.ps1. |
| Helper | Start-MT5Hidden requires env flag | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must require ALLOW_MT5_FOCUS_RISK=1. |
| Helper | Start-MT5Hidden requires unlock file | True | work\mt5_background_helpers.ps1 | Start-MT5Hidden must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock. |
| Helper | Background helper has low-impact controls | True | work\mt5_background_helpers.ps1 | Keep mute, lower-priority, and hide-window controls in the helper. |
| Runner scripts | All MT5 runner scripts source the launch guard | True | Runner scripts checked: 56; unguarded: 0 | Add . (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1") near the top of each runner. |
| Runner scripts | No runner bypasses Start-MT5Hidden with raw terminal launch | True | Raw terminal launch matches: 0 | Route tester launches through Start-MT5Hidden and the guard. |
| Watchdog | Watchdog script exists | True | work\mt5_focus_watchdog.ps1 | Restore work\mt5_focus_watchdog.ps1. |
| Watchdog | Watchdog targets MT5 and MetaEditor | True | work\mt5_focus_watchdog.ps1 | Watchdog must stop terminal64, metatester64, and MetaEditor. |
| Watchdog | Watchdog process is visible or can be restarted | True | No running watchdog process detected by CIM; script is present. | Start work\mt5_focus_watchdog.ps1 if a local safety net is needed. |
| Handoff configs | Current handoff integrity has no failures | True | Rows: 24; failures: 0 | Rerun work\audit_handoff_config_integrity.ps1 and fix any failed handoff config. |

## Runner Script Coverage

All 56 MT5 runner scripts are guarded and route tester launches through the hidden helper. Raw terminal launch bypasses found: 0.
