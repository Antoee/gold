# LowATR Locked Fast-Screen Summary

Generated after hidden local MT5 Model1 first-pass screens on 2026-07-14. MT5 did not export full HTML reports for these runs, so the results were imported from tester logs. Log evidence is enough to reject or continue a fast screen, but exported full reports are still required before promotion.

## Decision

No new trade-ready best was promoted.

The raw locked LowATR profile produced the large headline result, `+$8,437.54` from 2024-01-01 to 2026-07-12 on a `$1,000` start, but drawdown was `25.94%`. That is research-useful and explains the "about 8k" number, but it is not stable enough for the current risk-first first-pass gate.

The safer LowATR variants reduced drawdown or improved return, but none cleared the full first-pass path:

| Candidate | Window | Net | Ann. Return % | CAGR % | PF | DD % | Trades | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `lowatr_locked_research` | continuous_2024_2026 | `8437.54` |  |  | `2.8893` | `25.9387` | `59` | Reject for trade-ready: drawdown too high |
| `lowatr_locked_risk20` | continuous_2024_2026 | `241.12` | `9.54` | `8.92` | `6.4039` | `3.6771` | `8` | Advanced, then failed yearly recovery |
| `lowatr_locked_risk23` | continuous_2024_2026 | `288.08` | `11.40` | `10.54` | `6.3398` | `4.25` | `8` | Partial screen only |
| `lowatr_locked_risk23pure` | continuous_2024_2026 | `495.44` | `19.61` | `17.26` | `6.2207` | `6.6692` | `7` | Reject: DD above `6%` |
| `lowatr_locked_risk20pure` | continuous_2024_2026 | `430.78` | `17.05` | `15.23` | `4.7662` | `8.01` | `8` | Reject: DD above `6%` |
| `lowatr_locked_risk18pure` | continuous_2024_2026 | `419.14` | `16.59` | `14.86` | `5.0524` | `7.3251` | `8` | Reject: DD above `6%` |
| `money_ready` | continuous_2024_2026 | `-17.00` | `-0.67` | `-0.68` | `0` | `1.7511` | `1` | Reject: red broad screen |
| `trade_ready_conservative` | continuous_2024_2026 | `0.00` | `0.00` | `0.00` | `0` | `0` | `0` | Reject: zero trades |

## Next

The next useful branch is not "raise risk." It is either:

1. Find a LowATR risk shape that preserves trade frequency without exceeding drawdown, then rerun the yearly fast screens.
2. Run a raw LowATR Model4 continuous reproduction as research-only evidence, clearly marked high drawdown until risk shaping improves.
3. Make a strategy-code change that reduces the specific 2025 recovery weakness without filtering the bot down to almost no trades.
