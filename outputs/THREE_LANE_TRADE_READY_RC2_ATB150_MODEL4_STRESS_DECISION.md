# Three-Lane Trade-Ready RC2 ATB 1.50x Stress Decision

**Status: PASS. This is historical trade-ledger stress, not real-money approval.**

- Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Profile SHA-256: `705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E`
- Report SHA-256: `31A383253B7BF7611D6209E296317105E4C5756A8A12D883C0872245866B1B4D`
- Portable binary SHA-256: `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8`
- Ledger SHA-256: `D784E3F4289E989DDA2E6C686C80A20086825A6586355AFA8556021486373E69`
- Trades: `404`; base net: `+$2,105.08`

## Added Execution Cost

| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$2,105.08 | 1.810 | 0.978% | +$840.67 | +$631.83 | +$632.58 | True |
| light | 0.02R | $119.71 | +$1,985.37 | 1.745 | 1.028% | +$787.94 | +$592.12 | +$605.31 | True |
| moderate | 0.05R | $299.27 | +$1,805.81 | 1.654 | 1.106% | +$708.85 | +$532.56 | +$564.40 | True |
| severe | 0.10R | $598.53 | +$1,506.55 | 1.515 | 1.240% | +$577.03 | +$433.30 | +$496.22 | True |

## Order-Aware Monte Carlo

| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| moving_block_08 | standard | 10000 | +$793.17 | +$1,550.91 | 1.561 | 2.950% | 12 | 0.010% | True |
| moving_block_08 | severe | 10000 | +$238.64 | +$966.30 | 1.324 | 4.225% | 16 | 1.350% | True |
| moving_block_16 | standard | 10000 | +$790.31 | +$1,542.57 | 1.558 | 2.585% | 11 | 0.010% | True |
| moving_block_16 | severe | 10000 | +$240.57 | +$942.38 | 1.316 | 3.848% | 15 | 1.250% | True |
| moving_block_24 | standard | 10000 | +$805.84 | +$1,538.32 | 1.555 | 2.216% | 11 | 0.000% | True |
| moving_block_24 | severe | 10000 | +$250.43 | +$953.89 | 1.320 | 3.487% | 14 | 0.860% | True |
| calendar_year | standard | 10000 | +$982.42 | +$1,559.12 | 1.558 | 1.853% | 10 | 0.000% | True |
| calendar_year | severe | 10000 | +$421.71 | +$971.05 | 1.325 | 2.886% | 15 | 0.120% | True |

- Block and calendar-year resampling preserve local clustering better than independent trade shuffling.
- Standard and severe paths add random slippage, delay, spread shocks, and missed winners.
- Drawdown here is closed-trade path drawdown; MT5 reports remain authoritative for intratrade equity drawdown.
- Broker-specification variation and a valid untouched forward demo are still required.
