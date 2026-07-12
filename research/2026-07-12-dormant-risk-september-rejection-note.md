# 2026-07-12 Dormant Unlock And Risk Scaling Rejection

## Decision

Do not promote the dormant-month unlock, month-risk scaling, or September-only unlock profiles.

The current research best remains:

`outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set`

## Current Promotion Gate

Any replacement must beat or preserve:

- Continuous 2024-2026: `6763.86`
- 2026 YTD: `1107.93`
- Full 2025: `214.30`
- Full 2024: `2473.48`
- Losing windows: `0`

## Dormant-Month Unlock

Evidence:

`outputs/CURRENT_BEST_DORMANT_MONTH_UNLOCK_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_range_elite | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| unlock_h2_015 | 2068.31 | 1107.93 | 214.30 | 2245.72 | -52.78 | 2 |
| unlock_dormant_020 | 26.38 | 51.37 | 26.43 | 26.38 | -52.78 | 4 |
| unlock_dormant_012 | 26.38 | 51.37 | 26.43 | 26.38 | -52.78 | 4 |

Reason rejected:

- Broad dormant unlock collapsed 2026 YTD and continuity.
- H2-only unlock preserved YTD but introduced losing validation windows.
- November and December were especially damaging in monthly attribution.

## Month-Risk Scaling

Evidence:

`outputs/CURRENT_BEST_MONTH_RISK_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_range_elite | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| may325 | 960.46 | 4353.10 | 214.30 | 960.46 | -216.06 | 1 |
| may350 | 921.68 | 2634.07 | 214.30 | 921.68 | -232.68 | 1 |
| mar110_may325 | -170.52 | 4654.42 | 230.19 | -170.52 | -216.06 | 4 |
| mar115_may325 | -182.69 | 3429.26 | 246.13 | -182.69 | -216.06 | 4 |

Reason rejected:

- May scaling increased 2026 YTD but broke 2024 and long-run continuity.
- March scaling slightly improved 2025 but made the continuous and 2024 windows negative.
- This is not robust profit; it is unstable risk concentration.

## September-Only Unlock

Evidence:

`outputs/CURRENT_BEST_SEPTEMBER_UNLOCK_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_range_elite | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| sep020 | 5580.22 | 1107.93 | 214.30 | 2223.11 | 0.00 | 0 |
| sep015 | 5580.22 | 1107.93 | 214.30 | 2223.11 | 0.00 | 0 |
| sep012 | 5580.22 | 1107.93 | 214.30 | 2223.11 | 0.00 | 0 |

Reason rejected:

- The September-only clue did not survive broad validation.
- It preserved YTD and zero losing windows, but materially reduced continuous and 2024 performance.

## Next Work

The useful direction is not broad dormant-month activation or simple risk scaling. Next work should focus on new trade selection logic that can add 2025 and 2026 opportunities without changing the profitable 2024 path:

- Narrow 2026-specific entry-quality analysis
- Structural stop improvements that reduce premature exits without adding entries
- Exit expansion on existing winners rather than more weak-month entries
- A fresh additive lane gated by current-year behavior and out-of-sample windows
