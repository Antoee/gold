# March Conflict Guard + May 2.35 Profile

Date: 2026-07-10

## Summary

The prior promoted profile used the March-only liquidity stop conflict guard with May risk multiplier 2.25. A May risk ladder was tested on top of that profile using real-tick MT5 validation.

Best current candidate:

- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY235_PROFILE.set`
- March risk multiplier: `1.00`
- May risk multiplier: `2.35`
- Liquidity stop conflict guard: enabled only in March

## Real-Tick Broad Validation

Source: `outputs/LOCAL_MT5_LIQUIDITY_STOP_CONFLICT_MAY_RISK_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| conflict_may2p75 | 7/7 | 5002.78 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0.00 | 0 |
| conflict_may2p65 | 7/7 | 4981.98 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0.00 | 0 |
| conflict_may2p50 | 7/7 | 4961.18 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0.00 | 0 |
| conflict_may2p35 | 7/7 | 4946.52 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0.00 | 0 |
| conflict_may2p25 | 7/7 | 4919.58 | 1277.57 | 887.18 | 214.30 | 1277.57 | 0.00 | 0 |

## Real-Tick Monthly Validation

Source: `outputs/LOCAL_MT5_LIQUIDITY_STOP_CONFLICT_MAY_RISK_MONTHLY_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|
| conflict_may2p35 | 26/26 | 3598.02 | 0.00 | 0 |
| conflict_may2p25 | 26/26 | 3479.95 | 0.00 | 0 |
| conflict_may2p65 | 26/26 | 3207.23 | 0.00 | 0 |
| conflict_may2p50 | 26/26 | 3172.04 | 0.00 | 0 |
| conflict_may2p75 | 26/26 | 2834.44 | -264.40 | 1 |

## Decision

Promote `conflict_may2p35` over `conflict_may2p25`.

Rationale:

- Improves monthly real-tick total from `3479.95` to `3598.02`.
- Keeps broad validation profitable with zero losing windows.
- Rejects `conflict_may2p75` despite the strongest broad total because it introduces a losing monthly window.

## Rejected Follow-Up

House-money expansion profiles were tested after the May 2.35 profile:

Source: `outputs/LOCAL_MT5_LIQUIDITY_CONFLICT_HOUSE_MONEY_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | YTD | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|
| may235_baseline | 7/7 | 4946.52 | 1277.57 | 887.18 | 0.00 | 0 |
| closed_profit_tp_soft | 7/7 | 3616.98 | 1277.57 | 222.41 | 0.00 | 0 |
| profit_only_closed_soft | 7/7 | 4281.29 | 607.72 | 261.84 | 0.00 | 0 |
| closed_profit_risk_soft | 7/7 | 2276.54 | 583.88 | 261.84 | 0.00 | 0 |

Decision: reject house-money expansion for now. It avoided red windows, but reduced total and continuous profit versus the baseline May 2.35 candidate.
