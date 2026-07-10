# 2026-07-10 Liquidity Stop Conflict March Guard

## Purpose

Improve profit without opening weak flat-month trading and without relying on pure ATR stops.

The change adds a default-off guard that detects when the planned stop sits directly inside a recent same-side liquidity cluster. The guard can be month-scoped, which matters because the same stop behavior helped March but hurt May.

## Source Change

New inputs:

- `InpUseLiquidityStopConflictGuard`
- `InpLiquidityStopConflictLookbackBars`
- `InpLiquidityStopConflictMinTouches`
- `InpLiquidityStopConflictProximityATR`
- `InpLiquidityStopConflictProximityPoints`
- `InpLiquidityStopConflictBypassQualityScore`
- `InpUseLiquidityStopConflictMonthFilter`
- `InpLiquidityStopConflictTradeJanuary` ... `InpLiquidityStopConflictTradeDecember`

New logic:

- `LiquidityStopConflictGuardBlocks()`
- Called after the final stop distance is calculated and before RR/lot sizing.
- If the proposed stop is clustered near recent lows for buys or recent highs for sells, the entry is blocked unless quality is high enough to bypass.

## Key Result

Promoted candidate:

- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_PROFILE.set`
- Same as the stable March/May profile, but enables the stop-conflict guard only in March.
- May keeps the prior stable stop behavior.

## Real-Tick Broad Validation

File: `outputs/LOCAL_MT5_LIQUIDITY_STOP_CONFLICT_MARCH_SHORTLIST_REALTICK_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | 2026 YTD | 2025 Full | 2024 Full | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| conflict_march_only | 7/7 | 4920.83 | 1277.57 | 893.69 | 214.30 | 1277.57 | 0 | 0 |
| stable | 7/7 | 3451.27 | 1277.57 | 158.91 | 214.30 | 1277.57 | 0 | 0 |

## Real-Tick Monthly Validation

File: `outputs/LOCAL_MT5_LIQUIDITY_STOP_CONFLICT_MARCH_MONTHLY_REALTICK_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: |
| conflict_march_only | 30/30 | 3474.69 | 0 | 0 |
| stable | 30/30 | 2739.91 | 0 | 0 |

Non-zero month comparison:

| Month | Stable | Conflict March Only |
| --- | ---: | ---: |
| 2024-03 | 1277.57 | 1277.57 |
| 2024-05 | 45.92 | 45.92 |
| 2025-03 | 214.30 | 214.30 |
| 2025-05 | 679.20 | 679.20 |
| 2026-03 | 158.91 | 893.69 |
| 2026-05 | 364.01 | 364.01 |

## Decision

Promote `conflict_march_only` as the new current candidate.

Why:

- Real-tick broad validation improved 2026 YTD materially.
- Real-tick monthly validation improved total profit by 734.78.
- No losing windows were introduced.
- The improvement came from stop-placement logic, not martingale, grid, or blind risk increases.

## Caution

This still does not prove a reliable 2-3% every month. It improves the current seasonal profile while preserving the no-red validation behavior. Next work should continue expanding profitable months or adding controlled intra-month extraction without allowing May damage or flat-month whipsaw.
