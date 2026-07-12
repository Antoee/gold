# 2026-07-12 PTC House Strict Validation Rejection

## Decision

Do not promote `ptc_house_strict`.

The profile improved the long continuous 2024-2026 run, but it failed the current promotion gate because it damaged recent unseen behavior and introduced a losing validation window.

## Baseline

Current research best remains:

`outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_PROFILE.set`

This profile keeps:

- Adaptive Reverse disabled
- Flat Month Structural Displacement enabled
- MFE profit-lock restricted to August
- Flat Month Micro Reversion restricted to July/October
- Flat Month Micro Reversion risk multiplier at `0.35`

## Validation Summary

Evidence file:

`outputs/CURRENT_BEST_PTC_HOUSE_STRICT_VALIDATION_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_micro_r035 | 6754.43 | 1107.93 | 214.30 | 2465.45 | 0.00 | 0 |
| ptc_house_strict | 8583.39 | 49.99 | 214.30 | 2507.37 | -44.08 | 1 |

## Reason For Rejection

`ptc_house_strict` added a strong continuous-path improvement, but the improvement is not robust enough to accept:

- 2026 YTD collapsed from `1107.93` to `49.99`.
- 2025 Q4 became a losing window at `-44.08`.
- Prior PTC month-filter salvage probes showed the same recent/YTD weakness when PTC was active.
- Disabling the breakout-continuation dependency made PTC equivalent to baseline, which means the useful portion is not independently robust yet.

The current best profile is unchanged.

## Next Work

Move away from broad PTC activation and test a different strategy-code lane with explicit protection for recent/YTD behavior. Promotion should require:

- Continuous result above `6754.43`
- 2026 YTD at or above `1107.93`
- Full 2025 at or above `214.30`
- Full 2024 at or above `2465.45`
- Zero losing validation windows
