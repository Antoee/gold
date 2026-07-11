# Margin-Aware Sizing and Protection Hybrid

Date: 2026-07-11

## Source Change

Added `InpUseMarginAwareLotCap` behind a default-off input. When enabled, the EA now caps the calculated lot size to the largest broker-valid volume that fits under `InpMaxTradeMarginFreePercent` of free margin before exposure, cost, and margin checks run.

This prevents future optimizations from chasing profiles that look profitable only because MT5 rejects oversized XAUUSD orders with `No money`.

Compile evidence:

- `outputs\MARGIN_AWARE_LOT_CAP_COMPILE.log`
- Result: `0 errors, 0 warnings`

## Margin-Aware Day-Risk Probe

| Profile | Continuous | YTD 2026 | Full 2025 | Full 2024 | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |
| d110_mcap35 | 756.93 | 1209.45 | 107.09 | 756.93 | 0.00 | 0 |
| d110_mcap20 | 386.08 | 367.96 | 23.60 | 386.08 | 0.00 | 0 |
| d115_mcap20 | 386.08 | 367.96 | 23.60 | 386.08 | 0.00 | 0 |

Decision: reject. The new cap removes the fake high-risk upside, but does not improve continuous profit.

## Protection Hybrid Retest

Retested the old `risk25_guarded` protection-sweep idea against the current source and current broad gate. The old headline was misleading because it had weak/negative out-of-sample windows.

| Profile | Continuous | YTD 2026 | Full 2025 | Full 2024 | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |
| protect_r25 | 1454.17 | 2070.16 | -48.62 | -3.77 | -111.60 | 3 |
| protect_r20_marginaware | 51.61 | 578.55 | 186.64 | 51.61 | -152.32 | 1 |
| protect_r25_marginaware | 51.61 | 518.64 | 186.64 | 51.61 | -152.32 | 1 |

Decision: reject. `protect_r25` lifts 2026 but introduces losing validation windows and trails the continuous baseline badly.

## Current Best

Keep `base_mar10_may10` / `outputs\CANDIDATE_MAR10_MAY10_CONTINUOUS_PROFILE.set` as the promoted research candidate.

Continuous 2024-2026 remains `+3746.45` on a $1,000 deposit, with no losing broad validation windows in the current gate.
