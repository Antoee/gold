# 2026-07-11 Exit-Shape Validation

Base candidate:

- `outputs\CANDIDATE_MARCH110_MAY340_MAYCAP17_LOT040_QTPMARCH_PROFILE.set`
- Broad validation windows: full 2024-01-01 to 2026-07-02, 2026 YTD, 2025 full, 2024 full, March 2026, May 2026, June 2026.
- Hidden MT5 run, compact source compile: `outputs\EXIT_SHAPE_COMPACT_COMPILE.log`
- Results: `outputs\EXIT_SHAPE_LOG_SUMMARY.csv`

Summary:

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| base_current | 7468.70 | 793.69 | 1560.04 | 219.66 | 793.69 | 0.00 | 0 | Keep baseline |
| elite_tp_soft | 7468.70 | 793.69 | 1560.04 | 219.66 | 793.69 | 0.00 | 0 | Reject: no effect |
| closed_profit_tp_soft | 7468.70 | 793.69 | 1560.04 | 219.66 | 793.69 | 0.00 | 0 | Reject: no effect |
| rpartial_post_runner | 5895.95 | 759.60 | 928.35 | 242.36 | 759.60 | 0.00 | 0 | Reject: lower broad profit |
| rpartial_soft | 5743.21 | 759.60 | 851.98 | 242.36 | 759.60 | 0.00 | 0 | Reject: lower broad profit |
| elite_tp_mfe_lock | 5194.36 | 793.69 | 422.87 | 219.66 | 793.69 | 0.00 | 0 | Reject: lower broad profit |
| mfe_lock_soft | 5194.36 | 793.69 | 422.87 | 219.66 | 793.69 | 0.00 | 0 | Reject: lower broad profit |

Conclusion:

The tested exit overlays do not improve the current best profile. Elite/closed-profit TP expansion appears inactive under current trade conditions, while MFE and partial-lock exits protect trades earlier but materially reduce total profit. No promotion.

Next research direction:

- Focus on entry selectivity and directional/month-specific opportunity expansion rather than generic exit locks.
- If testing exit modules again, first instrument trigger counts so inactive TP expansions are visible without needing full broad MT5 runs.
