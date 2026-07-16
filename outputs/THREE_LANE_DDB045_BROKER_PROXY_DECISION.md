# Three-Lane DDB 0.45 Broker-Proxy Decision

Date: 2026-07-16

Verdict: **PASS AS SAME-BROKER EXECUTION-SENSITIVITY EVIDENCE. SECOND-BROKER GATE REMAINS PENDING.**

- Source SHA-256: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- Base profile SHA-256: `2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312`
- Window: 2019-01-01 through 2026-07-12
- MT5 model: Model 4, 99% real ticks on MetaQuotes-Demo Build 5989
- Starting balance: `$10,000`
- Returned reports: `5 / 5`

| Proxy | Net | Annualized | PF | Trades | Max DD | Recovery | Net vs base |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Base reproduction | `+$380.23` | `+0.51%/yr` | `2.80` | `46` | `0.78%` | `4.73` | `0.00%` |
| Wide/less-stable spread acceptance | `+$342.84` | `+0.46%/yr` | `2.60` | `42` | `0.88%` | `3.87` | `-9.83%` |
| High commission guard | `+$326.98` | `+0.43%/yr` | `2.54` | `39` | `0.83%` | `3.88` | `-14.01%` |
| Tight slippage tolerance | `+$342.84` | `+0.46%/yr` | `2.60` | `42` | `0.88%` | `3.87` | `-9.83%` |
| Margin-pressure guard | `+$381.64` | `+0.51%/yr` | `2.82` | `46` | `0.78%` | `4.75` | `+0.37%` |

Every proxy remained profitable, PF stayed above `2.50`, and drawdown stayed below `0.90%`. This passes the local sensitivity gate.

The proxy profiles tighten EA inputs while reusing the same MetaQuotes-Demo XAUUSD history and contract specification. They do not simulate a different broker's tick stream, contract size, stop level, swap, session clock, or execution engine. An actual second-broker report remains mandatory before live review.

Exact results: `outputs/THREE_LANE_DDB045_BROKER_PROXY_MODEL4_RESULTS.csv`.
