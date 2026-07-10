# Flat Breakout Probe Research Note

Date: 2026-07-09

## Purpose

Tested a default-off flat-month breakout probe lane intended to add carefully filtered entries during under-traded or flat monthly regimes.

## Validation Package

- Package: `work/local_mt5_flat_breakout_probe_package`
- Manifest: `outputs/FLAT_BREAKOUT_PROBE_MANIFEST.csv`
- Run CSV: `outputs/LOCAL_MT5_FLAT_BREAKOUT_PROBE_RUN.csv`
- Results: `outputs/LOCAL_MT5_FLAT_BREAKOUT_PROBE_LOG_RESULTS.csv`
- Summary: `outputs/LOCAL_MT5_FLAT_BREAKOUT_PROBE_LOG_SUMMARY.csv`
- Restore compile: `outputs/FLAT_BREAKOUT_PROBE_RESTORE_FULL_COMPILE.log`

## Result

Rejected for promotion.

The probe damaged the safer base/block profiles and only produced a tiny improvement on the aggressive `block115` profile.

| Profile | Continuous | YTD | Full 2025 | Weak Sum | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| base | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| base_fmb_bal | 785.35 | 84.72 | 124.51 | -255.33 | 3 |
| block | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block_fmb_bal | 785.35 | 84.72 | 124.51 | -84.88 | 1 |
| block115 | 806.46 | 98.84 | 153.90 | -106.10 | 1 |
| block115_fmb_bal | 807.92 | 98.84 | 153.90 | -106.10 | 1 |

## Decision

Keep the code default-off for future research, but do not promote any flat breakout probe candidate.

The `block115_fmb_bal` improvement over `block115` is only `+1.46` on the continuous window and `+2.92` total across the validation pack. That is not enough edge to justify added complexity or overfit risk.

## Next Direction

Focus on higher-impact changes:

- non-ATR-only structure stops,
- better adverse-regime avoidance without calendar fitting,
- reducing whipsaw risk in adaptive reverse logic,
- finding entries that improve 2025 and 2026 without damaging 2024.
