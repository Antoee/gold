# Three-Lane Payoff Ladder Discovery Decision

**Decision: REJECTED IN MODEL 1 DISCOVERY. MODEL 4 WAS NOT OPENED. NO NEW BEST.**

This experiment changed only the fixed take-profit distance of the momentum and adaptive-trend lanes. Entries, initial stops, requested risk, break-even, channel and momentum-failure exits, loss limits, the `0.75%` portfolio open-risk cap, and the real-account lock remained unchanged.

- Exact source: released ATB150 source, SHA-256 `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Controlled evidence: `27 / 27` exact reports, one pinned binary, one worker, zero report errors
- Discovery windows: 2015-2018, 2019-2020, and continuous 2015-2020
- Gate: both disjoint eras profitable, CAGR at least `0.25` percentage points above control, PF at least `1.60`, drawdown at most `1.50%`, and no deterioration in recovery or return/drawdown

## Continuous Results

Model 1, XAUUSD, `$10,000`, 2015-2020:

| Profile | Momentum target | Adaptive target | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control | 2.0R | 2.0R | +$1,191.69 | +11.92% | +1.89%/yr | 1.77 | 265 | 1.02% | 10.58 | 11.69 |
| Momentum 2.5R | 2.5R | 2.0R | +$1,146.42 | +11.46% | +1.83%/yr | 1.76 | 261 | 1.15% | 9.56 | 9.97 |
| Momentum 3.0R | 3.0R | 2.0R | +$1,092.35 | +10.92% | +1.74%/yr | 1.74 | 260 | 1.38% | 7.61 | 7.91 |
| Momentum 4.0R | 4.0R | 2.0R | +$1,169.30 | +11.69% | +1.86%/yr | 1.79 | 258 | 1.38% | 8.14 | 8.47 |
| Adaptive 2.5R | 2.0R | 2.5R | +$1,177.70 | +11.78% | +1.87%/yr | 1.77 | 264 | 1.07% | 10.06 | 11.01 |
| Adaptive 3.0R | 2.0R | 3.0R | +$1,239.96 | +12.40% | +1.97%/yr | 1.81 | 263 | 1.08% | 10.47 | 11.48 |
| Adaptive 4.0R | 2.0R | 4.0R | +$1,215.97 | +12.16% | +1.93%/yr | 1.80 | 262 | 1.08% | 10.27 | 11.26 |
| Both 2.5R | 2.5R | 2.5R | +$1,130.64 | +11.31% | +1.80%/yr | 1.75 | 260 | 1.14% | 9.43 | 9.92 |
| Both 3.0R | 3.0R | 3.0R | +$1,127.79 | +11.28% | +1.80%/yr | 1.77 | 258 | 1.26% | 8.64 | 8.95 |

Every profile remained profitable in both disjoint eras, but none delivered the required growth improvement while preserving the control's risk efficiency. The best CAGR gain was only `0.08` percentage points, and its recovery and return/drawdown were both lower than control.

The target ladder is therefore closed before recent data and real ticks. ATB150 and the frozen forward registration remain unchanged.
