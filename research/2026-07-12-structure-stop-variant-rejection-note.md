# Structure Stop Variant Rejection Note - 2026-07-12

## Summary

The current research-best profile already uses liquidity-aware structural stops. This pass tested whether additional structural stop features could improve profit while moving farther away from pure ATR stops.

One code-quality improvement was kept:

- Swing pivot stop controls were converted from plain globals to MT5 `input` parameters.
- Patch: `patches/2026-07-12-swing-pivot-stop-inputs.patch`

This makes confirmed swing pivot stops optimizable in future tester packages.

## Tested Variants

Validation files:

- `outputs/STRUCTURE_STOP_VARIANT_LOG_RESULTS.csv`
- `outputs/STRUCTURE_STOP_VARIANT_LOG_SUMMARY.csv`

Baseline to beat:

- Current research-best continuous 2024-2026: `7756.74`
- Current research-best 2026 YTD: `1375.04`
- Current research-best full 2024: `2459.19`
- Current research-best full 2025: `214.18`

Variant results:

- `pivot_tight`
  - Full 2024: `2450.89`
  - Full 2025: `214.18`
  - 2026 YTD: `857.00`
  - Continuous 2024-2026: `7661.13`
- `pivot_replace`
  - Full 2024: `2455.62`
  - Full 2025: `214.18`
  - 2026 YTD: `532.73`
  - Continuous 2024-2026: `6649.39`
- `pivot_wide`
  - Full 2024: `2431.73`
  - Full 2025: `214.18`
  - 2026 YTD: `534.75`
  - Continuous 2024-2026: `6644.52`
- `liq_cluster`
  - Full 2024: `945.01`
  - Full 2025: `184.54`
  - 2026 YTD: `666.63`
  - Continuous 2024-2026: `945.01`
- `liq_prevday`
  - Full 2024: `54.60`
  - Full 2025: `8.86`
  - 2026 YTD: `521.05`
  - Continuous 2024-2026: `63.46`
- `pivot_cluster`
  - Full 2024: `945.01`
  - Full 2025: `184.54`
  - 2026 YTD: `372.28`
  - Continuous 2024-2026: `945.01`

## Decision

Reject all tested structural-stop variants for promotion.

`pivot_tight` was the closest candidate, but it still reduced both continuous performance and 2026 YTD. The liquidity cluster and previous-day stop extensions were too damaging in this profile.

The current research-best profile remains:

- `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set`

## Validation

- Compact compile: `outputs/MT5_HIDDEN_COMPILE_STRUCTURE_STOP_VARIANT.log`
- Result: `0 errors, 0 warnings`
- Local MT5 safety audit: `PASS`, 39/39 checks
