# High-Reward Strong-Signal Reversion Lot-Cap Discovery Decision

**Decision: REJECTED IN DISCOVERY. Recent data, Model 4, promotion, forward substitution, and live approval remain closed.**

- Exact accepted reports: `21/21`; attempts: `22`; identity refusals retried without changing configs: `1`
- Source SHA-256: `3CB0574945CD4A7A486408EF5BCE58648392383C43BFEE6EB1F58B424698302F`
- EX5 SHA-256: `37CDEA025C4C66BD79022335B542E987775DC8CF1FCD7175D2C70C3E6558A8BD`
- Manifest SHA-256: `8CA894BA7C87358057D74B78693BCFA53F7B151B15B86241DB4C0DAD03D43BDC`
- `$10,000`; MT5 Model 1; 2015-2020 sealed discovery; requested reversion risk `0.45%`; portfolio cap `0.75%`; real trading disabled

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control strong cap 0.15 | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 |
| Broad strong cap 0.20 | +$1,024.13 | +$388.14 | +$1,403.09 | 14.03% | 2.21%/yr | 1.87 | 265 | 1.22% | 10.8843 | 11.5 |
| Adjusted RR 2.00 / cap 0.20 | +$1,005.65 | +$388.14 | +$1,384.61 | 13.85% | 2.19%/yr | 1.86 | 265 | 1.22% | 10.7409 | 11.3525 |
| Adjusted RR 3.00 / cap 0.20 | +$1,001.72 | +$388.14 | +$1,380.68 | 13.81% | 2.18%/yr | 1.87 | 265 | 1.06% | 11.6838 | 13.0283 |
| **Adjusted RR 2.50 / cap 0.20 center** | +$1,001.72 | +$388.14 | +$1,380.68 | 13.81% | 2.18%/yr | 1.87 | 265 | 1.06% | 11.6838 | 13.0283 |
| Adjusted RR 2.50 / cap 0.18 | +$1,001.72 | +$388.14 | +$1,380.33 | 13.8% | 2.18%/yr | 1.87 | 265 | 1.06% | 11.6809 | 13.0189 |
| Adjusted RR 2.50 / cap 0.22 | +$1,001.72 | +$388.14 | +$1,380.68 | 13.81% | 2.18%/yr | 1.87 | 265 | 1.06% | 11.6838 | 13.0283 |

## Frozen Gate

- Every report profitable: `True`
- Center changed behavior and was no worse in both disjoint eras: `True`
- Center net at least 4% above control: `False` (`+$1,380.68` vs required `+$1,407.89`)
- Center CAGR at least 0.06 point above control: `False`
- Center PF/recovery/return-DD no worse than control: `True`
- Center drawdown and trade-count gates: `True`
- Center retained at least 50% of broad-reference incremental net: `True` (`54.59%`)
- Center improved DD/recovery/return-DD versus broad reference: `True`
- At least 3 of 4 orthogonal neighbors passed: `False` (`0/4`)

The center improved net profit by only `+$26.94` over the exact leader control in the sealed continuous window. It failed the preregistered growth, CAGR, and neighborhood gates, so no recent-data or Model 4 budget was spent.

The published strong-signal selective lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.
