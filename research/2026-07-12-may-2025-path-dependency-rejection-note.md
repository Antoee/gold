# 2026-07-12 May 2025 Path Dependency Rejection

## Objective

Try to raise the current research-best profile by waking May 2025 without opening broad weak-month exposure.

Current best:

- Profile: `CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`
- Continuous: `6633.61`
- 2026 YTD: `1107.93`
- Full 2025: `214.30`
- Full 2024: `2406.27`
- Losing windows: `0`

## Monthly Attribution

Fresh attribution for the current best showed:

- March is the main engine: `2657.81` standalone net across 2024-2026.
- May works in 2024 and 2026, but May 2025 is dormant.
- August is positive but small.

Source: `outputs/CURRENT_BEST_MFE_AUG_MONTHLY_ATTRIBUTION_MODEL0_LOG_RESULTS.csv`

Key month rows:

| Window | Net |
| --- | ---: |
| 2024_03 | 1497.84 |
| 2025_03 | 214.30 |
| 2026_03 | 945.67 |
| 2024_05 | 214.91 |
| 2025_05 | 0.00 |
| 2026_05 | 485.92 |
| 2024_08 | 92.30 |
| 2025_08 | 59.32 |

## May Wake-Up Probe

Source: `outputs/CURRENT_BEST_MAY2025_WAKEUP_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_mfe_aug | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| may_full_window_r100 | 2109.87 | 901.96 | 214.30 | 2109.87 | 0.00 | 0 |
| may_session_impulse | 2117.62 | 901.96 | 214.30 | 2117.62 | -6.04 | 1 |
| may_power_trend | 2109.87 | 901.96 | 214.30 | 2109.87 | -6.04 | 1 |
| may_breakout_cont | 2109.87 | 49.99 | 214.30 | 2109.87 | -24.16 | 2 |
| may_momentum_combo | 2008.73 | 1128.75 | 180.94 | 2008.73 | -6.86 | 1 |

No promotion. Extending May can wake standalone May 2025, but it damages the broader path.

## Path Dependency Probe

Source: `outputs/CURRENT_BEST_MAY_PATH_DEPENDENCY_MODEL0_LOG_RESULTS.csv`

| Profile | Window | Net |
| --- | --- | ---: |
| base_mfe_aug | 2025_full | 214.30 |
| base_mfe_aug | 2025_mar_to_may | 214.30 |
| base_mfe_aug | 2025_may | 0.00 |
| may_window_r100 | 2025_full | 214.30 |
| may_window_r100 | 2025_mar_to_may | 214.30 |
| may_window_r100 | 2025_apr_to_may | 1308.69 |
| may_window_r100 | 2025_may | 1308.69 |
| may_window_r280 | 2025_full | 214.30 |
| may_window_r280 | 2025_mar_to_may | 214.30 |
| may_window_r280 | 2025_apr_to_may | 2475.99 |
| may_window_r280 | 2025_may | 2475.99 |

Interpretation: May 2025 is not simply blocked by May entry rules. Starting on March 1 prevents the May opportunity, while starting April 1 or later captures it. The blocker is likely March-position/path state.

## Protected Add-On Probe

Source: `outputs/CURRENT_BEST_MAY_PROTECTED_ADDON_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_mfe_aug | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| may_window_r280_max2 | 1085.77 | 493.59 | 39.10 | 1085.77 | 0.00 | 0 |
| may_window_r280_protected_addon | 950.91 | 205.09 | 39.10 | 950.91 | 0.00 | 0 |

Raising the max-position cap and enabling protected winner scale-in does not solve the path problem. It damages the full portfolio too much.

## Decision

No promotion.

May 2025 has attractive isolated profit, but it is path-dependent and cannot be safely harvested with simple May day-window expansion, momentum lanes, or protected add-ons. Current best remains unchanged.

## Next Direction

The next useful work is not more May entry relaxation. It should inspect the March trade lifecycle and state interactions:

- whether March positions remain open into May,
- whether March profit state changes later risk or quality gates,
- whether a specific exit or de-risk rule can free May without sacrificing March's edge.
