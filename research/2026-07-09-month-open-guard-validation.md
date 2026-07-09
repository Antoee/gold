# Month Open Guard Validation - 2026-07-09

## Purpose

Diagnose whether the 2026 weak-month losses are broad monthly chop or a narrower monthly-open failure.

The tested package used existing month-start style filters and a combined day-three plus weak-regime/MFE profile to see whether avoiding the first trading days improves the weak windows.

## Weak-Month Diagnosis

The base profile's weak 2026 windows were each driven by one early first-trading-day trade:

| Window | Entry | Direction | Entry Price | Stop | Exit | Net |
| --- | --- | --- | ---: | ---: | --- | ---: |
| `2026_03` | 2026.03.02 07:15 | sell | 5350.15 | 5371.37 | 2026.03.02 08:14:58 | -84.88 |
| `2026_05` | 2026.05.01 08:15 | buy | 4614.44 | 4605.39 | 2026.05.01 08:59:58 | -99.55 |
| `2026_06` | 2026.06.01 07:00 | buy | 4516.29 | 4509.20 | 2026.06.01 09:29:58 | -70.90 |

This is not an all-month chop problem. It is a monthly-open/session-discovery problem.

## Method

Built `work/build_month_open_guard_package.ps1` and ran 35 hidden MT5 tests using the compact-source workflow.

Windows:

- `2024_to_2026`
- `2026_ytd`
- `2025_full`
- `2024_full`
- `2026_03`
- `2026_05`
- `2026_06`

Parsed summary: `outputs/LOCAL_MT5_MONTH_OPEN_GUARD_LOG_SUMMARY.csv`

## Results

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Diagnostic only |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Benchmark |
| `day3_weak_mfe` | 558.95 | 307.02 | 113.44 | 558.95 | 247.50 | -91.89 | Reject as broad profile |
| `month_start_day2` | 557.99 | 84.72 | 124.51 | 557.99 | 74.26 | -97.92 | Reject |
| `month_start_day3` | 541.82 | -270.44 | 113.44 | 541.82 | 322.19 | -270.44 | Reject |

## Interpretation

Blocking the first one or two trading days strongly improves the March/May/June weak-window sum, but it also damages the broader continuous and 2024 windows. The day-three combined profile raises 2026 YTD from `84.72` to `307.02`, but continuous profit falls from `801.84` to `558.95`.

The result validates the failure diagnosis but rejects broad day blocking as too blunt.

## Decision

Do not promote the existing month-start filter as a primary candidate.

Next step: implement a default-off targeted monthly-open discovery guard that only blocks early monthly-open entries lacking an opening-range breakout confirmation, with quality/BOS bypasses for strong signals.
