# Three-Lane Noncompounding Risk-Budget Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4 run, research promotion, forward change, or live approval is permitted.**

- Reports: `16 / 16` parsed and exact source/binary identity valid; identity retries: `1`
- Source SHA-256: `B72F61E0633F5A57C3BC4D5688C8F7F29155B772F7D2BDE3EDC72429A41E9EA8`
- EX5 SHA-256: `7D5F1FF625C50609019B8DEBB48026DEF58583613DE971ADA63D5B0AF0DCF03F`
- Feature behavior: sizing capital is `min(current equity, frozen initial capital)` when enabled
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Champion control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Budget only | +$815.51 | +$614.68 | +$599.00 | +$2,030.20 | 20.3% | 1.62%/yr | 1.87 | 402 | 1.06% | 15.9082 | 19.1509 |
| Strong risk only | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Strong risk + budget | +$815.51 | +$686.79 | +$679.61 | +$2,182.92 | 21.83% | 1.73%/yr | 1.93 | 402 | 1.05% | 17.1048 | 20.7905 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every profile/window profitable | `True` | PASS |
| Combined net no worse than control in every era | `False` | FAIL |
| Continuous net at least control +5% | +$2,182.92 vs required +$2,305.31 | FAIL |
| CAGR at least control +0.08 point | `1.73%` vs required `1.82%` | FAIL |
| PF no worse than control | `1.93` vs `1.83` | PASS |
| DD <=1.25% and <=control +0.05 point | `1.05%` vs `1.17%` | PASS |
| Recovery no worse than control | `17.1048` vs `15.8168` | PASS |
| Return/DD no worse than control | `20.7905` vs `18.7692` | PASS |
| At least 400 continuous trades | `402` | PASS |

## Interpretation

The budget mechanism improved stability as intended. Combined PF rose from `1.83` to `1.93`, drawdown fell from `1.17%` to `1.05%`, recovery rose from `15.8168` to `17.1048`, and return/drawdown rose from `18.7692` to `20.7905`.

It did not preserve growth. Combined net was `+$2,182.92`, below control at `+$2,195.53`; CAGR fell from `1.74%` to `1.73%`; the older and middle eras were also below control; and continuous trades fell from 415 to 402. The budget-only profile was weaker still. The fixed growth gates therefore fail and Model 4 remains closed.

This is a useful conservative risk-control result, but it is not a higher-APR candidate. ATB150 remains the historical champion, and the registered forward candidate, invalid-account boundary, and real-account lock remain unchanged.
