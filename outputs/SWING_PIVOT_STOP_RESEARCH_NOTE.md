# Swing Pivot Stop Research Note

Date: 2026-07-09

## Purpose

Tested a default-off confirmed swing pivot stop that can use the nearest validated swing low/high as the initial stop anchor, with ATR and point buffers.

## Validation Package

- Package: `work/local_mt5_swing_pivot_stop_package`
- Manifest: `outputs/SWING_PIVOT_STOP_MANIFEST.csv`
- Compact run: `outputs/LOCAL_MT5_SWING_PIVOT_STOP_COMPACT_RUN.csv`
- Results: `outputs/LOCAL_MT5_SWING_PIVOT_STOP_LOG_RESULTS.csv`
- Summary: `outputs/LOCAL_MT5_SWING_PIVOT_STOP_LOG_SUMMARY.csv`
- Compact compile: `outputs/SWING_PIVOT_STOP_COMPACT_COMPILE.log`
- Restore compile: `outputs/SWING_PIVOT_STOP_RESTORE_FULL_COMPILE.log`

## Result

No promotion.

All tested swing-pivot stop variants produced identical results to their baselines.

| Profile | Continuous | YTD | Full 2025 | Weak Sum | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| base | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| base_sps_tight | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| base_sps_loose | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| base_sps_replace | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| block | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block_sps_tight | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block_sps_loose | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block115 | 806.46 | 98.84 | 153.90 | -106.10 | 1 |
| block115_sps_tight | 806.46 | 98.84 | 153.90 | -106.10 | 1 |
| block115_sps_loose | 806.46 | 98.84 | 153.90 | -106.10 | 1 |

## Decision

Keep the code default-off for future experiments, but do not promote any swing pivot stop profile.

This suggests the current candidate family is not being limited by simple initial stop anchoring. The next search should target entry frequency, regime selection, or exit asymmetry rather than another small stop-shape tweak.
