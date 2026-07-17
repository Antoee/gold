# Transferable Portfolio Model4 Cost Stress

Historical real-tick spread is already included. Each scenario adds adverse points on entry and exit plus round-trip commission.

- Ledger SHA-256: `2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B`
- Source SHA-256: `5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3`
- Trades: `362`
- Cost gate: positive net, PF >= 1.20, closed-trade DD <= 5%, and every broad era positive.

| Scenario | Extra cost | Net | Return | CAGR | PF | Closed DD | Red years | Broad eras | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| base_real_ticks | $0.00 | $1,615.36 | 16.154% | 1.306% | 1.584 | 2.505% | 2 | True | PASS |
| modest_extra_cost | $162.13 | $1,453.23 | 14.532% | 1.183% | 1.509 | 2.639% | 2 | True | PASS |
| moderate_extra_cost | $324.27 | $1,291.09 | 12.911% | 1.058% | 1.439 | 2.776% | 3 | True | PASS |
| severe_extra_cost | $600.50 | $1,014.86 | 10.149% | 0.841% | 1.327 | 3.069% | 4 | True | PASS |
| extreme_extra_cost | $888.74 | $726.62 | 7.266% | 0.610% | 1.222 | 3.671% | 4 | True | PASS |

Closed-trade drawdown excludes intratrade equity movement; the MT5 report's 2.83% equity drawdown remains the base authority.
