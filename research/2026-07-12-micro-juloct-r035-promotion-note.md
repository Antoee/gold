# Micro July/October R035 Promotion Note

Date: 2026-07-12

## Purpose

Improve flat-month efficiency without enabling Adaptive Reverse and without raising the main March/May/August risk engine. This test focused on the existing Flat Month Micro Reversion lane, which uses structural/liquidity/VWAP-style mean-reversion behavior rather than stop-and-reverse logic.

## Promoted Profile

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_PROFILE.set`
- SHA-256: `223530323A920E174957B67DBA56778B78996A8D2C454161A49665DEC8AB9CDF`

Enabled changes relative to the prior best:

- `InpUseFlatMonthMicroReversionLane=true`
- `InpFlatMonthMicroReversionStandaloneActive=true`
- `InpUseFlatMonthMicroReversionMonthFilter=true`
- `InpFlatMonthMicroReversionRiskMultiplier=0.35`
- `InpFlatMicroRevTradeJuly=true`
- `InpFlatMicroRevTradeOctober=true`
- All other Flat Micro Reversion trade months remain disabled.

## Model 0 Validation

Clean rerun summary:

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|
| previous best | 6633.61 | 1107.93 | 214.30 | 2406.27 | -5.54 | 2 |
| micro_juloct_r035 | 6754.43 | 1107.93 | 214.30 | 2465.45 | 9.64 | 0 |

The promoted profile improves continuous net profit by `120.82`, preserves recent and 2025 behavior, improves 2024, and removes the two losing validation windows seen in the base H2/Q3 slice.

## Notes

Higher micro-reversion risk multipliers were rejected. The initial ladder showed `0.50`, `0.75`, and `1.00` reducing continuous/full-year performance. Broad flat-month expansion was also not promoted because earlier dormant-month unlock tests damaged robustness.

The first validation pass was contaminated by stale tester-log tail data from a timed-out broader ladder run. A clean rerun from a locked/quiet MT5 state confirmed the promotion result.

## Artifacts

- `outputs/CURRENT_BEST_MICRO_REVERSION_LADDER_MODEL0_LOG_SUMMARY.csv`
- `outputs/CURRENT_BEST_MICRO_REVERSION_LADDER_MODEL0_LOG_RESULTS.csv`
- `outputs/CURRENT_BEST_MICRO_JULOCT_R035_VALIDATION_MODEL0_RERUN_LOG_SUMMARY.csv`
- `outputs/CURRENT_BEST_MICRO_JULOCT_R035_VALIDATION_MODEL0_RERUN_LOG_RESULTS.csv`
- `work/build_current_best_micro_reversion_ladder_model0_package.ps1`
- `work/build_current_best_micro_juloct_r035_validation_model0_package.ps1`
- `work/write_promoted_micro_juloct_r035_set.ps1`
