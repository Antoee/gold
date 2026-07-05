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
| Watchdog | Watchdog process is visible or can be restarted | True | Running watchdog PIDs: 38832 | Start work\mt5_focus_watchdog.ps1 if a local safety net is needed. |
| Handoff configs | Current handoff integrity has no failures | True | Rows: 24; failures: 0 | Rerun work\audit_handoff_config_integrity.ps1 and fix any failed handoff config. |

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
