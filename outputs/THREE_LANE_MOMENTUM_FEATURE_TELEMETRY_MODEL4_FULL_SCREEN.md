# Full Model4 Momentum Feature Screen

**Status: EXPLORATORY NOMINATION ONLY. NO HISTORICAL LEADER OR FORWARD CANDIDATE CHANGED.**

- Exact ledger SHA-256: `A9BD88891D0225933B56EE84B2F96C5F503EDC0DDCBB529B9440336CAD524046`
- Momentum control: 310 trades, +$593.04, PF `1.299`
- Broad-era control nets: era_2015_2018 +$479.28, era_2019_2020 +$117.47, era_2021_2023 -$156.00, era_2024_2026 +$152.29
- Single-feature thresholds screened: `94`
- Rules eligible for a fresh code test: `0`
- Channel-width and breakout-fraction families are intentionally excluded because their earlier reserved validation failed.
- Offline trade removal is not executable evidence: a removed trade can expose later signals that this ledger never observed.

## Highest-Ranked Screens

| Feature | Rule | Keep | Improvement | PF | Era nets (15-18 / 19-20 / 21-23 / 24-26) | Worst impact | Neighbors | Code test |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `CloseLocation` | `<= 0.85` | 189 (60.97%) | -$222.74 | 1.310 | +$299.84 / +$17.30 / +$15.03 / +$38.13 | -$179.44 | 0 | False |
| `D1MomentumPercent` | `>= 8` | 128 (41.29%) | -$300.05 | 1.368 | +$98.89 / +$10.00 / +$9.91 / +$174.19 | -$380.39 | 0 | False |
| `StopATR` | `<= 2.25` | 252 (81.29%) | +$47.45 | 1.394 | +$494.54 / +$160.03 / -$176.52 / +$162.44 | -$20.52 | 0 | False |
| `StopATR` | `<= 2.4` | 289 (93.23%) | +$41.86 | 1.344 | +$466.58 / +$113.82 / -$97.79 / +$152.29 | -$12.70 | 0 | False |
| `BodyRatio` | `>= 0.3` | 297 (95.81%) | +$35.46 | 1.334 | +$482.43 / +$133.51 / -$157.57 / +$170.13 | -$1.57 | 0 | False |
| `CloseLocation` | `>= 0.65` | 251 (80.97%) | +$28.01 | 1.395 | +$469.90 / +$58.14 / -$85.14 / +$178.15 | -$59.33 | 0 | False |
| `StopATR` | `>= 1.5` | 272 (87.74%) | +$12.58 | 1.360 | +$546.45 / +$87.23 / -$126.23 / +$98.17 | -$54.12 | 0 | False |
| `CloseLocation` | `>= 0.55` | 279 (90.00%) | +$11.52 | 1.342 | +$455.16 / +$94.98 / -$127.46 / +$181.88 | -$24.12 | 0 | False |
| `CloseLocation` | `>= 0.6` | 272 (87.74%) | +$11.31 | 1.355 | +$491.58 / +$32.47 / -$101.58 / +$181.88 | -$85.00 | 0 | False |
| `D1MomentumPercent` | `<= 18` | 294 (94.84%) | +$11.04 | 1.324 | +$477.72 / +$151.50 / -$123.13 / +$97.99 | -$54.30 | 0 | False |
| `D1MomentumPercent` | `<= 16` | 281 (90.65%) | +$8.77 | 1.338 | +$477.98 / +$131.13 / -$123.13 / +$115.83 | -$36.46 | 0 | False |
| `ATRPercent` | `<= 0.35` | 306 (98.71%) | +$6.61 | 1.304 | +$487.57 / +$117.47 / -$157.68 / +$152.29 | -$1.68 | 0 | False |
| `StopATR` | `>= 1` | 307 (99.03%) | +$1.42 | 1.305 | +$463.18 / +$117.47 / -$138.48 / +$152.29 | -$16.10 | 0 | False |
| `BreakoutATR` | `>= 0.05` | 310 (100.00%) | +$0.00 | 1.299 | +$479.28 / +$117.47 / -$156.00 / +$152.29 | +$0.00 | 0 | False |
| `ATRPercent` | `>= 0.05` | 310 (100.00%) | +$0.00 | 1.299 | +$479.28 / +$117.47 / -$156.00 / +$152.29 | +$0.00 | 0 | False |

## Decision

No single causal entry feature passed the frozen broad-era, retention, improvement, yearly-loss, and neighborhood gates. Do not implement a feature filter from this scan.

The registered demo identity remains invalid under the frozen $10,000 account contract. Real-account trading remains locked.
