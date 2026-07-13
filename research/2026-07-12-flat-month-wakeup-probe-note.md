# Flat-Month Wake-Up Probe

Date: 2026-07-12

## Decision

Rejected.

The wake-up, stale-entry, and elite-fallback controls compiled and tested correctly after being exposed as MT5 inputs, but the tested variants tied the current profile. They did not add trades, reduce zero-trade windows, or improve net profit.

Current stability-best remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

## Code Change

The dormant flat-month wake-up controls were changed from normal globals to `input` parameters so Strategy Tester `.set` profiles can actually enable and tune them.

Default behavior is unchanged because all feature toggles remain default-off.

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
| `fmw_wake_strict` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_wake_balanced` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_stale_elite` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |

## Interpretation

This confirms the inputs now work, but the tested wake-up logic did not find a missing opportunity pocket. It appears the other entry gates still block the flat months, or the required continuation lanes simply are not present.

## Evidence Files

- `outputs/FLAT_MONTH_WAKEUP_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_WAKEUP_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_WAKEUP_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_WAKEUP_PROBE_MANIFEST.csv`
- `outputs/FLAT_MONTH_WAKEUP_COMPACT_AUDIT.csv`

## Next Direction

Do not promote these wake-up settings. If revisited, it needs a different entry mechanism, not only lower confirmation / score requirements.
