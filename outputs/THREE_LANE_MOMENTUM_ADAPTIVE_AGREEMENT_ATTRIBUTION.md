# Momentum / Adaptive Agreement Attribution

This is retrospective architecture-selection evidence, not a simulated portfolio and not out-of-sample proof.

- Exact leader source SHA-256: `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`
- Exact Model 4 ledger SHA-256: `F4ABA823765C05FC8B44CAC07AAC168A9D2ABA9F06E344C682D6DC8CBB50EBEA`
- Ledger: 404 exact leader trades, 2015-01-01 through 2026-07-18
- Rule inspected: a new momentum entry whose direction matched an adaptive-trend position already open before that entry
- The rule uses only position state available at entry; no future bar or trade outcome is used by the proposed EA code

| Group | Trades | Net | PF | Win rate | Avg R |
|---|---:|---:|---:|---:|---:|
| All same-direction cross-lane entries | 31 | +$210.31 | 2.7533 | 58.06% | 0.5285 |
| Adaptive after Momentum | 8 | +$9.37 | 1.1536 | 37.5% | 0.1938 |
| Momentum after Adaptive | 19 | +$179.27 | 5.123 | 63.16% | 0.6996 |
| Momentum after Momentum | 4 | +$21.67 | 2.4026 | 75.0% | 0.3856 |
| Selected: Momentum after Adaptive | 19 | +$179.27 | 5.123 | 63.16% | 0.6996 |
| Selected 2015-2018 | 11 | +$66.96 | 2.959 | 45.45% | 0.4941 |
| Selected 2019-2022 | 6 | +$78.78 | 9.471 | 83.33% | 0.9069 |
| Selected 2023-2026 | 2 | +$33.53 | INF | 100.0% | 1.2077 |

The selected subset contains `19` trades, `+$179.27` net, and PF `5.123`. It was positive in all three broad eras, but the architecture was chosen after inspecting all eras. Therefore 2021-2026 is architecture-seen and cannot be described as a pristine holdout.

The proposed code may only change requested momentum risk for an otherwise-valid momentum entry while a same-symbol, same-direction, exact-magic adaptive-trend position is already open. Entry eligibility, initial stop geometry, target, exits, loss limits, and the account-wide 0.75% open-risk cap remain unchanged.
