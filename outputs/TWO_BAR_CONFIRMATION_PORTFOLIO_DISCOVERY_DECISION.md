# Two-Bar Confirmation Portfolio Discovery Decision

**Decision: rejected in pre-2021 discovery; holdout, Model 4, and promotion remain closed.**

Released risk, stops, targets, and position management were retained. Reversion entries could require extension then reclaim; momentum entries could require a breakout then a second close that held beyond the same channel.

- Source SHA-256: `A5462DA021E57A8FB42BA6344D89BE366204130DE1A47957F5EF988861DAD133`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `24 / 24`
- Fixed-risk control efficiency: `2.5054` return/DD
- Eligible two-bar confirmation profiles: `0 / 7`

| Candidate | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Return/DD | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| `tbc_fixed_control` | +$814.70 | -$105.45 | +$694.13 | 6.94% | 1.13% | 1.42 | 225 | 2.77% | 2.5054 | False | False | CONTROL_ONLY |
| `tbc_rv_wick` | +$699.81 | -$62.43 | +$625.51 | 6.26% | 1.02% | 1.39 | 223 | 2.4% | 2.6083 | False | False | REJECT_BEFORE_HOLDOUT |
| `tbc_rv_close` | +$601.11 | -$26.26 | +$569.14 | 5.69% | 0.93% | 1.39 | 214 | 2.03% | 2.803 | True | False | REJECT_BEFORE_HOLDOUT |
| `tbc_mo_hold` | +$674.99 | -$161.19 | +$542.94 | 5.43% | 0.89% | 1.4 | 185 | 2.77% | 1.9603 | False | False | REJECT_BEFORE_HOLDOUT |
| `tbc_both_wick_hold` | +$574.99 | -$118.17 | +$485.96 | 4.86% | 0.79% | 1.36 | 183 | 2.4% | 2.025 | False | False | REJECT_BEFORE_HOLDOUT |
| `tbc_both_close_hold` | +$500.23 | -$75.57 | +$453.80 | 4.54% | 0.74% | 1.38 | 174 | 2.01% | 2.2587 | False | False | REJECT_BEFORE_HOLDOUT |
| `tbc_mo_progress` | +$439.30 | -$220.68 | +$177.77 | 1.78% | 0.29% | 1.18 | 101 | 3.28% | 0.5427 | False | False | REJECT_BEFORE_HOLDOUT |
| `tbc_both_wick_progress` | +$338.90 | -$177.66 | +$120.39 | 1.2% | 0.2% | 1.13 | 99 | 3.02% | 0.3974 | False | False | REJECT_BEFORE_HOLDOUT |
