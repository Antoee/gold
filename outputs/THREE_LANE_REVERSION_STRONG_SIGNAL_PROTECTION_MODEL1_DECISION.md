# Three-Lane Reversion Strong-Signal Protection Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `20 / 20` parsed and exact source/binary identity valid
- Attempts: `22`; identity-only retries: `2`
- Exact source SHA-256: `9810F048C62E93C217FB955DA51A4364055BF7806EFC739B37621E3B251F9206`
- Exact EX5 SHA-256: `88FF0942B85D70C0530DDCC94ADCF5A64857605545C3B20AFCDD564390099EA5`
- Candidate profile SHA-256: `0A07BC3AAF29E25D3C0D12D1DC22045AE1BDEABF96F9D2424CDE15CCED49016D`
- Fixed allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Fixed strong-signal protection neighborhood: `1.00R / 0.05R`, `1.00R / 0.10R`, `1.25R / 0.10R`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Strong allocation without protection | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Lower lock 1.00R / 0.05R | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Center 1.00R / 0.10R | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Later trigger 1.25R / 0.10R | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center and both neighbors no worse in every era | `True` | PASS |
| Protection changes at least one frozen report | `False` | FAIL |
| Continuous net at least control +5% | `8.94%` | PASS |
| Continuous net retains at least 97% of strong-only | `100.00%` | PASS |
| CAGR >=control +0.10 point and >=strong-only -0.03 point | `1.88%` | PASS |
| PF no worse than strong-only | `1.89` vs `1.89` | PASS |
| DD <=1.25% and no worse than strong-only | `1.21%` vs `1.21%` | PASS |
| Recovery no worse than strong-only | `16.562` vs `16.562` | PASS |
| Return/DD no worse than strong-only | `19.7686` vs `19.7686` | PASS |
| At least 400 continuous trades | `415` | PASS |
| 1.00R / 0.05R neighbor independently passes | net `+$2,391.89`; CAGR `1.88%`; recovery `16.562` | PASS |
| 1.25R / 0.10R neighbor independently passes | net `+$2,391.89`; CAGR `1.88%`; recovery `16.562` | PASS |

## Interpretation

The branch keeps the completed-H1 body 0.25 / risk 0.70% allocation and adds one tightening-only stop path for those positions. All three protected profiles produced the same metrics and report-level outcomes as strong-only: `+$2,391.89`, `1.88%` CAGR, PF `1.89`, `1.21%` drawdown, recovery `16.562`, and `415` trades.

The protection feature had zero behavioral effect at the frozen completed-bar triggers, so it cannot be promoted merely because its metrics equal the strong-only baseline. No lower trigger is substituted after observation; Model 4 stays closed and ATB150 remains the historical champion. Center recovery difference versus strong-only: `0.0000`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
