# Strong-Signal Selective Lot-Cap Model 4 Stress Decision

**Status: STRESS GATE PASSED. This is historical stress evidence, not real-money approval.**

- Exact trades: `404`; base net: `+$2,428.50`
- Hard-risk audit: `True`; selective reversion lot cap: `True`
- Maximum reversion volume: `0.15` lots; maximum conservative portfolio initial risk: `0.5892%`
- Cost gate: `True`; order-aware Monte Carlo gate: `True`
- Source: `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`; EX5: `A1640E4D0E6892F4E826CA8FC5524C7F3BDB9FABE2121F508F94FD2D7AB7BE7A`
- Report: `1B673CD08DC8E3C826AD21EFF895F70EA6A9EBB461158DBE698CBC170B88AAE6`; ledger: `F4ABA823765C05FC8B44CAC07AAC168A9D2ABA9F06E344C682D6DC8CBB50EBEA`

## Added Execution Cost

| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$2,428.50 | 1.894 | 1.001% | +$971.96 | +$795.81 | +$660.73 | True |
| light | 0.02R | $126.06 | +$2,302.44 | 1.827 | 1.051% | +$917.27 | +$753.45 | +$631.72 | True |
| moderate | 0.05R | $315.16 | +$2,113.34 | 1.733 | 1.129% | +$835.23 | +$689.91 | +$588.21 | True |
| severe | 0.10R | $630.31 | +$1,798.19 | 1.588 | 1.264% | +$698.50 | +$584.01 | +$515.68 | True |

## Order-Aware Monte Carlo

| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| moving_block_08 | standard | 10000 | +$988.19 | +$1,834.81 | 1.635 | 3.004% | 12 | 0.010% | True |
| moving_block_08 | severe | 10000 | +$379.29 | +$1,209.93 | 1.389 | 4.255% | 16 | 0.650% | True |
| moving_block_16 | standard | 10000 | +$999.76 | +$1,830.35 | 1.631 | 2.596% | 11 | 0.000% | True |
| moving_block_16 | severe | 10000 | +$403.50 | +$1,186.78 | 1.381 | 3.835% | 15 | 0.560% | True |
| moving_block_24 | standard | 10000 | +$1,002.61 | +$1,824.59 | 1.631 | 2.235% | 11 | 0.000% | True |
| moving_block_24 | severe | 10000 | +$418.90 | +$1,198.11 | 1.387 | 3.453% | 14 | 0.300% | True |
| calendar_year | standard | 10000 | +$1,169.04 | +$1,838.70 | 1.634 | 1.929% | 10 | 0.000% | True |
| calendar_year | severe | 10000 | +$576.30 | +$1,208.98 | 1.389 | 2.929% | 15 | 0.070% | True |

- Stress preserves local trade clustering and calendar-year regimes; severe paths include worse slippage, delay, spread shocks, and missed winners.
- MT5 equity drawdown remains authoritative; Monte Carlo drawdown is closed-trade path drawdown.
- A second broker/specification and a valid frozen-account forward demo remain unavailable, so historical promotion and live approval stay closed.
