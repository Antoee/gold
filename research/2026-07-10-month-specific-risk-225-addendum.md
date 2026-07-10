# Month-Specific Risk 2.25 Addendum

Date: 2026-07-10

## Summary

After the May 2.50 candidate passed validation, a finer May-only multiplier sweep found May 2.25 to be the stronger candidate.

Promoted set:

- `outputs/CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set`

Compact override:

- `outputs/CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE_OVERRIDES.set`

Key risk settings:

- `InpRiskPercent=1.00`
- `InpUseMonthRiskMultipliers=true`
- `InpMarchRiskMultiplier=1.00`
- `InpMayRiskMultiplier=2.25`

## Monthly Real-Tick Fine Sweep

Source:

- `outputs/LOCAL_MT5_MONTH_SPECIFIC_RISK_FINE_MONTHLY_REALTICK_PROFILE_STATS.csv`

| Profile | Months | Total | Green | Flat | Red | Worst | Best |
|---|---:|---:|---:|---:|---:|---:|---:|
| mar1_may2p25 | 30 | 2739.91 | 6 | 24 | 0 | 0.00 | 1277.57 |
| mar1_may2p65 | 30 | 2464.34 | 6 | 24 | 0 | 0.00 | 1277.57 |
| mar1_may2p50 | 30 | 2430.10 | 6 | 24 | 0 | 0.00 | 1277.57 |
| mar1_may2p75 | 30 | 2090.60 | 5 | 24 | 1 | -264.40 | 1277.57 |
| mar1_may2p85 | 30 | 1683.44 | 4 | 24 | 2 | -277.62 | 1277.57 |

## Broad Real-Tick Check

Source:

- `outputs/LOCAL_MT5_MONTH_SPECIFIC_RISK_225_REALTICK_LOG_SUMMARY.csv`

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WeakSum | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| mar1_may2p25 | 3451.27 | 1277.57 | 158.91 | 214.30 | 1277.57 | 522.92 | 0.00 | 0 |
| mar1_may1p00 | 3265.99 | 1277.57 | 158.91 | 214.30 | 1277.57 | 337.64 | 0.00 | 0 |

## Decision

May 2.25 is preferred over May 2.50 because it has a much stronger monthly real-tick total while preserving zero red monthly windows. May 2.50 had slightly higher broad TotalNet, but the broad score double-counts overlapping windows and is less useful than the monthly safety matrix for this promotion decision.
