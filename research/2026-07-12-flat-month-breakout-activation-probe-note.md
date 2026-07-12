# Flat-Month Breakout Activation Probe

Date: 2026-07-12

## Decision

Rejected.

This probe tested whether much looser flat-month breakout discovery could create additional trades at very small risk without hurting guard windows.

## Result

Model4 sampled probe across the same 12 weak/flat/guard windows:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Window | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `0.00` | `30.9408` |
| `fmb_activation_tape` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `0.00` | `30.9408` |
| `fmb_activation_loose` | `12 / 12` | `5` | `7` | `+490.65` | `2` | `8` | `-9.18` | `30.9408` |

## Interpretation

The loose profile proved FMB can create extra trades, but those trades were not useful:

- Added one loser in `2024_10`: `-9.18`.
- Added one loser in `2025_04`: `-8.24`.
- Reduced total net from `+508.07` to `+490.65`.
- Increased losing windows from `0` to `2`.

The tape profile tied current and did not improve activity.

Do not promote. Wider breakout discovery is not the right flat-month fix unless paired with a materially better setup-quality filter.

## Evidence

- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_MANIFEST.csv`
