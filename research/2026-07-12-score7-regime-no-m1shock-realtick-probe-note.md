# Score7 Regime No-M1-Shock Real-Tick Probe

Date: 2026-07-12

## Purpose

Run a small higher-fidelity `Model=4` real-tick probe after promoting the no-M1-shock Regime profile.

The goal was to check whether the no-M1-shock profile shows damage or continued edge when moving beyond faster tester models.

## Test

File: `outputs/MODEL4_SCORE7_VS_NO_M1SHOCK_PROBE_LOG_RESULTS.csv`

Windows:

- Full 2024
- Full 2025
- 2026 YTD through `2026.07.12`

Profiles:

- `score7`
- `no_m1shock`

## Results

| Window | Score7 | No-M1-Shock | Delta |
| --- | ---: | ---: | ---: |
| Full 2024 | `1425.73` | `1425.73` | `0.00` |
| Full 2025 | `214.30` | `214.30` | `0.00` |
| 2026 YTD | `955.21` | `955.21` | `0.00` |

Summary:

- Score7 parsed: `3 / 3`
- No-M1-Shock parsed: `3 / 3`
- Score7 total: `2595.24`
- No-M1-Shock total: `2595.24`
- Worst window: `214.30`
- Losing windows: `0`

## Interpretation

This real-tick probe is neutral. It does not confirm the larger Model=1/Model=2 edge from the spread-regime profile, but it also does not show damage versus Score7 on the sampled windows.

The current profile remains a research-best candidate because it improves Model=1 and Model=2 without hurting this initial real-tick probe. It should not be treated as production-proven or risk-scaled until broader real-tick and walk-forward checks confirm the edge.
