# FMR Location Extreme Probe Note

Date: 2026-07-12

## Purpose

Test a stricter flat-month micro-reversion variant aimed at the flat-month efficiency bottleneck without enabling Adaptive Reverse or adding grid/martingale behavior.

The code change makes strict flat-month micro-reversion require both:

- the existing VWAP magnet strict mode, via `InpFlatMonthMicroReversionRequireVWAP=true`,
- a nearby structural/liquidity extreme such as equal levels, previous-day liquidity, session sweep, or Asian range sweep.

This is intended to keep any extra flat-window probing tied to real market structure instead of pure ATR placement.

## Tester Input Issue

The full local EA source exceeded MT5 Strategy Tester's input-parameter ceiling:

- Full source after first attempt: `1553` inputs, rejected.
- After locking Adaptive Reverse internals off: `1516` inputs, still rejected.
- After freezing dormant generic flat-month probe controls: `1449` inputs, still rejected.

The usable path is the compact tester source:

- Compact source: `outputs/FMR_LOCATION_EXTREME_COMPACT.mq5`
- Compact audit: `outputs/FMR_LOCATION_EXTREME_COMPACT_AUDIT.csv`
- Kept tester inputs: `334`
- Converted globals: `1105`

Decision: use compact tester builds for validation packages. Do not compile the full local source directly for MT5 Strategy Tester until the input surface is reduced much further.

## Test

- Package: `outputs/realtick_fmr_location_extreme_probe_package`
- Runner CSV: `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_RUN.csv`
- Parsed results: `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_LOG_RESULTS.csv`
- Diff: `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_DIFF.csv`
- Profile summary: `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_PROFILE_SUMMARY.csv`
- Decision summary: `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_DECISION_SUMMARY.csv`
- Tester model: `Model=4`
- Evidence type: parsed tester-log final balances

## Result

| Profile | Parsed Windows | Total Net | Losing Windows | Worst Window | Best Window |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7 / 7` | `+$204.86` | `1` | `-$44.64` | `+$107.82` |
| `fmr_location_extreme` | `7 / 7` | `+$204.86` | `1` | `-$44.64` | `+$107.82` |

Decision summary:

| Metric | Value |
| --- | ---: |
| `fmr_location_extreme` wins | `0` |
| `dec_islp_off` wins | `0` |
| Ties | `7` |
| Total delta | `$0.00` |

## Decision

Do not promote the FMR location-extreme profile.

The code-level strict-mode hook is safe to keep because it is inactive unless `InpFlatMonthMicroReversionRequireVWAP=true`, but the tested candidate did not improve the current profile. Current research-best remains `Score7 Regime No-M1-Shock Dec-ISLP-Off`.

## Safety

- Adaptive Reverse is now internally locked off in local source to reduce whipsaw risk and lower tester input count.
- Dormant generic flat-month probe/stale/missed-move/breakout-probe controls were frozen as globals in local source.
- Active current-best lanes remain configurable: flat-month opportunity mode, structural displacement, micro-reversion, and ISLP.
- Local MT5 safety audit after the run passed `39 / 39`.
