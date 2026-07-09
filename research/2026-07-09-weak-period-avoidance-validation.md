# Weak-Period Avoidance Validation

Date: 2026-07-09

## Purpose

After M5 secondary lanes and flat-month impulse lanes failed to repair the weak 2026 months, test whether the recurring losses are better addressed by avoiding specific weak calendar/session conditions.

This is a risk-calendar experiment, not a final promotion. Calendar filters can overfit, so candidates must preserve broader windows and survive future out-of-sample testing.

## Setup

Base profile:

- `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

Windows:

- `2024_to_2026`
- `2026_ytd`
- `2025_full`
- `2024_full`
- weak months: `2026_03`, `2026_05`, `2026_06`

Additional stress windows:

- `2024_05`, `2024_06`
- `2025_05`, `2025_06`
- `2026_05`, `2026_06`

## Broad Avoidance Sweep

| Profile | Continuous | YTD | 2025 | 2024 | Weak Sum | Min Weak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `block_may_only` | 801.84 | 84.72 | 124.51 | 801.84 | -155.78 | -84.88 |
| `block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 |
| `block_june_only` | 801.84 | 84.72 | 124.51 | 801.84 | -184.43 | -99.55 |
| `block_mar_may_jun` | -14.19 | 84.72 | -332.42 | -14.19 | 0.00 | 0.00 |
| `ny_only` | 225.45 | -258.14 | 16.50 | 225.45 | -249.22 | -89.88 |
| `london_only` | -599.31 | 84.72 | 153.48 | -475.90 | -255.33 | -99.55 |

## May/June Stress Test

| Profile | Continuous | YTD | 2025 | 2024 | May/Jun 2024 | May/Jun 2025 | May/Jun 2026 | Min May/Jun |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | 801.84 | 84.72 | 124.51 | 801.84 | -139.57 | 120.66 | -170.45 | -99.55 |
| `block_may_only` | 801.84 | 84.72 | 124.51 | 801.84 | -96.52 | 95.36 | -70.90 | -96.52 |
| `block_june_only` | 801.84 | 84.72 | 124.51 | 801.84 | -43.05 | 25.30 | -99.55 | -99.55 |
| `block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | 0.00 | 0.00 | 0.00 | 0.00 |

## Decision

Create a candidate risk-calendar set, but do not mark the overall goal complete.

Candidate:

- `outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`

Rationale:

- Blocking May and June removes standalone May/June losses in 2024 and 2026.
- It does not reduce the broad continuous, yearly, or 2026 YTD windows in this validation run.
- It does sacrifice standalone May/June profit in 2025, so it should be treated as a risk-control candidate rather than proof of a universal seasonal edge.

Next validation should test additional unseen slices and/or a regime classifier that only disables May/June when the current structure resembles the losing months.

## Artifacts

- `work/build_weak_period_avoidance_package.ps1`
- `work/build_may_june_stress_package.ps1`
- `outputs/LOCAL_MT5_WEAK_PERIOD_AVOIDANCE_RANKED.csv`
- `outputs/LOCAL_MT5_WEAK_PERIOD_AVOIDANCE_SUMMARY.csv`
- `outputs/LOCAL_MT5_MAY_JUNE_STRESS_RANKED.csv`
- `outputs/LOCAL_MT5_MAY_JUNE_STRESS_SUMMARY.csv`
- `outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`
- `outputs/WEAK_PERIOD_FINAL_FULL_COMPILE.log`
