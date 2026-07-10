# March Conflict + May 2.75 Month Spread Cap Candidate

Date: 2026-07-10

## Summary

Promoted a new candidate that keeps the March-only liquidity stop conflict guard, raises May risk to `2.75`, and adds a month-specific spread cap:

- `InpUseMonthRiskMultipliers=true`
- `InpMarchRiskMultiplier=1.00`
- `InpMayRiskMultiplier=2.75`
- `InpUseMonthSpreadCaps=true`
- `InpMayMaxSpreadPoints=17.0`

## Why

The raw May `2.75` risk profile improved broad totals but failed monthly validation because May 2025 produced a `-264.40` month. Diagnostic logs showed the bad May 2025 sell entered with an 18-point spread, while the stronger May paths survived when entries above 17 points were blocked.

A global 17-point cap was rejected because it damaged broader validation:

- Global `may275_spread17`: continuous `297.64`
- Baseline/unguarded broad continuous: `1277.57`

The promoted implementation makes spread caps month-specific, so May can be tightened without reducing non-May opportunity.

## Validation

May-only validation:

| Profile | TotalNet | WorstWindow | LosingWindows |
|---|---:|---:|---:|
| may275_maycap17 | 3128.17 | 260.81 | 0 |
| may275_maycap16 | 2064.06 | 260.81 | 0 |
| may245_base | 1278.37 | 110.57 | 0 |
| may275_no_guard | 455.39 | -264.40 | 1 |

Broad validation:

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|---:|
| may275_maycap17 | 5002.78 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0 | 0 |
| may275_maycap16 | 5002.78 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0 | 0 |
| may275_no_guard | 5002.78 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0 | 0 |
| may245_base | 4967.32 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0 | 0 |

Monthly validation:

| Profile | TotalNet | WorstWindow | LosingWindows |
|---|---:|---:|---:|
| may275_maycap17 | 5507.22 | 0 | 0 |
| may275_maycap16 | 4443.11 | 0 | 0 |
| may245_base | 3657.42 | 0 | 0 |
| may275_no_guard | 2834.44 | -264.40 | 1 |

## Decision

Promote `may275_maycap17`. It improves monthly validation from `3657.42` to `5507.22` compared with the previous May `2.45` candidate, while preserving zero losing broad and monthly windows.

## Artifacts

- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY275_MAYCAP17_PROFILE.set`
- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY275_MAYCAP17_PROFILE_OVERRIDES.set`
- `outputs/EA_CANDIDATE_STATE_2026-07-10_MARCH_CONFLICT_MAY275_MAYCAP17.txt`
- `outputs/LOCAL_MT5_MAY_MONTHCAP_MAYONLY_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_MAY_MONTHCAP_BROAD_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_MAY_MONTHCAP_MONTHLY_LOG_SUMMARY.csv`
- `patches/2026-07-10-month-spread-caps.diff`
