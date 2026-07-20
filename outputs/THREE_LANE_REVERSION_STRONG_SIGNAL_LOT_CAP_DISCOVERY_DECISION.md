# Strong-Signal Selective Reversion Lot-Cap Discovery Decision

**Decision: DISCOVERY GATE PASSED. Only the exact frozen center may proceed to recent-data validation; Model 4 and promotion remain closed.**

- Reports: `15 / 15` exact source/binary/config/report identities
- Attempts: `17`; identity refusals: `2`
- Source SHA-256: `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`
- EX5 SHA-256: `A1640E4D0E6892F4E826CA8FC5524C7F3BDB9FABE2121F508F94FD2D7AB7BE7A`
- `$10,000`; 2015-2020; MT5 Model 1; requested reversion risk `0.45%`; real trading disabled

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control 0.10 | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| Unconditional 0.15 | +$1,075.75 | +$370.41 | +$1,419.25 | 14.19% | 2.24%/yr | 1.85 | 267 | 1.3% | 10.3136 | 10.9154 |
| Selective 0.12 | +$921.10 | +$343.82 | +$1,260.47 | 12.6% | 2%/yr | 1.81 | 265 | 1.02% | 11.1883 | 12.3529 |
| **Selective 0.15 center** | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 |
| Selective 0.18 | +$1,024.19 | +$388.14 | +$1,394.28 | 13.94% | 2.2%/yr | 1.87 | 265 | 1.18% | 11.2234 | 11.8136 |

## Frozen Gate

- Every report profitable: `True` (PASS)
- Unconditional reference active: `True` (PASS)
- Center changed behavior: `True` (PASS)
- Center no worse in both eras: `True` (PASS)
- Center growth/CAGR: `True / True` (PASS)
- Center PF/recovery/return-DD: `True` (PASS)
- Center drawdown: `True` (PASS)
- Center trade count: `True` (PASS)
- Retains 50% of unconditional increment: `True` (PASS)
- Improves efficiency versus unconditional: `True` (PASS)
- Selective 0.12 neighbor: `True` (PASS)
- Selective 0.18 neighbor: `True` (PASS)

## Boundary

The feature uses only the completed signal candle body ratio to select a lot ceiling. It never raises requested risk above 0.45%, and every size still passes broker-valued initial-stop sizing, account-wide exposure checks, and post-fill reconciliation.

The frozen center and both neighbors passed sealed discovery. Recent-data validation is required before Model 4; this is not yet a new best.

ATB150 and the registered forward candidate remain unchanged; real-account trading remains disabled.
