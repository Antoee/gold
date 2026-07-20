# Four-Lane M15 Squeeze Partial-Runner Discovery Decision

**Decision: REJECTED IN DISCOVERY. No post-2020 run, Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**

- Exact accepted Model 1 reports: `27/27`; preserved identity refusals: `2`; successful exact recoveries: `2`
- Source SHA-256: `1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005`
- EX5 SHA-256: `405665BCE71400E067AD6DE80CFA4CAEE4C937C2F916F05A1545327DAAE2E4B1`
- Manifest SHA-256: `A6BA5855A67F090B20CC9E895EC81070402DE75F3E01D6011FE32663F6FD266E`
- Test contract: XAUUSD M15, `$10,000`, Model 1, frozen 2015-2020 discovery.

| Candidate | Close | Target | Lock | 2015-18 | 2019-20 | Continuous | CAGR | PF | PF/leader | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Leader control | 80% | 4R | 1.25R | +$1,036.19 | +$370.60 | +$1,379.93 | 2.18%/yr | 1.88 | 100% | 261 | 1.05% | 11.6775 | 13.1429 | LEADER_CONTROL |
| Active squeeze reference | 80% | 4R | 1.25R | +$1,141.49 | +$459.89 | +$1,575.70 | 2.47%/yr | 1.78 | 94.68% | 350 | 1.1% | 13.4434 | 14.3273 | ACTIVE_REFERENCE |
| **80% / 4R / +1.25R center** | 80% | 4R | 1.25R | +$1,212.22 | +$494.68 | +$1,695.16 | 2.64%/yr | 1.84 | 97.87% | 391 | 1.1% | 14.4626 | 15.4091 | False |
| sqpr_close70 | 70% | 4R | 1.25R | +$1,199.23 | +$488.83 | +$1,677.27 | 2.62%/yr | 1.83 | 97.34% | 391 | 1.1% | 14.31 | 15.2455 | False |
| sqpr_close90 | 90% | 4R | 1.25R | +$1,227.32 | +$494.22 | +$1,711.11 | 2.67%/yr | 1.85 | 98.4% | 391 | 1.1% | 14.5987 | 15.5545 | True |
| sqpr_target300 | 80% | 3R | 1.25R | +$1,230.55 | +$498.04 | +$1,716.77 | 2.68%/yr | 1.85 | 98.4% | 389 | 1.1% | 14.647 | 15.6091 | True |
| sqpr_target500 | 80% | 5R | 1.25R | +$1,214.60 | +$500.42 | +$1,703.28 | 2.66%/yr | 1.85 | 98.4% | 391 | 1.1% | 14.5319 | 15.4818 | True |
| sqpr_lock100 | 80% | 4R | 1R | +$1,213.51 | +$500.69 | +$1,702.02 | 2.65%/yr | 1.85 | 98.4% | 391 | 1.1% | 14.5211 | 15.4727 | True |
| sqpr_lock140 | 80% | 4R | 1.4R | +$1,221.27 | +$493.21 | +$1,703.00 | 2.66%/yr | 1.85 | 98.4% | 391 | 1.1% | 14.5295 | 15.4818 | True |

## Frozen Gate

- Leader control reproduced: `True`
- Active squeeze reference reproduced: `True`
- Every broad-window report profitable: `True`
- Center improved both disjoint eras: `True`
- Center profit/CAGR gate: `True`
- Center quality gate: `False`
- Passing neighbors: `5/6`; required: `3/6`

## Interpretation

The fixed center raised continuous pre-2021 net from `+$1,575.70` to `+$1,695.16` and CAGR from `2.47%` to `2.64%` while holding maximum drawdown at `1.1%`. Its PF improved from `1.78` to `1.84`, but retained only `97.87%` of the `1.88` leader PF, below the frozen `98%` floor. That single frozen quality miss rejects the center despite `5/6` supporting neighbors.

The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo contributes zero forward days and zero forward trades; the registered candidate is unchanged and real-account trading remains disabled.
