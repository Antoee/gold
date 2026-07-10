# Seasonal March/May Gate Validation - 2026-07-10

## Purpose

Test whether the EA can improve profit and reduce red periods by standing aside during historically weak months.

This is a seasonal gate, not a martingale/grid/recovery system. It uses existing EA inputs:

- `InpUseMonthFilter=true`
- trade only March and May
- weak-regime entry block enabled
- MFE giveback exit enabled
- month-start filter enabled

Candidate set:

- `outputs/CANDIDATE_SEASONAL_MARCH_MAY_PROFILE.set`

## Fast Broad Validation

Evidence:

- `outputs/LOCAL_MT5_SEASONAL_GATE_LOG_RESULTS.csv`
- `outputs/LOCAL_MT5_SEASONAL_GATE_LOG_SUMMARY.csv`

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WeakSum | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| primary_mar_may | 3236.03 | 1262.72 | 157.02 | 214.18 | 1262.72 | 339.39 | 0 | 0 |
| block_mar_may | 3236.03 | 1262.72 | 157.02 | 214.18 | 1262.72 | 339.39 | 0 | 0 |

## Real-Tick Broad Validation

Evidence:

- `outputs/LOCAL_MT5_SEASONAL_GATE_REALTICK_LOG_RESULTS.csv`
- `outputs/LOCAL_MT5_SEASONAL_GATE_REALTICK_LOG_SUMMARY.csv`

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WeakSum | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| primary_mar_may_realtick | 3265.99 | 1277.57 | 158.91 | 214.30 | 1277.57 | 337.64 | 0 | 0 |

## Real-Tick Monthly Validation

Evidence:

- `outputs/LOCAL_MT5_SEASONAL_GATE_MONTHLY_REALTICK_LOG_RESULTS.csv`
- `outputs/LOCAL_MT5_SEASONAL_GATE_MONTHLY_REALTICK_PROFILE_STATS.csv`

| Profile | Months | Total | Green | Flat | Red | Worst | Best |
|---|---:|---:|---:|---:|---:|---:|---:|
| primary_mar_may_monthly_realtick | 30 | 2186.25 | 6 | 24 | 0 | 0 | 1277.57 |

## Interpretation

This is the strongest candidate found so far. It improves the prior best continuous run from about `806.46` to `1277.57` on real ticks, while reducing validated red windows to zero.

The tradeoff is obvious: it trades only March and May, so it may sit flat most of the year. This is probably more robust than forcing trades in weak months, but it is still a seasonal pattern and must not be treated as guaranteed future profit.

## Decision

Promote `outputs/CANDIDATE_SEASONAL_MARCH_MAY_PROFILE.set` to current best candidate for further forward/walk-forward validation.
