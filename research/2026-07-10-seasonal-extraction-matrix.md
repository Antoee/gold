# 2026-07-10 Seasonal Extraction Matrix

## Purpose

Try to increase profit inside the already validated March/May seasonal profile instead of forcing trades into weak months.

## Fast Triage

File: `outputs/LOCAL_MT5_SEASONAL_EXTRACTION_MATRIX_LOG_SUMMARY.csv`

Fast-model profiles tested:

- stable March 1.00 / May 2.25
- March 2.00 / May 2.25
- March 1.00 / May 2.65
- equity profit lock / peak trail
- MFE runner lock
- house-money scale-in
- guarded profit boost

Fast triage showed no red windows for most profiles, but several apparent improvements were caused by overlapping windows or weakened continuous performance.

## Real-Tick Shortlist

File: `outputs/LOCAL_MT5_SEASONAL_EXTRACTION_SHORTLIST_REALTICK_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | 2026 YTD | 2025 Full | 2024 Full | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| may265_guarded | 7/7 | 3510.82 | 1277.57 | 158.91 | 214.30 | 1277.57 | 0 | 0 |
| stable_mar1_may225 | 7/7 | 3451.27 | 1277.57 | 158.91 | 214.30 | 1277.57 | 0 | 0 |
| mfe_runner_lock | 7/7 | 2986.27 | 1178.72 | 169.33 | 242.38 | 1178.72 | 0 | 0 |
| profit_boost_guarded | 7/7 | 3190.49 | 725.01 | 749.46 | -24.35 | 725.01 | -24.35 | 1 |

## Decision

Do not promote any new profile from this matrix.

Reasons:

- `may265_guarded` only improved the isolated 2026 May slice. The broader 30-month real-tick monthly sweep already showed May 2.65 underperforming May 2.25.
- `mfe_runner_lock` improved 2026 YTD and 2025 slightly, but reduced continuous 2024-2026 performance.
- `profit_boost_guarded` created a negative 2025 full window in real ticks.
- `house_money_scale` matched stable behavior in fast triage and did not justify real-tick promotion.

## Current Best Candidate

Keep `outputs/CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set`.

Stable real-tick broad validation:

- TotalNet: 3451.27
- Continuous 2024-2026: 1277.57
- 2026 YTD: 158.91
- 2025 Full: 214.30
- 2024 Full: 1277.57
- WorstWindow: 0
- LosingWindows: 0
