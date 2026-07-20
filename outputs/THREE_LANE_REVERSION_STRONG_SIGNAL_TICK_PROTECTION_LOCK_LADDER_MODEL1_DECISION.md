# Three-Lane Reversion Strong-Signal Tick Protection Lock Ladder Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `24 / 24` parsed and exact source/binary identity valid
- Attempts: `27`; identity-only retries: `3`
- Exact source SHA-256: `096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248`
- Exact EX5 SHA-256: `C8F436B0474D166020B210731EF553E64F9BC49700C99FB25F2AA69972ECFBC2`
- Candidate profile SHA-256: `059C89204B5F443AC791BC49004BA5D393B1809968CE48967FF39C94BD737D61`
- Fixed allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Fixed 1.00R-trigger lock ladder: observed reference `0.10R`; new neighborhood `0.15R / 0.20R / 0.25R`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Strong allocation without protection | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Observed reference lock 0.10R | +$793.76 | +$640.19 | +$744.30 | +$2,289.77 | 22.9% | 1.8%/yr | 1.88 | 414 | 1.15% | 17.1198 | 19.913 |
| Lower neighbor lock 0.15R | +$795.16 | +$427.68 | +$747.10 | +$2,088.51 | 20.89% | 1.66%/yr | 1.81 | 415 | 1.31% | 14.1412 | 15.9466 |
| Center lock 0.20R | +$702.50 | +$432.38 | +$749.90 | +$2,005.83 | 20.06% | 1.6%/yr | 1.8 | 412 | 1.3% | 13.7678 | 15.4308 |
| Upper neighbor lock 0.25R | +$705.20 | +$436.98 | +$752.70 | +$2,007.78 | 20.08% | 1.6%/yr | 1.8 | 412 | 1.28% | 13.973 | 15.6875 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center and both neighbors no worse in every era | `False` | FAIL |
| Protection changes at least one frozen report | `True` | PASS |
| Continuous net at least control +5% | `-8.64%` | FAIL |
| Continuous net retains at least 97% of strong-only | `83.86%` | FAIL |
| CAGR >=control +0.10 point and >=strong-only -0.03 point | `1.6%` | FAIL |
| PF no worse than strong-only | `1.8` vs `1.89` | FAIL |
| DD <=1.25% and no worse than strong-only | `1.3%` vs `1.21%` | FAIL |
| Recovery no worse than strong-only | `13.7678` vs `16.562` | FAIL |
| Return/DD no worse than strong-only | `15.4308` vs `19.7686` | FAIL |
| At least 400 continuous trades | `412` | PASS |
| 0.15R lower neighbor independently passes | net `+$2,088.51`; CAGR `1.66%`; recovery `14.1412` | FAIL |
| 0.25R upper neighbor independently passes | net `+$2,007.78`; CAGR `1.6%`; recovery `13.973` | FAIL |

## Interpretation

The ladder fixes the every-tick trigger at 1.00R and raises only the profit-lock distance. The 0.20R center fell to `+$2,005.83`, `1.6%` CAGR, PF `1.8`, `1.3%` drawdown, and recovery `13.7678`. Both new neighbors also underperformed disabled control.

The higher-lock ladder failed growth, drawdown, recovery, and neighbor support. Its non-monotonic path response contradicts a simple retained-profit improvement, so this protection family closes without another lock or trigger search. Model 4 stays closed and ATB150 remains the historical champion. Center recovery difference versus strong-only: `-2.7942`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
