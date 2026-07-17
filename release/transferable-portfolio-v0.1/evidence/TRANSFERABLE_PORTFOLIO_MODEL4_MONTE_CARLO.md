# Transferable Portfolio Model4 Monte Carlo

Seeded trade-order stress with random execution degradation, spread shocks, and missed winners over the exact combined ledger.

- Ledger SHA-256: `2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B`
- Source SHA-256: `5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3`
- Each scenario uses 10,000 deterministic trials; percentages are measured against the $10,000 starting balance.

| Scenario | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Capital | Streak |
|---|---:|---:|---:|---:|---:|---:|---|---|
| standard | $896.54 | $1,110.95 | 1.378 | 4.366% | 14 | 0.000% | PASS | WARN |
| severe | $286.74 | $560.80 | 1.178 | 5.770% | 16 | 0.090% | PASS | WARN |

Both capital gates pass. The streak warning is retained because randomized order produced longer runs than the predeclared advisory limits.
The shuffled test does not reapply the EA's time-based four-loss momentum cooldown, so this is an operational warning rather than a modeled account-loss failure.
Monte Carlo cannot prove future profitability; it measures sensitivity to plausible sequencing and execution deterioration.
