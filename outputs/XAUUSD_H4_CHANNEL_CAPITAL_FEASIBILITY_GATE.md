# XAUUSD Capital-Feasibility Gate

**Verdict: `FAIL`. This is a sizing/activity gate, not a strategy-profit test.**

A candidate passes only when at least `30` eligible signals exist from 2021 onward, broker-native `OrderCalcProfit` has zero failures, and at least `80%` of those signals can trade the broker minimum volume without exceeding the declared equity/risk budget.

| Probe | Lookback | Equity | Risk | Min lot | All signals | All feasible | Recent signals | Recent feasible | Latest signal year | Latest required equity min / median / p95 | Gate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `h4ct_capital_l40` | 40 | `$10,000.00` | `0.10%` | `0.01` | 970 | `19.69%` | 477 | `0.42%` | 2026 | `$64,280.00 / $87,310.00 / $137,848.00` | `FAIL_MINIMUM_LOT_FEASIBILITY` |
| `h4ct_capital_l55` | 55 | `$10,000.00` | `0.10%` | `0.01` | 815 | `19.63%` | 394 | `0.76%` | 2025 | `$19,770.00 / $39,630.00 / $73,921.50` | `FAIL_MINIMUM_LOT_FEASIBILITY` |
| `h4ct_capital_l80` | 80 | `$10,000.00` | `0.10%` | `0.01` | 687 | `18.49%` | 348 | `0.86%` | 2026 | `$64,280.00 / $87,310.00 / $123,672.00` | `FAIL_MINIMUM_LOT_FEASIBILITY` |

A failed candidate must change its strategy economics before performance testing: use a tighter evidence-based stop, a broker/symbol with a smaller minimum risk quantum, or a declared larger account. Forcing the minimum lot or silently raising risk is prohibited.

Diagnostic source and settings are immutable evidence for this gate. Changing them requires a new diagnostic identity.
