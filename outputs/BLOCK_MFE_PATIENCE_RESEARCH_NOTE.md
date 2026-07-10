# Block MFE Patience Research Note

Date: 2026-07-09

## Purpose

Retested MFE giveback exits with runner patience against the stronger May/June-blocked candidates and the 1.15 risk variant.

## Validation Package

- Package: `work/local_mt5_block_mfe_patience_package`
- Manifest: `outputs/BLOCK_MFE_PATIENCE_MANIFEST.csv`
- Run: `outputs/LOCAL_MT5_BLOCK_MFE_PATIENCE_RUN.csv`
- Results: `outputs/LOCAL_MT5_BLOCK_MFE_PATIENCE_LOG_RESULTS.csv`
- Summary: `outputs/LOCAL_MT5_BLOCK_MFE_PATIENCE_LOG_SUMMARY.csv`
- Restore compile: `outputs/BLOCK_MFE_PATIENCE_RESTORE_FULL_COMPILE.log`

## Result

No promotion.

All MFE patience variants matched their baselines exactly.

| Profile | Continuous | YTD | Full 2025 | Weak Sum | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| base | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| base_mfe_patience | 801.84 | 84.72 | 124.51 | -255.33 | 3 |
| block | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block_mfe_patience | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block_mfe_earlier | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block_mfe_loose | 801.84 | 84.72 | 124.51 | -84.88 | 1 |
| block115 | 806.46 | 98.84 | 153.90 | -106.10 | 1 |
| block115_mfe_patience | 806.46 | 98.84 | 153.90 | -106.10 | 1 |
| block115_mfe_earlier | 806.46 | 98.84 | 153.90 | -106.10 | 1 |
| block115_mfe_loose | 806.46 | 98.84 | 153.90 | -106.10 | 1 |

## Decision

Do not promote MFE patience for the current candidate family.

The next useful work should focus on entries and regime selection because exit overlays are not changing the tested trade paths.
