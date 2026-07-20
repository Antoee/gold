# Joint Strong-Signal Reversion Allocation Discovery Decision

**Decision: REJECTED IN DISCOVERY. Recent data, Model 4, promotion, forward substitution, and live approval remain closed.**

- Exact accepted reports: `21/21`; attempts: `23`; identity refusals retried without changing configs: `2`
- Source SHA-256: `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`
- EX5 SHA-256: `21DDE8A2C1E04CB1D26C76E791A1EA1F0F26167667F19479F29A98BAE1D905A4`
- Manifest SHA-256: `015DF848CD3882639DE65CE7AF4B117B718FF522EBAEB8013D8EB99AF38E3291`
- `$10,000`; MT5 Model 1; 2015-2020 sealed discovery; requested reversion risk `0.45%`; portfolio cap `0.75%`; real trading disabled

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control cap 0.15 / risk 0.45% | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 |
| Risk-only body 0.250 / risk 0.65% | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| Cap 0.15 / risk 0.60% | +$986.83 | +$354.69 | +$1,327.11 | 13.27% | 2.1%/yr | 1.83 | 265 | 1.06% | 11.2305 | 12.5189 |
| Cap 0.15 / risk 0.70% | +$986.83 | +$354.69 | +$1,327.11 | 13.27% | 2.1%/yr | 1.83 | 265 | 1.06% | 11.2305 | 12.5189 |
| **Cap 0.15 / risk 0.65% center** | +$986.83 | +$354.69 | +$1,327.11 | 13.27% | 2.1%/yr | 1.83 | 265 | 1.06% | 11.2305 | 12.5189 |
| Body 0.225 / cap 0.15 / risk 0.65% | +$1,029.61 | +$354.69 | +$1,369.84 | 13.7% | 2.16%/yr | 1.85 | 265 | 1.21% | 10.743 | 11.3223 |
| Body 0.275 / cap 0.15 / risk 0.65% | +$986.83 | +$330.02 | +$1,302.44 | 13.02% | 2.06%/yr | 1.82 | 265 | 1.06% | 11.0217 | 12.283 |

## Frozen Gate

- Every report profitable: `True`
- Center changed behavior and was no worse in both disjoint eras: `False`
- Center net at least 3% above control: `False` (`+$1,327.11` vs required `+$1,394.35`)
- Center CAGR at least 0.05 point above control: `False`
- Center PF/recovery/return-DD no worse than control: `False`
- Center drawdown and trade-count gates: `True`
- Center beat the risk-only reference in net and return/DD: `True`
- At least 3 of 4 orthogonal neighbors passed: `False` (`0/4`)

The center changed net profit by `-$26.63` versus the exact leader control in the sealed continuous window. It failed the preregistered disjoint-era, growth, CAGR, efficiency, and neighborhood gates, so no recent-data or Model 4 budget was spent.

The published strong-signal selective lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.
