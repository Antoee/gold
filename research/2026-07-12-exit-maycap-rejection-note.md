# 2026-07-12 Exit Expansion And May-Cap Rejection

## Decision

Do not promote the exit-expansion or May lot-cap profiles.

The current research best remains:

`outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set`

## Evidence

Validation summary:

`outputs/CURRENT_BEST_EXIT_MAYCAP_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base_range_elite | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| qtp_conservative | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| runner_conservative | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| may325_lot042 | 1485.56 | 1217.07 | 214.30 | 1485.56 | 0.00 | 0 |
| may325_lot042_runner | 1485.56 | 1217.07 | 214.30 | 1485.56 | 0.00 | 0 |
| may325_lot045 | 1575.05 | 1198.65 | 214.30 | 1575.05 | -216.06 | 1 |

## Reason For Rejection

- Conservative quality-TP scaling and runner expansion were identical to baseline, which means their activation gates did not affect the current trade set.
- May risk plus lot cap improved 2026 YTD slightly, but it severely damaged 2024 and continuous performance.
- The `0.45` lot cap also introduced a losing validation window.

## Next Work

The next exit-focused work should not be another parameter-only QTP/runner pass. Better candidates:

- Add trade-level MFE/MAE export columns and analyze whether winners had unused room.
- Lower runner activation only after seeing quality/price-action distributions at entry.
- Test structural stop refinements that preserve 2024 and do not depend on increasing May risk.
