# Three-Lane Protected Runner Discovery Decision

**Decision: REJECTED IN MODEL 1 DISCOVERY. MODEL 4 WAS NOT OPENED. NO NEW BEST.**

This code experiment paired a wider fixed target with a second tightening-only stop milestone for the momentum and adaptive-trend lanes. The feature was disabled by default. It did not change entry signals, initial stops, requested risk, lot sizing, portfolio limits, or the real-account lock.

- Source SHA-256: `654EEA6299C1D2ABC1F9ACB09F66C41839ABD2EDD6BFD93607A51B043BF26035`
- Isolated compile EX5 SHA-256: `6078C87CDA9065BBA3E7F680B54296969CDDDDE6FF52DA145F5A1A24FAB06868`
- Exact portable EX5 SHA-256: `3E7D9D2822238A460A5954E5BC35D2578E27B45A85A2AAB220B49370AA749C24`
- Compile: `0 errors, 0 warnings`
- Static safety: default-off features, zero new buy/sell paths, unchanged initial stops, tightening-only runner locks, unchanged post-fill reconciliation and `0.75%` open-risk cap
- Valid controlled evidence: `33 / 33` reports, one worker, one portable compile, one reused binary, zero report errors
- Infrastructure note: an earlier 33-row attempt was refused before testing because a portable binary identity had not yet been prepared. Those rows contain no reports and are not strategy evidence.
- Gate: both disjoint eras profitable, CAGR at least `0.15` percentage points above control, PF at least `1.65`, drawdown at most `1.25%`, no loss of recovery or return/drawdown, and adjacent support

## Continuous Results

Model 1, XAUUSD, `$10,000`, 2015-2020:

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Control | +$1,191.69 | +11.92% | +1.89%/yr | 1.77 | 265 | 1.02% | 10.58 | 11.69 |
| Adaptive runner, lock 0.50R | +$1,223.78 | +12.24% | +1.94%/yr | 1.81 | 262 | 1.08% | 10.34 | 11.33 |
| Adaptive runner, lock 0.75R | +$1,231.63 | +12.32% | +1.96%/yr | 1.81 | 262 | 1.12% | 10.00 | 11.00 |
| Adaptive runner, lock 1.00R | +$1,245.49 | +12.45% | +1.98%/yr | 1.82 | 263 | 1.09% | 10.43 | 11.42 |
| Momentum runner, lock 0.50R | +$1,160.65 | +11.61% | +1.85%/yr | 1.78 | 259 | 1.29% | 8.63 | 9.00 |
| Momentum runner, lock 0.75R | +$1,198.35 | +11.98% | +1.90%/yr | 1.81 | 259 | 1.43% | 7.59 | 8.38 |
| Momentum runner, lock 1.00R | +$1,068.25 | +10.68% | +1.71%/yr | 1.72 | 260 | 1.40% | 7.29 | 7.63 |
| Momentum target 3R | +$1,105.06 | +11.05% | +1.76%/yr | 1.75 | 260 | 1.15% | 8.80 | 9.61 |
| Momentum trigger 1.25R | +$1,115.61 | +11.16% | +1.78%/yr | 1.75 | 260 | 1.25% | 8.61 | 8.93 |
| Momentum trigger 1.75R | +$1,188.28 | +11.88% | +1.89%/yr | 1.80 | 258 | 1.44% | 7.53 | 8.25 |
| Both center runners | +$1,217.52 | +12.18% | +1.93%/yr | 1.82 | 257 | 1.36% | 8.16 | 8.96 |

All profiles remained profitable in both disjoint eras. The strongest adaptive row improved CAGR by only `0.09` percentage points, below the frozen `0.15` requirement, while recovery fell from `10.58` to `10.43` and return/drawdown fell from `11.69` to `11.42`. Momentum runners materially weakened drawdown efficiency.

The runner mechanism is valid but not strong enough to justify recent-data or real-tick escalation. ATB150 and the frozen forward registration remain unchanged.
