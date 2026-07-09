# Weak Regime Filter Validation - 2026-07-09

## Purpose

Test a default-off market-state entry block intended to replace crude month filtering with observable weak-regime conditions.

The filter checks recent net movement versus ATR, candle direction alternation, ADX, and EMA slope. It can optionally allow high-quality liquidity sweep entries through the block.

## Source And Compile

Canonical source: `outputs/Professional_XAUUSD_EA.mq5`

New inputs added:

- `InpUseWeakRegimeEntryBlock`
- `InpWeakRegimeLookbackBars`
- `InpWeakRegimeMaxNetMoveATR`
- `InpWeakRegimeMinAlternationPercent`
- `InpWeakRegimeMaxADX`
- `InpWeakRegimeSlopeLookbackBars`
- `InpWeakRegimeMaxSlopePoints`
- `InpWeakRegimeMinScore`
- `InpWeakRegimeQualityBypassScore`
- `InpWeakRegimeBlockDiagnosticFallback`
- `InpWeakRegimeAllowLiquiditySweep`

Source hash after sync:

`B32D4E4B3C054F6350A54F14FBEB875A6D3ABC437FBBFB24FE5C15A3738AFC27`

Compile proof:

- `outputs/WEAK_REGIME_FULL_COMPILE.log`
- restored full-source compile after package run: `outputs/WEAK_REGIME_FILTER_RESTORE_FULL_COMPILE.log`
- both compiled with `0 errors, 0 warnings`

## Method

Built `work/build_weak_regime_filter_package.ps1` and ran 56 hidden MT5 tests using the compact-source workflow.

Windows:

- `2024_to_2026`
- `2026_ytd`
- `2025_full`
- `2024_full`
- `2026_03`
- `2026_05`
- `2026_06`

Parsed summary: `outputs/LOCAL_MT5_WEAK_REGIME_FILTER_LOG_SUMMARY.csv`

## Results

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `weak_plus_mfe` | 827.33 | 84.72 | 124.51 | 827.33 | -255.33 | -99.55 | Research lead only |
| `weak_balanced` | 806.98 | 84.72 | 124.51 | 806.98 | -255.33 | -99.55 | Research lead only |
| `weak_no_liq_bypass` | 806.98 | 84.72 | 124.51 | 806.98 | -255.33 | -99.55 | Neutral |
| `block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Diagnostic only |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Benchmark |
| `weak_strict` | 611.24 | 84.72 | -284.90 | 611.24 | -255.33 | -284.90 | Reject |
| `weak_fallback_quality` | -333.15 | 84.54 | 95.92 | -371.14 | -287.61 | -371.14 | Reject |

## Interpretation

The weak-regime block plus MFE patience improved the continuous window from `801.84` to `827.33`, but it did not improve the 2026 weak-month cluster. The March, May, and June losses stayed unchanged.

This means the current weak-regime definition is not detecting the real failure mode. It is useful as a small default-off research lead, but it is not a promotion candidate.

## Decision

Do not promote the weak-regime filter yet.

Keep `weak_plus_mfe` as a research profile only. The next improvement should target the first-trading-day monthly-open failure directly using price action around the opening range, instead of broad month or weak-regime blocking.
