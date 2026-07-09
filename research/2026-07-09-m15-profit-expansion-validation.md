# M15 Profit Expansion Validation - 2026-07-09

## Purpose

Test profit expansion inside the current M15 engine without increasing raw base risk. This batch focused on exits, runner behavior, partial locks, MFE giveback logic, protected scale-in, and elite continuation.

## Method

Built `work/build_m15_profit_expansion_package.ps1` and ran 56 hidden MT5 tests using the compact-source workflow.

Windows:

- `2024_to_2026`
- `2026_ytd`
- `2025_full`
- `2024_full`
- `2026_03`
- `2026_05`
- `2026_06`

Compile proof:

- compact tester compile: `outputs/M15_PROFIT_EXPANSION_COMPILE.log`
- restored full-source compile: `outputs/M15_PROFIT_EXPANSION_RESTORE_FULL_COMPILE.log`
- both compiled with `0 errors, 0 warnings`

## Results

Parsed summary: `outputs/LOCAL_MT5_M15_PROFIT_EXPANSION_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `mfe_giveback_patience` | 805.55 | 84.72 | 124.51 | 805.55 | -255.33 | -99.55 | Research lead only |
| `block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Risk-control diagnostic |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Benchmark |
| `elite_continuation` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Neutral |
| `protected_runner` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Neutral |
| `protected_scale_in` | 757.50 | 84.72 | 125.47 | 757.50 | -255.33 | -99.55 | Reject |
| `runner_mfe_lock` | 747.99 | 84.72 | 124.51 | 747.99 | -255.33 | -99.55 | Reject |
| `partial_runner` | 643.19 | 58.14 | 109.99 | 643.19 | -255.33 | -99.55 | Reject |

## Interpretation

`mfe_giveback_patience` produced a tiny broad improvement over the benchmark, but it did not improve 2026 YTD or the weak-month cluster. The change is too small to promote by itself.

The May/June risk-control candidate remains the best tested way to reduce weak-window damage, but it is still a calendar diagnostic rather than a true market-regime solution.

## Decision

Do not promote a new profit-expansion profile yet.

Keep:

- primary candidate: `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`
- diagnostic/risk-control candidate: `outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`

Next best direction:

1. Turn the May/June calendar block into a real market-state filter.
2. Explore regime detection using range compression, failed continuation, low MFE, and session liquidity conditions.
3. Keep `mfe_giveback_patience` as a possible small add-on only if it survives broader walk-forward testing.
