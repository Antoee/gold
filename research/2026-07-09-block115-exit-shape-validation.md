# Block115 Exit Shape Validation - 2026-07-09

## Purpose

Test whether the new aggressive `block_r115` candidate can produce more profit through modest stop, target, or trailing changes.

## Method

Built `work/build_block115_exit_shape_package.ps1` and ran 56 hidden MT5 tests using the compact-source workflow.

Parsed summary: `outputs/LOCAL_MT5_BLOCK115_EXIT_SHAPE_LOG_SUMMARY.csv`

## Results

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `block115_base` | 806.46 | 98.84 | 153.90 | 806.46 | -106.10 | -106.10 | Keep as aggressive candidate |
| `block115_trail14` | 54.49 | 98.84 | -352.65 | 54.49 | -93.40 | -352.65 | Reject |
| `block115_trail20` | 9.28 | 98.84 | -415.85 | 9.28 | -106.25 | -415.85 | Reject |
| `block115_sl20_tp45` | -37.08 | 175.44 | 146.26 | -37.08 | -106.10 | -106.10 | Reject |
| `block115_sl16_tp42` | -43.65 | 156.45 | 113.91 | -43.65 | -103.90 | -103.90 | Reject |
| `block115_tp45` | -43.73 | 156.40 | 144.38 | -43.73 | -106.10 | -106.10 | Reject |
| `block115_sl16_tp38` | -49.40 | 137.42 | 51.09 | -49.40 | -103.90 | -103.90 | Reject |
| `block115_tp40` | -53.01 | 132.44 | 93.12 | -53.01 | -106.10 | -106.10 | Reject |

## Interpretation

The current exit shape is fragile. Higher targets, wider stops, and trailing changes improved some 2026 windows but destroyed 2024/continuous performance.

## Decision

Keep `block115_base` unchanged as the only aggressive candidate from this batch.
