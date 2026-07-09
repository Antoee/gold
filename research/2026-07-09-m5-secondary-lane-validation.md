# M5 Tight-Liquidity Secondary Lane Validation

Date: 2026-07-09

## Purpose

Test whether the M5 tight-liquidity/ADX branch can improve the promoted M15 liquidity-stop/chop profile by acting as a secondary lane.

The branch was implemented as optional, default-off inputs so the promoted M15 profile remains unchanged unless explicitly enabled.

## Code Changes

- Added an optional M5 tight-liquidity secondary lane.
- Added direct M5 OHLC calculations for EMA, ATR, and ADX-style trend strength to avoid MT5 lower-timeframe indicator loading failures in Open Prices mode.
- Added direct M5 liquidity stop and per-signal risk multiplier support.
- Added compact tester workflow support for the larger input set.
- Added optional primary-signal override controls, default off:
  - `InpM5TightLiquidityAllowPrimaryOverride`
  - `InpM5TightLiquidityOverrideMaxPrimaryQuality`
  - `InpM5TightLiquidityOverrideRequireSameBias`

## Validation Setup

Base profile:

- `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

Windows:

- `2024_to_2026`: 2024-01-01 to 2026-07-02
- `2026_ytd`: 2026-01-01 to 2026-07-02
- `2025_full`: 2025-01-01 to 2025-12-31
- `2024_full`: 2024-01-01 to 2024-12-31
- Weak 2026 months: March, May, June

Tester notes:

- Full EA compile: pass, 0 errors, 0 warnings.
- Compact tester compile: pass, 0 errors, 0 warnings.
- M15 tester launch could not access lower M5 data in Open Prices mode, so validation was launched on M5 while preserving `InpSignalTimeframe=15`.
- MT5 did not emit HTML reports in this compact local mode, but all tests completed and final balances were parsed from the tester log.

## Results

Baseline promoted M15 profile:

| Window | Net |
| --- | ---: |
| 2024_to_2026 | 801.84 |
| 2026_ytd | 84.72 |
| 2025_full | 124.51 |
| 2024_full | 801.84 |
| 2026_03 | -84.88 |
| 2026_05 | -99.55 |
| 2026_06 | -70.90 |

Best passive secondary variants:

| Profile | Continuous | YTD | 2025 | 2024 | Weak Sum | Min Weak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `m15_peak_plus_m5_r100_cap4_align` | 801.84 | 84.72 | 388.63 | 801.84 | -255.33 | -99.55 |
| `m15_peak_plus_m5_r100_cap8_align` | 801.84 | 84.72 | 388.63 | 801.84 | -255.33 | -99.55 |

Override variants:

| Profile | Continuous | YTD | 2025 | 2024 | Weak Sum | Min Weak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `m15_peak_m5_override_r100_q6` | 801.84 | -298.64 | 388.63 | 801.84 | -255.33 | -99.55 |
| `m15_peak_m5_override_r150_q6` | 801.84 | -301.24 | 138.83 | 801.84 | -255.33 | -99.55 |
| `m15_peak_m5_override_r100_q8` | 801.84 | -298.64 | 388.63 | 801.84 | -255.33 | -99.55 |
| `m15_peak_m5_override_r150_q8` | 801.84 | -301.24 | 138.83 | 801.84 | -255.33 | -99.55 |

## Decision

Do not promote the M5 secondary lane yet.

The passive M5 lane improved isolated 2025 behavior but did not improve the continuous 2024-2026 result or the weak 2026 months. The primary-override mode made 2026 YTD much worse, so it is rejected as a default behavior.

Keep the code default-off as a research branch. The useful takeaway is that M5 tight-liquidity entries can add isolated profit, but the current gate does not solve the flat/weak-month problem. Next work should focus on regime-selective allocation rather than simply adding or overriding trades.

## Artifacts

- `outputs/LOCAL_MT5_M5_SECONDARY_SUMMARY.csv`
- `outputs/LOCAL_MT5_M5_SECONDARY_RANKED.csv`
- `outputs/LOCAL_MT5_M5_SECONDARY_OVERRIDE_SUMMARY.csv`
- `outputs/LOCAL_MT5_M5_SECONDARY_OVERRIDE_RANKED.csv`
- `outputs/M5_SECONDARY_FINAL_FULL_COMPILE.log`
- `outputs/M5_SECONDARY_OVERRIDE_COMPACT_COMPILE.log`
