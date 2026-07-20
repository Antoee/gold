# Tiered Strong-Signal Reversion Lot-Cap Discovery Decision

**Decision: REJECTED IN DISCOVERY. Recent data, Model 4, promotion, forward substitution, and live approval remain closed.**

- Exact accepted reports: `21/21`; attempts: `24`; identity refusals retried without changing configs: `3`
- Source SHA-256: `C5FF7608247DA628C5A8AF75BCAC31B70DEDCE42C7DBC2391F7B10F17847E054`
- EX5 SHA-256: `189225B2743CCB77D1E246E0AF3578695CB70B4679354739C910579A7120F2CA`
- Manifest SHA-256: `7EF9DF7F59667C572F23E6A4D9731C739933FA7E0684CFEBCF3CA7992CEDE281`
- `$10,000`; MT5 Model 1; 2015-2020 sealed discovery; requested reversion risk `0.45%`; portfolio cap `0.75%`; real trading disabled

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Control strong cap 0.15 | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 |
| Broad strong cap 0.20 | +$1,024.13 | +$388.14 | +$1,403.09 | 14.03% | 2.21%/yr | 1.87 | 265 | 1.22% | 10.8843 | 11.5 |
| Body 0.35 / cap 0.20 | +$1,017.35 | +$370.41 | +$1,369.37 | 13.69% | 2.16%/yr | 1.86 | 265 | 1.06% | 11.5881 | 12.9151 |
| Body 0.45 / cap 0.20 | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 |
| **Body 0.40 / cap 0.20 center** | +$1,017.35 | +$370.41 | +$1,369.37 | 13.69% | 2.16%/yr | 1.86 | 265 | 1.06% | 11.5881 | 12.9151 |
| Body 0.40 / cap 0.18 | +$1,017.35 | +$370.41 | +$1,369.37 | 13.69% | 2.16%/yr | 1.86 | 265 | 1.06% | 11.5881 | 12.9151 |
| Body 0.40 / cap 0.22 | +$1,017.35 | +$370.41 | +$1,369.37 | 13.69% | 2.16%/yr | 1.86 | 265 | 1.06% | 11.5881 | 12.9151 |

## Frozen Gate

- Every report profitable: `True`
- Center changed behavior and was no worse in both disjoint eras: `True`
- Center net at least 1.5% above control: `False` (`+$1,369.37` vs required `+$1,374.05`)
- Center CAGR at least 0.03 point above control: `False`
- Center PF/recovery/return-DD no worse than control: `True`
- Center drawdown and trade-count gates: `True`
- Center retained at least 40% of broad-reference incremental net: `False` (`31.67%`)
- Center improved DD/recovery/return-DD versus broad reference: `True`
- At least 3 of 4 orthogonal neighbors passed: `True` (`3/4`)

The center improved net profit by only `$15.63` over the exact leader control in the sealed continuous window. It failed the preregistered growth, CAGR, and incremental-retention gates, so no recent-data or Model 4 budget was spent.

The published strong-signal selective lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.
