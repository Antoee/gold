# RDMC Momentum Breakout Retest v5 Risk Audit

**Status: PASS. Every reconstructed entry risk is inside its lane's static upper ceiling.**

| Window | Trades | Maximum initial risk | Violations |
|---|---:|---:|---:|
| 2015_2018 | 46 | 0.3254% | 0 |

- Momentum ceiling: `0.10%` of reconstructed entry balance.
- Shared primary ceiling: `0.25%`; isolated reversion and D1 breakout absolute upper ceiling: `0.50%`.
- The ledgers contain no overlapping positions, so closed balance equals equity immediately before each entry.
- This safety pass does not override the strategy rejection: the older training window placed only 46 trades against the frozen 60-trade floor.
