# Full Model4 Momentum Market-Phase Screen

**Status: EXPLORATORY NOMINATION ONLY. NO HISTORICAL LEADER OR FORWARD CANDIDATE CHANGED.**

- Exact ledger SHA-256: `6B9A70B11E2C90C4B8247234DF28F7E38A31847B88F1B696B436D42F45BAAD8F`
- Momentum control: 310 trades, +$593.04, PF `1.299`
- Broad-era control nets: era_2015_2018 +$479.28, era_2019_2020 +$117.47, era_2021_2023 -$156.00, era_2024_2026 +$152.29
- Single-feature thresholds screened: `159`
- Rules eligible for a fresh code test: `3`
- Previously rejected channel-width and breakout-fraction families are not retested here.
- Offline trade removal is not executable evidence: a removed trade can expose later signals that this ledger never observed.

## Highest-Ranked Screens

| Feature | Rule | Keep | Improvement | PF | Era nets (15-18 / 19-20 / 21-23 / 24-26) | Worst impact | Neighbors | Code test |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `D1EmaSlopeATR` | `<= 1` | 173 (55.81%) | +$149.49 | 1.761 | +$403.26 / +$156.49 / +$81.20 / +$101.58 | -$76.02 | 2 | True |
| `D1EmaSlopeATR` | `<= 0.75` | 155 (50.00%) | +$73.31 | 1.766 | +$333.61 / +$135.41 / +$114.54 / +$82.79 | -$145.67 | 1 | True |
| `D1EmaSlopeATR` | `<= 1.25` | 195 (62.90%) | +$28.90 | 1.543 | +$359.59 / +$147.51 / +$24.94 / +$89.90 | -$119.69 | 1 | True |
| `H1Efficiency20` | `>= 0.3` | 183 (59.03%) | +$39.35 | 1.588 | +$312.87 / +$159.43 / +$71.82 / +$88.27 | -$166.41 | 0 | False |
| `MarketH1ADX` | `>= 35` | 120 (38.71%) | -$32.35 | 1.891 | +$229.50 / +$181.97 / +$92.64 / +$56.58 | -$249.78 | 0 | False |
| `H1Efficiency20` | `>= 0.35` | 149 (48.06%) | -$39.16 | 1.694 | +$253.00 / +$115.98 / +$82.27 / +$102.63 | -$226.28 | 1 | False |
| `D1EmaSlopeATR` | `<= 0.5` | 138 (44.52%) | -$71.56 | 1.681 | +$304.06 / +$62.46 / +$82.11 / +$72.85 | -$175.22 | 1 | False |
| `H4Efficiency20` | `>= 0.4` | 74 (23.87%) | -$75.43 | 2.533 | +$173.81 / +$155.62 / +$85.89 / +$102.29 | -$305.47 | 0 | False |
| `MarketH1ADX` | `>= 30` | 171 (55.16%) | -$100.28 | 1.467 | +$295.72 / +$140.40 / +$7.57 / +$49.07 | -$183.56 | 0 | False |
| `H4Efficiency20` | `>= 0.2` | 155 (50.00%) | -$121.63 | 1.519 | +$230.88 / +$88.50 / +$33.97 / +$118.06 | -$248.40 | 0 | False |
| `MarketH1ADX` | `>= 40` | 77 (24.84%) | -$166.24 | 2.151 | +$143.88 / +$222.87 / +$56.69 / +$3.36 | -$335.40 | 0 | False |
| `H4Efficiency20` | `>= 0.3` | 112 (36.13%) | -$181.90 | 1.639 | +$202.56 / +$101.74 / +$31.69 / +$75.15 | -$276.72 | 0 | False |
| `H1Efficiency20` | `>= 0.45` | 88 (28.39%) | -$216.81 | 1.781 | +$14.91 / +$187.21 / +$84.79 / +$89.32 | -$464.37 | 0 | False |
| `H1Efficiency20` | `>= 0.4` | 119 (38.39%) | -$240.80 | 1.514 | +$108.96 / +$124.46 / +$51.75 / +$67.07 | -$370.32 | 0 | False |
| `H4Efficiency20` | `>= 0.5` | 40 (12.90%) | -$283.32 | 2.772 | +$133.94 / +$88.14 / +$4.95 / +$82.69 | -$345.34 | 0 | False |

## Decision

The first preregistered implementation candidate is `D1EmaSlopeATR <= 1`. It may enter fresh broad Model 1 testing only; recent and Model 4 confirmation remain sealed until that gate passes.

The registered demo identity remains invalid under the frozen $10,000 account contract. Real-account trading remains locked.
