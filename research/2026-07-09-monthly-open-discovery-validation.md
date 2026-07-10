# Monthly Open Discovery Guard Validation - 2026-07-09

## Purpose

Test the new default-off `InpUseMonthlyOpenDiscoveryGuard` code path.

The guard was designed to block early monthly-open trades unless the signal candle confirmed a breakout beyond a same-day opening range. It includes quality, BOS, and liquidity-sweep bypasses.

## Source And Compile

Canonical source hash after sync:

`CA2540D4CA55DFD92BF4AE8DA08B3AF76590EF8166D129E7EAD6A5DB9A2F7F0E`

Compile proof:

- full source: `outputs/MONTHLY_OPEN_DISCOVERY_FULL_COMPILE.log`
- compact source: `outputs/MONTHLY_OPEN_DISCOVERY_COMPACT_COMPILE.log`
- restored full source: `outputs/MONTHLY_OPEN_DISCOVERY_RESTORE_FULL_COMPILE.log`
- all compiled with `0 errors, 0 warnings`

## Method

Built `work/build_monthly_open_discovery_package.ps1` and ran 49 hidden MT5 tests.

Windows:

- `2024_to_2026`
- `2026_ytd`
- `2025_full`
- `2024_full`
- `2026_03`
- `2026_05`
- `2026_06`

Parsed summary: `outputs/LOCAL_MT5_MONTHLY_OPEN_DISCOVERY_LOG_SUMMARY.csv`

## Results

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `calendar_block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Diagnostic |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Benchmark |
| `open_guard_strict` | 557.72 | -286.56 | 123.81 | 557.72 | -249.22 | -286.56 | Reject |
| `open_guard_no_sweep_bypass` | 557.72 | -286.56 | 123.81 | 557.72 | -249.22 | -286.56 | Reject |
| `open_guard_mfe` | 543.01 | -294.01 | 123.81 | 543.01 | -285.75 | -294.01 | Reject |
| `open_guard_early_only` | 542.84 | 84.72 | 123.81 | 542.84 | -285.75 | -99.55 | Reject |
| `open_guard_balanced` | 539.63 | -291.01 | 123.81 | 539.63 | -285.75 | -291.01 | Reject |

## Interpretation

The guard was too blunt. It blocked or delayed profitable early-month 2024 trades and did not reliably remove the 2026 first-day failures.

## Decision

Keep the code default-off for future research, but do not promote any monthly-open discovery profile.
