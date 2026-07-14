# MT5 Local Safety Audit

Offline audit only. This script does not launch MT5.

- Overall: **PASS**
- Checks passed: 44 / 44
- Runner scripts checked: 58
- MT5 processes running: 0
- Unlock file present: False
- Hidden desktop ack file present: False
- Hard local launch lock present: True
- Quiet PC stop marker present: True
- ALLOW_MT5_FOCUS_RISK=1: False
- ALLOW_MT5_HIDDEN_DESKTOP_ACK=1: False

## Checks

| Area | Check | Passed | Evidence | Remediation |
|---|---|---|---|---|
| Runtime | No MT5/MetaEditor process is running | True | No matching process found. | Stop terminal64, metatester64, and MetaEditor before continuing offline work. |
| Runtime | ALLOW_MT5_FOCUS_RISK is not enabled | True | Environment variable is empty. | Unset ALLOW_MT5_FOCUS_RISK unless the user explicitly accepts focus risk for a controlled local MT5 run. |
| Runtime | ALLOW_MT5_HIDDEN_DESKTOP_ACK is not enabled | True | Environment variable is empty. | Unset ALLOW_MT5_HIDDEN_DESKTOP_ACK unless the user explicitly accepts focus risk for a controlled local MT5 run. |
| Runtime | Unlock file is absent | True | work\ALLOW_MT5_LOCAL_LAUNCH.unlock | Remove work\ALLOW_MT5_LOCAL_LAUNCH.unlock unless a controlled local MT5 run is intentionally allowed. |
| Runtime | Hidden desktop ack file is absent | True | work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock | Remove work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock unless a controlled local MT5 run is intentionally allowed. |
| Runtime | Hard local launch lock is present | True | work\MT5_LOCAL_LAUNCH_DISABLED.lock | Restore work\MT5_LOCAL_LAUNCH_DISABLED.lock while local MT5 can steal focus on this PC. |
| Runtime | Quiet PC mode stop marker status is recorded | True | Present: True; path: work\STOP_MT5_FOCUS_WATCHDOG | Create work\STOP_MT5_FOCUS_WATCHDOG while the user needs no resident watchdog or visible helper process. |
| Guard | Launch guard script exists | True | work\assert_mt5_launch_allowed.ps1 | Restore work\assert_mt5_launch_allowed.ps1. |
| Guard | Launch guard has broad MT5 process list | True | work\assert_mt5_launch_allowed.ps1 | Guard must stop terminal/metatester/MetaEditor variants. |
| Guard | Launch guard requires env flag | True | work\assert_mt5_launch_allowed.ps1 | Guard must require ALLOW_MT5_FOCUS_RISK=1. |
| Guard | Launch guard requires hidden desktop ack | True | work\assert_mt5_launch_allowed.ps1 | Guard must require ALLOW_MT5_HIDDEN_DESKTOP_ACK=1. |
| Guard | Launch guard requires unlock file | True | work\assert_mt5_launch_allowed.ps1 | Guard must require work\ALLOW_MT5_LOCAL_LAUNCH.unlock. |
| Guard | Launch guard requires hidden desktop ack file | True | work\assert_mt5_launch_allowed.ps1 | Guard must require work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock. |
| Guard | Launch guard honors hard lock | True | work\assert_mt5_launch_allowed.ps1 | Guard must stop when work\MT5_LOCAL_LAUNCH_DISABLED.lock exists. |
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
| Runner scripts | All MT5 runner scripts source the launch guard | True | Runner scripts checked: 58; unguarded: 0 | Add . (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1") near the top of each runner. |
| Runner scripts | No runner bypasses Start-MT5Hidden with raw terminal launch | True | Raw terminal launch matches: 0 | Route tester launches through Start-MT5Hidden and the guard. |
| Watchdog | Watchdog script exists | True | work\mt5_focus_watchdog.ps1 | Restore work\mt5_focus_watchdog.ps1. |
| Watchdog | Watchdog targets MT5 and MetaEditor | True | work\mt5_focus_watchdog.ps1 | Watchdog must stop terminal64, metatester64, and MetaEditor. |
| Watchdog | Watchdog default is bounded for quiet PC use | True | work\mt5_focus_watchdog.ps1 | Keep the default watchdog run short unless the user explicitly asks for a resident safety net. |
| Watchdog | Hidden watchdog starter exists | True | work\start_mt5_focus_watchdog_hidden.ps1 | Restore work\start_mt5_focus_watchdog_hidden.ps1. |
| Watchdog | Hidden watchdog starter uses detached no-window launch | True | work\start_mt5_focus_watchdog_hidden.ps1 | Start the focus watchdog through detached hidden process creation, not a visible shell. |
| Watchdog | Watchdog process state matches quiet shield mode | True | No running watchdog process detected by CIM; stop marker present: True | Use work\start_mt5_focus_watchdog_hidden.ps1 for an active hidden shield, or work\stop_mt5_focus_watchdog.ps1 for no resident helper. |
| Handoff configs | Current handoff integrity has no failures | True | Rows: 20; failures: 0 | Rerun work\audit_handoff_config_integrity.ps1 and fix any failed handoff config. |

## Runner Script Coverage

| File | Guard | Hidden Helper | Raw Terminal Start |
|---|---|---|---|
| `probe_2024_h1_real_ticks.ps1` | True | True | False |
| `probe_2024_h1_real_ticks_v2.ps1` | True | True | False |
| `probe_2025_h2_direction_real_ticks.ps1` | True | True | False |
| `probe_bos_sweep_profit_extensions.ps1` | True | True | False |
| `probe_bos_sweep_variants_clean.ps1` | True | True | False |
| `probe_date_sell_block_real_ticks.ps1` | True | True | False |
| `probe_directional_confirmations_real_ticks.ps1` | True | True | False |
| `probe_equity_drawdown_guard_real_ticks.ps1` | True | True | False |
| `probe_general_regime_stress_clean.ps1` | True | True | False |
| `probe_losing_quarters_real_ticks.ps1` | True | True | False |
| `probe_monthly_confirmation_filters.ps1` | True | True | False |
| `probe_monthly_no_trail.ps1` | True | True | False |
| `probe_monthly_regime_filters.ps1` | True | True | False |
| `probe_mtf_slope_direction_no_date_real_ticks.ps1` | True | True | False |
| `probe_mtf_slope_sell_block_real_ticks.ps1` | True | True | False |
| `probe_risk16_neighborhood.ps1` | True | True | False |
| `probe_robust_profile_variants_clean.ps1` | True | True | False |
| `probe_signal_timeframes_no_date_real_ticks.ps1` | True | True | False |
| `probe_sl18_profit_extensions.ps1` | True | True | False |
| `resume_buy3_sell2_monthly.ps1` | True | True | False |
| `run_adaptive_real_tick_windows.ps1` | True | True | False |
| `run_external_mt5_validation_package_local.ps1` | True | True | False |
| `run_first_pass_package_hidden.ps1` | True | True | False |
| `run_full_real_tick_default.ps1` | True | True | False |
| `run_monthly_real_ticks.ps1` | True | True | False |
| `run_mt5_fast_windows.ps1` | True | True | False |
| `run_quarterly_real_ticks.ps1` | True | True | False |
| `run_real_tick_windows.ps1` | True | True | False |
| `run_walk_forward_real_ticks.ps1` | True | True | False |
| `sweep_2024_candidates.ps1` | True | True | False |
| `sweep_2024_candidates_2.ps1` | True | True | False |
| `sweep_2025_adaptive_candidates.ps1` | True | True | False |
| `sweep_adaptive_thresholds.ps1` | True | True | False |
| `sweep_weak_half_fast.ps1` | True | True | False |
| `test_adaptive_candidate_windows.ps1` | True | True | False |
| `test_adaptive_candidate_windows_short.ps1` | True | True | False |
| `test_top_candidates_windows.ps1` | True | True | False |
| `validate_adaptive_candidates_real_ticks.ps1` | True | True | False |
| `validate_bos_sweep_splits_clean.ps1` | True | True | False |
| `validate_bos_sweep_windows_clean.ps1` | True | True | False |
| `validate_conf3_standard_real_ticks.ps1` | True | True | False |
| `validate_date_buy_block_standard_real_ticks.ps1` | True | True | False |
| `validate_date_sell_block_standard_real_ticks.ps1` | True | True | False |
| `validate_directional_candidate_quarters.ps1` | True | True | False |
| `validate_directional_candidate_splits.ps1` | True | True | False |
| `validate_equity_dd4_splits.ps1` | True | True | False |
| `validate_h4_no_date_splits.ps1` | True | True | False |
| `validate_momentum_sweep_monthly_clean.ps1` | True | True | False |
| `validate_momentum_sweep_quarters_clean.ps1` | True | True | False |
| `validate_momentum_sweep_splits_clean.ps1` | True | True | False |
| `validate_no_be_strict_loss_walk_forward_real_ticks.ps1` | True | True | False |
| `validate_no_be_strict_loss_yearly_full_real_ticks.ps1` | True | True | False |
| `validate_no_be_walk_forward_real_ticks.ps1` | True | True | False |
| `validate_no_date_buy_only_quarters.ps1` | True | True | False |
| `validate_no_trail_quarters_clean.ps1` | True | True | False |
| `validate_no_trail_splits.ps1` | True | True | False |
| `validate_second_buy_block_standard_real_ticks.ps1` | True | True | False |
| `validate_strict_loss_walk_forward_real_ticks.ps1` | True | True | False |
