# Flat-Month Breakout Structural Probe

Date: 2026-07-12

## Decision

Rejected as a profit/stability improvement.

The flat-month breakout probe was made optimizer-visible and given an optional direct structural stop/target path. Defaults remain off.

## What Changed

- Converted `InpUseFlatMonthBreakoutProbe` and related FMB controls from globals to `input` parameters.
- Added structural stop controls:
  - `InpFlatMonthBreakoutProbeUseStructuralStop`
  - `InpFlatMonthBreakoutProbeStopLookbackBars`
  - `InpFlatMonthBreakoutProbeStopBufferATR`
  - `InpFlatMonthBreakoutProbeStopBufferPoints`
  - `InpFlatMonthBreakoutProbeMinStopATR`
  - `InpFlatMonthBreakoutProbeMaxStopATR`
  - `InpFlatMonthBreakoutProbeTakeProfitATR`
  - `InpFlatMonthBreakoutProbeMinRR`
- Added compact-source validation runner:
  - `work/build_flat_month_breakout_structural_probe_package.ps1`
  - `work/run_fmb_structural_probe_background.ps1`

## Result

Model4 sampled probe across 12 weak/flat/guard windows:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fmb_struct_conservative` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fmb_struct_balanced` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |

## Interpretation

The structural FMB variants did not add active windows, did not reduce zero-trade windows, and did not improve profit. This means the lane either did not activate or did not survive the full entry/risk filter stack.

Keep the code default-off as test infrastructure, but do not promote either profile.

## Evidence

- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_MANIFEST.csv`
