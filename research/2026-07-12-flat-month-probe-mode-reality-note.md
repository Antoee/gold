# Flat-Month Probe-Mode Reality Probe

Date: 2026-07-12

## Decision

Rejected.

The older flat-month probe-mode controls were exposed as inputs and tested. They did not add useful trades. Instead, the candidates reduced sizing on existing winners, lowering total net profit.

Current stability-best remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

## Code Change

The dormant flat-month probe-mode controls were changed from normal globals to `input` parameters so MT5 `.set` files can enable and tune them.

Default behavior is unchanged because `InpUseFlatMonthProbeMode=false`.

## Test Setup

- Model: `4` real ticks
- Windows: 12 weak / flat / guard months
- Configs: 48
- Source: compact tester source
- Hidden MT5 run: yes
- Safety audit after run: `PASS`, `39 / 39`

## Summary

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmp_strict_low_risk` | `12 / 12` | `3` | `9` | `+453.17` | `0` | `6` | `30.9408` |
| `fmp_quality_ramp` | `12 / 12` | `3` | `9` | `+453.17` | `0` | `6` | `30.9408` |
| `fmp_tiny_discovery` | `12 / 12` | `2` | `10` | `+444.02` | `0` | `5` | `30.9408` |

## What Happened

The probe-mode variants did not create new profitable flat-month trades.

They mainly reduced the `2026_06` winner:

- Current: `2026_06` was `+64.05`
- Strict low-risk / quality-ramp: `2026_06` fell to `+9.15`
- Tiny discovery: `2026_06` was skipped entirely

## Interpretation

Flat-month probe-mode is not an opportunity engine by itself. In this sample it is mostly a risk reducer on trades that were already good.

That can be useful in a defensive profile, but it does not solve the user's goal of materially increasing profit while staying out of the red.

## Evidence Files

- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_RESULTS.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_SUMMARY.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_RUN.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_MANIFEST.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_COMPACT_AUDIT.csv`

## Next Direction

Do not promote these probe-mode settings. Continue looking for a real entry improvement or a risk-adjusted exit/stop improvement.
