# Profit Escalation Validation

Date: 2026-07-09

## Purpose

Test whether the current best candidate can produce much larger profit by increasing risk and changing exit management, while still avoiding broad-window losses.

This was a deliberate stress test. The user wants materially higher returns, but the validation rule remains: higher profit is not acceptable if it comes from unstable risk scaling or repeated red windows.

## Setup

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

The first run hit MT5's input limit. The package was then trimmed to non-default inputs, a compact tester source was compiled, and results were recovered from tester-log final balances because the hidden compact run did not export HTML reports.

## Results

| Profile | Parsed | Continuous | YTD | 2025 | 2024 | Weak Sum | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `block_may_jun_r1` | 7/7 | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | 1 |
| `base_r1` | 7/7 | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | 3 |
| `block_may_jun_r2` | 7/7 | 378.52 | -290.08 | -554.83 | 378.52 | -190.98 | -554.83 | 3 |
| `base_r2` | 7/7 | 378.52 | -343.93 | -593.72 | 378.52 | -491.55 | -593.72 | 5 |
| `block_may_jun_r3_structure_trail` | 7/7 | 304.70 | -175.04 | 190.06 | -302.11 | -239.12 | -302.11 | 3 |
| `block_may_jun_r3` | 7/7 | -791.25 | -358.22 | 103.11 | -627.34 | -297.08 | -791.25 | 4 |
| `base_r3` | 7/7 | -791.51 | -387.48 | 103.11 | -456.36 | -836.84 | -791.51 | 6 |
| `block_may_jun_r5` | 7/7 | -804.13 | -413.11 | -737.33 | -569.67 | -473.11 | -804.13 | 5 |
| `block_may_jun_r3_tp45` | 7/7 | -817.36 | 209.76 | -616.08 | -647.01 | -297.08 | -817.36 | 4 |
| `block_may_jun_r3_sl16_tp38` | 7/7 | -833.64 | -239.52 | -406.22 | -678.31 | -290.92 | -833.64 | 5 |

## Decision

Reject raw risk escalation.

Rationale:

- Moving from 1% to 2% or 3% risk did not simply multiply returns. It changed the path enough that full-window and yearly results degraded sharply.
- The 5% risk version failed badly.
- Exit-management variants did not repair the higher-risk instability.
- The best tested profile remains `block_may_jun_r1`, but that is a risk-calendar candidate, not a high-growth solution.

## Next Direction

Do not keep pushing risk percent as the main profit lever. The next improvement needs a new source of edge:

- a separate high-quality secondary entry lane with its own stops,
- better flat-month opportunity capture,
- or a regime classifier that permits higher risk only in proven favorable conditions.

## Artifacts

- `work/build_profit_escalation_package.ps1`
- `work/collect_local_mt5_log_results.ps1`
- `outputs/PROFIT_ESCALATION_MANIFEST.csv`
- `outputs/LOCAL_MT5_PROFIT_ESCALATION_RUN_COMPACT.csv`
- `outputs/LOCAL_MT5_PROFIT_ESCALATION_LOG_RESULTS.csv`
- `outputs/LOCAL_MT5_PROFIT_ESCALATION_LOG_SUMMARY.csv`
- `outputs/PROFIT_ESCALATION_COMPACT_COMPILE.log`
- `outputs/PROFIT_ESCALATION_FINAL_FULL_COMPILE.log`
