# First-Day Damage Control Validation - 2026-07-09

## Purpose

Test whether existing fast-exit controls can reduce the first-trading-day weak-month losses without deleting early-month winners.

## Method

Built `work/build_first_day_damage_control_package.ps1` and ran 56 hidden MT5 tests using the compact-source workflow.

Parsed summary: `outputs/LOCAL_MT5_FIRST_DAY_DAMAGE_CONTROL_LOG_SUMMARY.csv`

## Results

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `calendar_block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Diagnostic |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Benchmark |
| `early_mfe_reversal` | 801.84 | 84.72 | -394.95 | 801.84 | -249.35 | -394.95 | Reject |
| `no_follow_fast` | 759.09 | 84.72 | 94.48 | 759.09 | -224.95 | -99.55 | Reject |
| `combo_fast` | 759.09 | 84.72 | 94.48 | 759.09 | -224.95 | -99.55 | Reject |
| `combo_gentle` | 756.29 | 84.72 | 124.51 | 756.29 | -255.33 | -99.55 | Reject |
| `mfe_failure_fast` | 748.91 | 84.72 | 124.51 | 748.91 | -245.85 | -99.55 | Reject |
| `underwater_fast` | 748.91 | 84.72 | 124.51 | 748.91 | -255.33 | -99.55 | Reject |

## Interpretation

Fast exits modestly reduced some weak-window loss, but the cost to continuous and 2024 profit was larger than the benefit. `early_mfe_reversal` preserved 2024 but broke 2025 badly.

## Decision

Do not promote the fast-exit damage-control profiles.
