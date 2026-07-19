# RDMC Hard Lane Risk v4 Audit

**Status: PASS. Every reconstructed entry risk is inside its lane's static upper ceiling.**

| Window | Trades | Maximum initial risk | Violations |
|---|---:|---:|---:|
| 2019 | 25 | 0.1784% | 0 |
| 2022 | 27 | 0.3087% | 0 |

- Momentum ceiling: `0.10%` of reconstructed entry balance.
- Shared primary ceiling: `0.25%`; isolated reversion and D1 breakout absolute upper ceiling: `0.50%`.
- The ledgers contain no overlapping positions, so closed balance equals equity immediately before each entry.
- This safety pass does not override the strategy rejection: 2019 profit factor remains below the frozen `1.05` gate.
