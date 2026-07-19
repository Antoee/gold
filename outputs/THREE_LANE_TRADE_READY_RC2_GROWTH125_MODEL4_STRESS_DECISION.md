# Three-Lane Trade-Ready RC2 Growth 1.25x Stress Decision

**Status: PASS. This is historical trade-ledger stress, not real-money approval.**

- Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Profile SHA-256: `8502A0D4FE736FFB5B219CCE20C2FD97AF4CB2EA4BFC2BA1FEC0788E18B4D32F`
- Report SHA-256: `6949A842D944465ECE24B8325557E207D4B52D1C51050B048B2DC5D0F8D98A37`
- Portable binary SHA-256: `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8`
- Ledger SHA-256: `75140BF59A50F1AE67640131A66455AF382E65D0FAAF3DA3A5FA07BC78431AC9`
- Trades: `383`; base net: `+$2,317.95`

## Added Execution Cost

| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$2,317.95 | 1.729 | 1.226% | +$873.89 | +$565.91 | +$878.15 | True |
| light | 0.02R | $142.89 | +$2,175.06 | 1.667 | 1.307% | +$813.48 | +$516.61 | +$844.96 | True |
| moderate | 0.05R | $357.24 | +$1,960.71 | 1.581 | 1.430% | +$722.87 | +$442.67 | +$795.18 | True |
| severe | 0.10R | $714.47 | +$1,603.48 | 1.448 | 1.806% | +$571.84 | +$319.43 | +$712.21 | True |

## Order-Aware Monte Carlo

| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| moving_block_08 | standard | 10000 | +$743.71 | +$1,650.07 | 1.488 | 4.009% | 13 | 0.120% | True |
| moving_block_08 | severe | 10000 | +$67.44 | +$974.00 | 1.267 | 5.872% | 16 | 4.120% | True |
| moving_block_16 | standard | 10000 | +$695.99 | +$1,637.53 | 1.484 | 3.652% | 12 | 0.120% | True |
| moving_block_16 | severe | 10000 | +$20.86 | +$949.08 | 1.262 | 5.698% | 15 | 4.530% | True |
| moving_block_24 | standard | 10000 | +$715.57 | +$1,621.99 | 1.479 | 3.106% | 11 | 0.030% | True |
| moving_block_24 | severe | 10000 | +$50.32 | +$946.98 | 1.261 | 5.046% | 15 | 3.850% | True |
| calendar_year | standard | 10000 | +$929.23 | +$1,666.32 | 1.488 | 2.815% | 10 | 0.000% | True |
| calendar_year | severe | 10000 | +$242.81 | +$972.67 | 1.265 | 4.497% | 15 | 1.360% | True |

- Block and calendar-year resampling preserve local clustering better than independent trade shuffling.
- Standard and severe paths add random slippage, delay, spread shocks, and missed winners.
- Drawdown here is closed-trade path drawdown; MT5 reports remain authoritative for intratrade equity drawdown.
- Broker-specification variation and a valid untouched forward demo are still required.
