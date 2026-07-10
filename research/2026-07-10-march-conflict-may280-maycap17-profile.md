# March Conflict + May 2.80 Month Spread Cap Candidate

Date: 2026-07-10

## Summary

Promoted a small risk-ladder upgrade over the May `2.75` month-cap candidate:

- `InpMayRiskMultiplier=2.80`
- `InpUseMonthSpreadCaps=true`
- `InpMayMaxSpreadPoints=17.0`
- March-only liquidity stop conflict guard retained

## Why

The May 17-point spread cap fixed the prior high-risk May failure. A ladder test showed `2.80` is the highest tested May risk that kept all three May years green. Nearby values became unstable quickly:

- `2.81`: losing May window `-126.17`
- `2.85`: losing May window `-152.98`
- `3.00`: losing May window `-162.38`

## Validation

May-only fine ladder:

| Profile | TotalNet | WorstWindow | LosingWindows |
|---|---:|---:|---:|
| maycap17_may2p80 | 3176.82 | 214.91 | 0 |
| maycap17_may2p75 | 3128.17 | 260.81 | 0 |
| maycap17_may2p85 | 2839.69 | -152.98 | 1 |

Broad validation:

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|---:|
| maycap17_may2p80 | 5029.72 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0 | 0 |
| maycap17_may2p75 | 5002.78 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0 | 0 |

Monthly validation:

| Profile | TotalNet | WorstWindow | LosingWindows |
|---|---:|---:|---:|
| maycap17_may2p80 | 5555.87 | 0 | 0 |
| maycap17_may2p75 | 5507.22 | 0 | 0 |

## Decision

Promote `maycap17_may2p80`. The improvement is modest, but it increases total profit without adding losing validation windows.

## Artifacts

- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY280_MAYCAP17_PROFILE.set`
- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY280_MAYCAP17_PROFILE_OVERRIDES.set`
- `outputs/EA_CANDIDATE_STATE_2026-07-10_MARCH_CONFLICT_MAY280_MAYCAP17.txt`
- `outputs/LOCAL_MT5_MAYCAP_RISK_LADDER_FINE_MAYONLY_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_MAYCAP_RISK_LADDER_ULTRAFINE_MAYONLY_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_MAYCAP_RISK_LADDER_280_BROAD_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_MAYCAP_RISK_LADDER_280_MONTHLY_LOG_SUMMARY.csv`
