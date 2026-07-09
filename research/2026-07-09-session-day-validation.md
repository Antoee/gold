# Session and Day Risk Validation

Date: 2026-07-09

This continuation tested whether the current best branch could improve March/May/June 2026 by changing session exposure or day-of-week risk rather than blocking exact calendar dates.

Current best branch before this pass:

- `peak15_liquidity_stop_chop`
- Risk 1.00%
- Equity peak trail: enabled, 3% start, 15% giveback
- Liquidity-aware structure stop: enabled
- Diagnostic fallback entry: enabled, but now passes the guard stack
- Chop filter: enabled

Candidate set generated locally:

`outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

## Session validation

All results are net profit on a $1,000 test deposit.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 801.84 | 84.72 | 124.51 | 801.84 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| london_only | -599.31 | 84.72 | 153.48 | -475.90 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -599.31 |
| ny_only | 225.45 | -258.14 | 16.50 | 225.45 | -76.49 | -89.34 | -83.50 | -65.71 | -75.84 | -89.88 | -258.14 |
| custom_overlap | -313.91 | -270.86 | 157.96 | -377.87 | -76.49 | -72.05 | -40.58 | -53.24 | -75.84 | -89.88 | -377.87 |
| london_plus_overlap | 103.90 | 84.72 | 70.40 | 103.90 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |

Conclusion: session narrowing did not beat the base branch. London-only preserved 2026 YTD but wrecked full validation; New York/custom overlap were weak.

## Day-of-week hard filters

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 801.84 | 84.72 | 124.51 | 801.84 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| no_monday | 540.57 | 135.49 | -451.57 | 540.57 | 135.49 | -50.42 | 157.02 | 212.62 | -99.55 | -97.92 | -451.57 |
| no_friday | 578.44 | -235.07 | 124.51 | 578.44 | -97.80 | 78.78 | -84.88 | 192.20 | 257.06 | -70.90 | -235.07 |
| no_tuesday | 529.12 | 84.72 | 17.44 | 529.12 | 84.72 | 83.15 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| tue_thu_only | -628.08 | -272.99 | -411.19 | -333.97 | -54.15 | -50.42 | 102.74 | 129.27 | -42.98 | -97.92 | -628.08 |

Conclusion: weekday filters exposed clues, but did not validate. No-Monday improves March and YTD but destroys 2025. No-Friday improves May but breaks January and YTD.

## Partial day-risk scaling

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 801.84 | 84.72 | 124.51 | 801.84 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| mon50 | 650.88 | 143.40 | -63.37 | 650.88 | 143.40 | -44.67 | -42.44 | 213.23 | -99.55 | -51.27 | -99.55 |
| mon50_fri50 | 623.64 | 52.14 | -41.75 | 623.64 | 52.14 | -44.67 | -42.44 | 213.23 | -45.25 | -51.27 | -51.27 |
| fri25 | 650.50 | -47.28 | 124.51 | 650.50 | -47.28 | 78.78 | -84.88 | 192.20 | 88.94 | -70.90 | -84.88 |
| mon25 | 556.77 | 140.26 | -430.69 | 556.77 | 140.26 | -50.42 | 53.71 | 209.12 | -99.55 | -57.70 | -430.69 |

Conclusion: partial weekday scaling improved some weak months but failed broader validation. The base branch remains the strongest overall by total and continuous performance.

## Status

No session/day variant is promoted. Current best remains:

`outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

The 2-3% monthly goal is still not proven because March, May, and June 2026 remain negative in the best broad-validation branch.
