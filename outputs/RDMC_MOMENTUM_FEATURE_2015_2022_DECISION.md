# RDMC Momentum Feature Training Extension

**Status: NO_ROBUST_FILTER_REPLACE_MOMENTUM_ENGINE. No candidate, forward, or real-money change.**

- Older exact Model4 rows: `135`
- New 2019-2022 telemetry-to-Model4 matches: `111`
- Unmatched telemetry entries: `8`
- Single rules with 8/8 positive portfolio years and at least 60% activity: `0`
- Two-rule combinations with 8/8 positive portfolio years and at least 50% activity: `0`
- Feature selection stops at 2022; 2023-2026 remains outside this scan.

| Rule | Trades | Retained | Portfolio net | Worst year | Positive years |
| --- | ---: | ---: | ---: | ---: | ---: |
| `max_stop_atr_1.75` | 76 | 30.89% | $+844.44 | $-33.98 | 7/8 |
| `max_stop_atr_2` | 137 | 55.69% | $+879.82 | $-39.52 | 7/8 |
| `max_d1_momentum_pct_6` | 115 | 46.75% | $+926.48 | $-55.76 | 7/8 |
| `min_h1_efficiency_0.2` | 204 | 82.93% | $+1155.83 | $-62.70 | 7/8 |
| `min_breakout_atr_0.3` | 118 | 47.97% | $+1042.07 | $-64.91 | 7/8 |

This is a training scan, not an executable result. Any nominated rule requires a fresh source/profile identity, exact compilation, adjacent-threshold support, and staged MT5 validation.
