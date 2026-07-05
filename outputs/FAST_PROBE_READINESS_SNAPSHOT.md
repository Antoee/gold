# Fast Probe Readiness Snapshot

Offline snapshot only. No MT5 process was launched.

- Overall: **WAITING_FOR_FAST_REPORTS**

| Gate | Status | Rows | Decision Counts | Next Action |
|---|---|---:|---|---|
| STRESS_MICRO | WAITING_FOR_REPORTS | 0 | missing=outputs\MICRO_TEST_DECISION.csv | Run/import stress micro reports first. |
| RECENT_OOS | WAITING_FOR_REPORTS | 0 | missing=outputs\RECENT_OOS_DECISION.csv | Run/import recent-OOS reports after stress micro passes. |
| CONFIRMATION_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\CONFIRMATION_PROBE_DECISION.csv | Run/import confirmation probe reports. |
| BREAKEVEN_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\BREAKEVEN_PROBE_DECISION.csv | Run/import break-even probe reports. |
| ADX_FILTER_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\ADX_FILTER_PROBE_DECISION.csv | Run/import ADX filter probe reports. |
| SPREAD_GUARD_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\SPREAD_GUARD_PROBE_DECISION.csv | Run/import ATR spread guard probe reports. |
| TIME_EXIT_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\TIME_EXIT_PROBE_DECISION.csv | Run/import time-exit probe reports. |
| MTF_TREND_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\MTF_TREND_PROBE_DECISION.csv | Run/import MTF trend probe reports. |
| STRUCTURE_TRAIL_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\STRUCTURE_TRAILING_PROBE_DECISION.csv | Run/import structure trailing probe reports. |
| SESSION_PROBE | WAITING_FOR_REPORTS | 0 | missing=outputs\SESSION_VARIANT_DECISION.csv | Run/import session variant reports. |

## Bottom Line

Fast probes are still waiting for exported reports. Keep the current promoted profile unchanged.
