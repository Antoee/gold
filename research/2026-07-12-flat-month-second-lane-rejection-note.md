# Flat Month Second-Lane Rejection Note

Date: 2026-07-12

## Purpose

Probe a second flat-month opportunity lane on top of the current MFE-August research-best profile. The goal was to wake the still-dormant target months without adding broad lower-timeframe noise or Adaptive Reverse whipsaw risk.

## Evidence

- Builder: `work/build_current_best_flat_month_second_lane_model0_package.ps1`
- Package: `work/local_mt5_current_best_flat_month_second_lane_model0_package`
- Compact source audit: `outputs/CURRENT_BEST_FLAT_MONTH_SECOND_LANE_MODEL0_COMPACT_SOURCE_AUDIT.csv`
- Compile log: `outputs/CURRENT_BEST_FLAT_MONTH_SECOND_LANE_MODEL0_COMPACT_COMPILE.log`
- Run log: `outputs/CURRENT_BEST_FLAT_MONTH_SECOND_LANE_MODEL0_RUN.csv`
- Parsed results: `outputs/CURRENT_BEST_FLAT_MONTH_SECOND_LANE_MODEL0_LOG_RESULTS.csv`
- Summary: `outputs/CURRENT_BEST_FLAT_MONTH_SECOND_LANE_MODEL0_LOG_SUMMARY.csv`

The run used the compact tester-source workflow because the full EA source exceeds MT5 Strategy Tester's input-parameter limit. The compact source kept 298 tester inputs and converted 1187 unused tester inputs to globals.

## Results

| Profile | Parsed | Expected | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| base_mfe_aug | 9 | 9 | 10362.11 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| fsd_relaxed | 9 | 9 | 10362.11 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| missed_move_wake | 9 | 9 | 10362.11 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| elite_fallback | 9 | 9 | 10362.11 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| breakout_probe | 9 | 9 | 9273.61 | 6697.00 | 51.85 | 214.30 | 2310.46 | 0.00 | 0 |
| guarded_combo | 9 | 9 | 7467.09 | 4878.96 | 63.37 | 214.30 | 2310.46 | 0.00 | 0 |

## Dormant-Month Check

All tested variants stayed inactive in the target dormant windows:

| Window | Base | FSD Relaxed | Breakout Probe | Missed Move | Elite Fallback | Guarded Combo |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2025-01 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2025-04 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2025-06 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2026-01 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 2024-04 guard | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |

## Decision

Do not promote any second-lane variant from this batch.

`breakout_probe` improved the continuous window by `63.39`, but it collapsed 2026 YTD from `1107.93` to `51.85` and reduced Full 2024. The other variants matched baseline exactly and did not wake the dormant months.

Current best remains:

`outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`

## Interpretation

Relaxing existing flat-month lanes is not enough. The dormant-month bottleneck appears to be upstream of the lane-level toggles, likely in the shared global gates, month filters, session filters, or entry-regime gates. The next useful step should diagnose which gate blocks those target months before adding more entry logic.
