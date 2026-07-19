# Three-Lane Adaptive Trend Stress Decision

**Status: PASS. This is historical trade-ledger stress, not real-money approval.**

- Source SHA-256: `51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB`
- Profile SHA-256: `48636124EE5E38D516A48D7551F401F4B179A34296B6373C317F843CD3DEF1B1`
- Report SHA-256: `D946E7E90AE4E17BEE43282E97EFFD9826B8C3EB489AC367B3A67AA67E361271`
- Portable binary SHA-256: `6229E0023D3F54CA9A3404EA0584E97010230FECF4B1C99F6E034880A97039FC`
- Ledger SHA-256: `6501CCE7AB74A74CE810D8303A8A5FFF629155FBA26198D8AB9A27F64A9AA496`
- Trades: `367`; base net: `+$1,994.62`

## Added Execution Cost

| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$1,994.62 | 1.818 | 1.103% | +$828.96 | +$592.93 | +$572.73 | True |
| light | 0.02R | $109.08 | +$1,885.54 | 1.756 | 1.156% | +$782.37 | +$556.01 | +$547.16 | True |
| moderate | 0.05R | $272.70 | +$1,721.92 | 1.667 | 1.238% | +$712.49 | +$500.63 | +$508.80 | True |
| severe | 0.10R | $545.41 | +$1,449.21 | 1.530 | 1.379% | +$596.01 | +$408.32 | +$444.88 | True |

## Order-Aware Monte Carlo

| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| moving_block_08 | standard | 10000 | +$726.79 | +$1,483.44 | 1.571 | 3.110% | 13 | 0.040% | True |
| moving_block_08 | severe | 10000 | +$197.56 | +$938.40 | 1.336 | 4.352% | 16 | 1.740% | True |
| moving_block_16 | standard | 10000 | +$741.42 | +$1,468.09 | 1.567 | 2.643% | 12 | 0.030% | True |
| moving_block_16 | severe | 10000 | +$219.98 | +$932.75 | 1.335 | 3.952% | 15 | 1.360% | True |
| moving_block_24 | standard | 10000 | +$749.50 | +$1,465.18 | 1.567 | 2.347% | 11 | 0.010% | True |
| moving_block_24 | severe | 10000 | +$238.58 | +$939.75 | 1.338 | 3.565% | 14 | 1.150% | True |
| calendar_year | standard | 10000 | +$917.41 | +$1,486.58 | 1.575 | 1.913% | 10 | 0.000% | True |
| calendar_year | severe | 10000 | +$392.22 | +$950.49 | 1.339 | 2.910% | 15 | 0.230% | True |

- Block and calendar-year resampling preserve local clustering better than independent trade shuffling.
- Standard and severe paths add random slippage, delay, spread shocks, and missed winners.
- Drawdown here is closed-trade path drawdown; MT5 reports remain authoritative for intratrade equity drawdown.
- Broker-specification variation and a valid untouched forward demo are still required.
