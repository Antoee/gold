# Mar10/May10 Margin-Cap Probe

Date: 2026-07-11

## Context

The `dayrisk_110_110` edge-ladder profile showed strong standalone 2026 profit but failed the continuous 2024-2026 run. Tester logs showed repeated MT5 order rejections such as `not enough money`, meaning the profile was asking for oversized XAUUSD lots on a $1,000 account.

## Result

The current promoted `base_mar10_may10` profile remains the best continuous candidate.

| Profile | Continuous | YTD 2026 | Full 2025 | Full 2024 | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |
| d110_lot040 | 1452.75 | 1325.68 | 230.19 | 1452.75 | 0.00 | 0 |
| d110_lot035 | 1207.65 | 1175.63 | 230.19 | 1207.65 | 0.00 | 0 |
| d115_lot035 | 1219.55 | 837.24 | 246.13 | 1219.55 | 0.00 | 0 |
| d115_lot030 | 1070.45 | 867.94 | 246.13 | 1070.45 | 0.00 | 0 |
| d110_lot030 | 1064.50 | 1182.23 | 230.19 | 1064.50 | 0.00 | 0 |
| d110_lot025 | 894.50 | 1176.78 | 214.20 | 894.50 | 0.00 | 0 |
| d110_lot020 | 715.60 | 1207.48 | 180.10 | 715.60 | 0.00 | 0 |

## Decision

Reject the margin-cap variants. They reduce sizing failures and can lift some standalone windows, but none improve continuous 2024-2026 profit versus the promoted baseline.

## Follow-Up

Add a margin-aware lot cap to the EA risk manager before testing more high-risk day multipliers. The current `LotsForRisk()` calculation sizes from stop-risk only, then MT5 can reject trades for insufficient margin. A pre-order free-margin cap should prevent impossible order attempts and make optimization results less misleading.
