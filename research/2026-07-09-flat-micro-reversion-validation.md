# Flat-Month Micro-Reversion Validation

Date: 2026-07-09

## Purpose

Try to address the flat-month opportunity problem with a new default-off entry lane instead of raw risk escalation.

The new lane is designed for quiet/flat periods:

- activates only when flat-month opportunity mode is active,
- uses small risk through `InpFlatMonthMicroReversionRiskMultiplier`,
- requires a rejection candle,
- can require liquidity sweep/failed-breakout evidence,
- can require VWAP magnet evidence,
- uses structural stop and mean/ATR target rather than a plain ATR stop,
- enforces spacing after recent entries to reduce whipsaw clustering.

The test also included variants with `InpUseAdaptiveReverse=false` to measure whether disabling adaptive reverse improves the current candidate.

## Code Added

New default-off inputs:

- `InpUseFlatMonthMicroReversionLane`
- `InpFlatMonthMicroReversionRiskMultiplier`
- `InpFlatMonthMicroReversionMaxMonthlyEntries`
- `InpFlatMonthMicroReversionSpacingMinutes`
- `InpFlatMonthMicroReversionMaxADX`
- `InpFlatMonthMicroReversionMinWickPercent`
- `InpFlatMonthMicroReversionMinCloseLocation`
- `InpFlatMonthMicroReversionMinRangeATR`
- `InpFlatMonthMicroReversionRequireLiquidity`
- `InpFlatMonthMicroReversionRequireVWAP`
- `InpFlatMonthMicroReversionMaxVWAPDistanceATR`
- `InpFlatMonthMicroReversionStopBufferATR`
- `InpFlatMonthMicroReversionStopBufferPoints`
- `InpFlatMonthMicroReversionFallbackTPATR`
- `InpFlatMonthMicroReversionMinRR`

## Validation Setup

Base sets:

- `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`
- `outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`

Windows:

- `2024_to_2026`
- `2026_ytd`
- `2025_full`
- `2024_full`
- `2026_03`
- `2026_05`
- `2026_06`

## Results

| Profile | Continuous | YTD | 2025 | 2024 | Weak Sum | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | 1 |
| `block_no_adapt` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | 1 |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | 3 |
| `block_fmr_strict` | 785.35 | 84.72 | 124.51 | 785.35 | -84.88 | -84.88 | 1 |
| `block_fmr_loose` | 785.35 | 84.72 | 124.51 | 785.35 | -84.88 | -84.88 | 1 |
| `block_fmr_strict_no_adapt` | 785.35 | 84.72 | 124.51 | 785.35 | -84.88 | -84.88 | 1 |
| `base_fmr_strict` | 785.35 | 84.72 | 124.51 | 785.35 | -255.33 | -99.55 | 3 |
| `base_fmr_loose` | 785.35 | 84.72 | 124.51 | 785.35 | -255.33 | -99.55 | 3 |

## Decision

Reject promotion. Keep the lane default-off.

Rationale:

- The lane reduced the best continuous result from 801.84 to 785.35.
- It did not repair 2026 YTD or the weak 2026 months.
- It did not improve the May/June blocked risk-calendar candidate.
- Disabling adaptive reverse was neutral in this validation, so adaptive reverse is not the current bottleneck in these windows.

The code remains useful as a configurable research hook, but it should not be enabled in the current best set.

## Artifacts

- `work/build_flat_micro_reversion_package.ps1`
- `outputs/FLAT_MICRO_REVERSION_MANIFEST.csv`
- `outputs/LOCAL_MT5_FLAT_MICRO_REVERSION_RUN.csv`
- `outputs/LOCAL_MT5_FLAT_MICRO_REVERSION_LOG_RESULTS.csv`
- `outputs/LOCAL_MT5_FLAT_MICRO_REVERSION_LOG_SUMMARY.csv`
- `outputs/FLAT_MICRO_REVERSION_FULL_COMPILE.log`
- `outputs/FLAT_MICRO_REVERSION_COMPACT_COMPILE.log`
- `outputs/FLAT_MICRO_REVERSION_FINAL_FULL_COMPILE.log`
