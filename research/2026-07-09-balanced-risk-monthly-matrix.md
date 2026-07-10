# Balanced Risk and Monthly Matrix Research Note

Date: 2026-07-09

## What changed

- Added a default-off early-month adverse-rejection entry guard to `Professional_XAUUSD_EA.mq5`.
- Added `work/build_balanced_risk_package.ps1` to test month-start + weak-regime + MFE-giveback logic across the primary, May/June-block, and 1.15x profiles.
- Added `work/build_monthly_profile_matrix_package.ps1` to validate individual monthly results from 2024-01 through 2026-06.

## Early-month rejection and large-stop result

The early-month adverse-rejection guard did not materially change results in the focused broad-window validation. The early-month large-stop guard was also not promoted; after the package was rebuilt correctly, it worsened weak-window results slightly.

Key evidence:

- `outputs/LOCAL_MT5_EARLY_MONTH_ADVERSE_REJECTION_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_EARLY_MONTH_LARGE_STOP_LOG_SUMMARY.csv`

## Balanced risk result

The current highest broad-profit profile remains the 1.15x May/June-block profile:

- `block115_base`: Continuous `806.46`, YTD `98.84`, Full2025 `153.90`, Full2024 `806.46`, WeakSum `-106.10`.

The best balanced/stress profile is `block_bal`:

- Continuous `558.95`
- YTD `307.02`
- Full2025 `113.44`
- Full2024 `558.95`
- WeakSum `157.02`
- Losing weak windows: `0`

This is not higher total profit, but it is smoother in the specific weak-window stress set.

Key evidence:

- `outputs/LOCAL_MT5_BALANCED_RISK_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_MONTH_OPEN_GUARD_CURRENT_LOG_SUMMARY.csv`

## Monthly matrix result

A month-by-month reset test was run for 2024-01 through 2026-06 across:

- `block115_base`
- `block_base`
- `block_bal`
- `primary_bal`

None of the profiles came close to avoiding red months:

| Profile | Green Months | Red Months | Monthly Sum | Worst Month |
|---|---:|---:|---:|---:|
| block_base | 13 | 17 | 943.38 | -99.26 |
| block_bal | 12 | 18 | 630.09 | -98.64 |
| block115_base | 12 | 18 | -836.90 | -114.84 |
| primary_bal | 9 | 21 | 879.31 | -98.64 |

Important interpretation: the monthly matrix resets the account each month, so monthly sums do not equal continuous backtest profit. This test is for consistency and red-month frequency, not total equity-curve profit.

## Decision

- Do not promote the early-month adverse-rejection guard.
- Do not promote the early-month large-stop guard.
- Keep `block115_base` as the highest broad-profit candidate.
- Preserve `block_bal` as a smoother balanced/stress candidate, but do not treat it as final because it still has many red individual months.

## Next research direction

The current strategy family is still too dependent on a few profitable windows. Risk scaling and small entry guards are not enough to reach the desired goal of much larger profit with low red-month frequency.

Next work should focus on a fundamentally different entry edge:

- Separate trend-continuation and mean-reversion regimes instead of forcing one profile through all months.
- Build a monthly regime selector using prior-month volatility, trend slope, ADX, and realized drawdown.
- Test profile switching between `block115_base` and `block_bal` only using information available before the month starts.
- Continue using monthly matrix validation to detect overfitting.
