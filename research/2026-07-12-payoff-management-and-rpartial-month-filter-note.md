# Payoff Management and R-Partial Month Filter Note

Date: 2026-07-12

## Purpose

Test whether improving exits on the current research-best profile can raise profit without adding new weak-month entry exposure.

Base profile:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set`

## Payoff Management Probe

Evidence:

- Summary: `outputs/CURRENT_BEST_PAYOFF_MANAGEMENT_MODEL0_PROBE_LOG_SUMMARY.csv`
- Results: `outputs/CURRENT_BEST_PAYOFF_MANAGEMENT_MODEL0_PROBE_LOG_RESULTS.csv`
- Builder: `work/build_current_best_payoff_management_model0_probe_package.ps1`

Model 0 broad-window results:

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base | 6222.35 | 1107.93 | 214.30 | 2390.20 | 0.00 | 0 |
| mfe_lock_balanced | 6633.61 | 720.23 | 214.30 | 2406.27 | 0.00 | 0 |
| mfe_lock_loose_runner | 6456.57 | 706.23 | 214.30 | 2390.20 | 0.00 | 0 |
| partial_runner_lock | 6384.35 | 838.19 | 236.30 | 2071.74 | 0.00 | 0 |
| runner_tp_quality | 6222.35 | 1107.93 | 214.30 | 2390.20 | 0.00 | 0 |
| tp_stretch_mfe_lock | 378.18 | 621.58 | 413.61 | 378.18 | -217.60 | 1 |

Decision: do not promote any global payoff-management profile.

`mfe_lock_balanced` improved continuous profit, but cut 2026 YTD too heavily. `partial_runner_lock` improved some later windows but damaged 2024. `tp_stretch_mfe_lock` is rejected outright because it introduced a losing tested window.

## Monthly Attribution

Evidence:

- Summary: `outputs/CURRENT_BEST_PAYOFF_MONTHLY_ATTRIBUTION_MODEL0_LOG_SUMMARY.csv`
- Results: `outputs/CURRENT_BEST_PAYOFF_MONTHLY_ATTRIBUTION_MODEL0_LOG_RESULTS.csv`
- Builder: `work/build_current_best_payoff_monthly_attribution_model0_package.ps1`

Key deltas versus base:

- `mfe_lock_balanced` improved only `2024_08` by 7.80, but hurt `2026_03` by -349.86.
- `partial_runner_lock` improved `2025_03` by 22.00 and `2026_05` by 116.43, but hurt `2024_03` by -262.11 and `2026_03` by -288.34.

This showed that the partial lock is not a March feature. It is only worth testing as a May-specific overlay.

## R-Partial Month Filter Code

Added default-off inputs:

- `InpUseRPartialProfitLockMonthFilter`
- `InpRPartialProfitLockTradeJanuary` through `InpRPartialProfitLockTradeDecember`

Added helper:

- `RPartialProfitLockMonthAllows()`

Applied the helper to the R-based partial profit lock condition. Defaults preserve existing behavior.

## May-Only Validation

Evidence:

- Summary: `outputs/CURRENT_BEST_RPARTIAL_MONTH_FILTER_MODEL0_LOG_SUMMARY.csv`
- Results: `outputs/CURRENT_BEST_RPARTIAL_MONTH_FILTER_MODEL0_LOG_RESULTS.csv`
- Builder: `work/build_current_best_rpartial_month_filter_model0_package.ps1`
- Multiday parser: `work/collect_local_mt5_log_results_multiday.ps1`

Model 0 broad-window results:

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base | 6222.35 | 1107.93 | 214.30 | 2390.20 | 0.00 | 0 |
| rpartial_may_larger | 6186.21 | 1218.85 | 214.30 | 2390.20 | 0.00 | 0 |
| rpartial_may_only | 6163.17 | 1191.69 | 214.30 | 2390.20 | 0.00 | 0 |
| rpartial_may_smaller | 6112.12 | 1184.85 | 214.30 | 2390.20 | 0.00 | 0 |

Decision: do not replace the current research-best profile.

The May-only partial lock is useful infrastructure and improves recent 2026 YTD, but all tested variants reduce the 2024-2026 continuous run. It can remain available as a recent-performance research branch, but the promoted research-best profile stays unchanged.

## Current Best Status

No promotion from this branch.

Current research-best remains:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set`
- Continuous: 6222.35
- YTD: 1107.93
- Full 2025: 214.30
- Full 2024: 2390.20
- Losing windows: 0

Local MT5 safety audit after testing: PASS 39/39.
