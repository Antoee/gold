# Real-Tick Profile Showdown

Date: 2026-07-12

## Purpose

Retest older real-tick-strong profiles against the current EA source and current research-best profile.

This was needed because earlier `May235` and `conflict_march` profiles looked very clean under real ticks, while the current `Score7 Regime No-M1-Shock` profile had stronger fast and higher-fidelity model results but only a small real-tick probe.

## Test Setup

- Symbol: `XAUUSD`
- Timeframe: `M15`
- Deposit: `1000`
- Model: `4` real ticks
- Runner: hidden local MT5 validation wrapper
- Package: `outputs/realtick_profile_showdown_package`
- Manifest: `outputs/REALTICK_PROFILE_SHOWDOWN_MANIFEST.csv`
- Raw runner CSV: `outputs/REALTICK_PROFILE_SHOWDOWN_RUN.csv`
- Parsed results: `outputs/REALTICK_PROFILE_SHOWDOWN_LOG_RESULTS.csv`
- Decision summary: `outputs/REALTICK_PROFILE_SHOWDOWN_DECISION_SUMMARY.csv`
- Safety audit after run: `39 / 39` checks passed

MT5 did not export report files for these rows, but all `24 / 24` rows were parsed from the tester log.

## Profiles Compared

- `no_m1shock`
- `may235`
- `conflict_march`
- `stable_mar1_may225`

## Decision Summary

| Profile | Parsed | Total Net | Continuous | Full 2024 | Full 2025 | 2026 YTD | Q4 2024 | Q4 2025 | Worst | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `no_m1shock` | 6 | `4075.62` | `1288.93` | `1425.73` | `214.30` | `955.21` | `-4.55` | `196.00` | `-4.55` | 1 |
| `conflict_march` | 6 | `3663.13` | `1277.57` | `1277.57` | `214.30` | `893.69` | `0.00` | `0.00` | `0.00` | 0 |
| `may235` | 6 | `3663.13` | `1277.57` | `1277.57` | `214.30` | `893.69` | `0.00` | `0.00` | `0.00` | 0 |
| `stable_mar1_may225` | 6 | `2928.35` | `1277.57` | `1277.57` | `214.30` | `158.91` | `0.00` | `0.00` | `0.00` | 0 |

## Interpretation

The current `no_m1shock` profile remains the best research profile by total real-tick profit in this comparison.

It beats the older `may235` and `conflict_march` profiles on:

- continuous `2024.01.01` to `2026.07.12`
- full 2024
- 2026 YTD
- Q4 2025

The tradeoff is the small Q4 2024 loss of `-4.55`. The older profiles avoid that loss, but they give up more profit than they save.

## Decision

Do not replace the current research-best with `may235`, `conflict_march`, or `stable_mar1_may225`.

Keep `Score7 Regime No-M1-Shock` as current research-best, but make the next improvement target explicit:

- remove or neutralize the Q4 2024 `-4.55` real-tick loss
- preserve the Q4 2025 `196.00` gain
- preserve the current full 2024 and 2026 YTD improvements

This supports continuing with the current profile while searching for a targeted weak-window guard rather than reverting to the older real-tick-clean profiles.
