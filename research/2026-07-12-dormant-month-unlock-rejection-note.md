# 2026-07-12 Dormant Month Unlock Rejection

## Objective

Test whether the current best profile is leaving easy profit on the table by excluding dormant/flat months from the normal month gate.

Current best:

- Profile: `CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`
- Continuous 2024-01-01 to 2026-07-02: `6633.61`
- 2026 YTD: `1107.93`
- 2025 full: `214.30`
- 2024 full: `2406.27`
- Losing windows: `0`

## Finding

The normal month filter is deliberately carrying a lot of safety. The current best trades March, May, and August. January, April, and June are disabled for normal entries, while flat-month bypass lanes remain available.

Unlocking January/April/June does create trades, but it damages the multi-year path and introduces losing windows. The isolated green results are not strong enough to justify promotion because the path dependency harms later high-value periods.

## Broad Unlock Results

Source: `outputs/CURRENT_BEST_DORMANT_MONTH_UNLOCK_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_mfe_aug | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| unlock_jan_apr_jun_r025 | 1309.62 | 34.68 | 71.27 | 1309.62 | -43.93 | 4 |
| unlock_jan_apr_jun_r050 | 1198.87 | 552.05 | 84.15 | 1198.87 | -66.74 | 4 |
| unlock_jan_apr_jun_breakout | 1309.62 | 34.68 | 71.27 | 1309.62 | -43.93 | 4 |
| month_filter_off_r020 | 1132.25 | 11.16 | 71.27 | 1132.25 | -43.93 | 4 |

## Single-Month Unlock Results

Source: `outputs/CURRENT_BEST_DORMANT_SINGLE_MONTH_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_mfe_aug | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| apr_only_r010 | 3405.99 | 1408.82 | 214.30 | 3033.39 | -43.93 | 2 |
| jan_only_r010 | 1839.92 | 34.68 | 71.27 | 1876.21 | -40.21 | 1 |
| jan_only_r025 | 1839.92 | 34.68 | 71.27 | 1876.21 | -40.21 | 1 |
| jun_only_r010 | 1331.58 | 1107.93 | 214.30 | 1331.58 | -40.14 | 1 |

## Decision

No promotion.

The base profile remains the current research best. Dormant-month normal activation is rejected for now because it creates path damage and losing windows. April-only is interesting as a future research clue because it improves 2026 YTD and 2024 full, but the continuous path is still much worse than the current best.

## Next Work

Stop trying to force normal entries into weak months. The next profit-seeking iteration should focus on extracting more from already validated months and improving exit/hold behavior, especially:

- March/May/August continuation capture
- trade management after strong MFE
- profit-protection that avoids cutting runners too early
- active-month scale-up only after protected equity gains
