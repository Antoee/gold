# Month-Specific Risk Validation

Date: 2026-07-10

## Summary

Added default-off month-specific risk multipliers to `CRiskManager::EffectiveRiskPercent()`.

The goal was to avoid blanket risk increases, which failed monthly real-tick validation, and instead test whether May could use higher risk while March stayed at the safer baseline.

## Promoted Candidate

Set file:

- `outputs/CANDIDATE_SEASONAL_MAR1_MAY25_PROFILE.set`

Key overrides:

- `InpUseMonthFilter=true`
- `InpTradeMarch=true`
- `InpTradeMay=true`
- `InpRiskPercent=1.00`
- `InpUseMonthRiskMultipliers=true`
- `InpMarchRiskMultiplier=1.00`
- `InpMayRiskMultiplier=2.50`

## Real-Tick Broad Validation

Source:

- `outputs/LOCAL_MT5_MONTH_SPECIFIC_RISK_REALTICK_LOG_SUMMARY.csv`

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WeakSum | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| mar1_may2p50 | 3490.97 | 1277.57 | 158.91 | 214.30 | 1277.57 | 562.62 | 0.00 | 0 |
| mar1_may1p00 | 3265.99 | 1277.57 | 158.91 | 214.30 | 1277.57 | 337.64 | 0.00 | 0 |

## Real-Tick Monthly Validation

Source:

- `outputs/LOCAL_MT5_MONTH_SPECIFIC_RISK_MONTHLY_REALTICK_PROFILE_STATS.csv`

| Profile | Months | Total | Green | Flat | Red | Worst | Best |
|---|---:|---:|---:|---:|---:|---:|---:|
| mar1_may2p50 | 30 | 2430.10 | 6 | 24 | 0 | 0.00 | 1277.57 |
| mar1_may1p25 | 30 | 2308.92 | 6 | 24 | 0 | 0.00 | 1277.57 |
| mar1_may1p00 | 30 | 2186.25 | 6 | 24 | 0 | 0.00 | 1277.57 |

Rejected:

- `mar1_may1p50`: one red month, `2024_05 = -52.51`
- `mar1_may2p00`: one red month, `2024_05 = -88.97`
- `mar1_may3p00`: two red months, worst `2025_05 = -290.84`

## Interpretation

Month-specific risk improved the seasonal candidate without adding red validation windows.

This remains a seasonal profile. It is safer than a blanket risk increase, but it still sits flat outside March and May and should be treated as a candidate for continued walk-forward validation, not a final live-trading system.
