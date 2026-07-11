# 2026-07-11 Mar10/May10 Edge Ladder

Base candidate:

- `outputs\CANDIDATE_MAR10_MAY10_CONTINUOUS_PROFILE.set`
- Baseline broad result: Continuous `3746.45`, YTD `1107.93`, Full2025 `214.30`, Full2024 `1409.57`, WorstWindow `0`, LosingWindows `0`.

Test:

- Built `work\local_mt5_mar10_may10_edge_ladder_package`.
- Compile: `outputs\MAR10_MAY10_EDGE_LADDER_COMPILE.log`, `0 errors, 0 warnings`.
- Results: `outputs\MAR10_MAY10_EDGE_LADDER_LOG_SUMMARY.csv`.

Summary:

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| base_mar10_may10 | 7909.84 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 | Keep |
| dayrisk_125_lot045 | 5223.48 | 1637.70 | 692.69 | 262.02 | 1637.70 | 0.00 | 0 | Reject: lower continuous |
| dayrisk_150_110 | 2887.05 | 395.91 | 901.45 | -8.35 | 395.91 | -8.35 | 1 | Reject: losing OOS |
| tp380 | 1745.62 | 322.56 | 487.50 | 234.30 | 322.56 | -217.60 | 1 | Reject: losing window |
| sl170_tp380 | 1743.75 | 321.65 | 487.50 | 234.25 | 321.65 | -217.60 | 1 | Reject: losing window |
| tp400 | 1623.01 | 216.72 | 505.31 | 265.99 | 216.72 | -217.60 | 1 | Reject: losing window |
| dayrisk_125_110 | 2143.31 | 211.44 | 692.69 | 262.02 | -16.21 | -16.21 | 1 | Reject: losing train |
| dayrisk_110_110 | 6428.34 | -1.66 | 4825.71 | 230.19 | -1.66 | -1.66 | 2 | Reject: fragile/negative continuous |
| dayrisk_125_tp380 | 1544.88 | -4.25 | 752.96 | 286.82 | -4.25 | -239.36 | 3 | Reject: losing windows |
| dayrisk_125_125 | 2500.78 | -195.34 | 692.69 | 262.02 | -195.34 | -195.34 | 2 | Reject: losing windows |

Conclusion:

The promoted baseline remains the best broad candidate. Direct risk scaling and wider TP settings either reduce continuous profit or introduce losing windows. The `dayrisk_110_110` variant is interesting for raw 2026 YTD profit (`4825.71`) but fails robustness with negative continuous/full-2024 behavior, so it is not promotable.

Next direction:

- Treat `dayrisk_110_110` as a clue for a 2026-specific research lane only, not a default.
- Search for structural filters that keep the 2026 gain while removing the 2024 fragility.
