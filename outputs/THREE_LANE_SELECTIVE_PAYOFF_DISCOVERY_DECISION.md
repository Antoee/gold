# Three-Lane Selective Payoff Discovery Decision

**Decision: REJECTED IN MODEL 1 DISCOVERY. MODEL 4 WAS NOT OPENED. NO NEW BEST.**

This code experiment widened only the adaptive-trend target when the completed H4 breakout bar met fixed ADX, body, close-location, and range/ATR thresholds. The feature was disabled by default and could not create an entry, increase size, widen an initial stop, inspect a future bar, or alter another lane.

- Source SHA-256: `56B674D2C85A879212350F944838FDCE7AF91E320D799FEA1EDAB5BF9A0D5C02`
- Exact portable EX5 SHA-256: `A62DAFD5360E50EAA2CE33E48DE6A1FB75998A4475B65601200FA37DA6D4C855`
- Compile: `0 errors, 0 warnings`
- Static safety: default-off feature, completed entry bar only, zero new buy/sell paths, unchanged initial risk and post-fill reconciliation
- Controlled evidence: `30 / 30` exact reports, one pinned binary, one worker, zero report errors
- Gate: both disjoint eras profitable, at least three qualified entries, CAGR at least `0.20` percentage points above control, PF at least `1.60`, drawdown at most `1.50%`, no loss of recovery or return/drawdown, and two supporting one-factor neighbors

## Continuous Results

Model 1, XAUUSD, `$10,000`, 2015-2020:

| Profile | Qualified entries | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control | 0 | +$1,191.69 | +11.92% | +1.89%/yr | 1.77 | 265 | 1.02% | 10.58 | 11.69 |
| Center | 23 | +$1,198.90 | +11.99% | +1.91%/yr | 1.78 | 264 | 1.07% | 10.24 | 11.21 |
| Target 2.5R | 23 | +$1,175.79 | +11.76% | +1.87%/yr | 1.77 | 264 | 1.07% | 10.04 | 10.99 |
| Target 4.0R | 23 | +$1,223.19 | +12.23% | +1.94%/yr | 1.80 | 264 | 1.08% | 10.33 | 11.32 |
| ADX 18 | 31 | +$1,209.87 | +12.10% | +1.92%/yr | 1.79 | 263 | 1.07% | 10.33 | 11.31 |
| ADX 26 | 19 | +$1,192.37 | +11.92% | +1.90%/yr | 1.78 | 264 | 1.07% | 10.19 | 11.14 |
| Body 45% | 24 | +$1,198.90 | +11.99% | +1.91%/yr | 1.78 | 264 | 1.07% | 10.24 | 11.21 |
| Body 65% | 19 | +$1,198.61 | +11.99% | +1.91%/yr | 1.78 | 265 | 1.07% | 10.24 | 11.21 |
| Range 0.50 ATR | 23 | +$1,198.90 | +11.99% | +1.91%/yr | 1.78 | 264 | 1.07% | 10.24 | 11.21 |
| Range 1.00 ATR | 20 | +$1,198.73 | +11.99% | +1.91%/yr | 1.78 | 265 | 1.07% | 10.24 | 11.21 |

All variants remained profitable in both disjoint eras, and the center produced 23 genuinely changed entries. The best profile improved CAGR by only `0.05` percentage points, one quarter of the frozen requirement. It also reduced recovery from `10.58` to `10.33` and return/drawdown from `11.69` to `11.32`.

The completed-bar confirmation was mechanically valid but economically too weak. It is rejected before recent data and real ticks. ATB150 and the frozen forward registration remain unchanged.
