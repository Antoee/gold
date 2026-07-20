# Three-Lane Reversion Strong-Signal Tick Protection Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `20 / 20` parsed and exact source/binary identity valid
- Attempts: `21`; identity-only retries: `1`
- Exact source SHA-256: `096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248`
- Exact EX5 SHA-256: `C8F436B0474D166020B210731EF553E64F9BC49700C99FB25F2AA69972ECFBC2`
- Candidate profile SHA-256: `D6D608320EABFD333B311DDFEE0F17C4ABE66F64D6440B38269BE7D8B5BB7859`
- Fixed allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Fixed every-tick protection neighborhood: `1.00R / 0.05R`, `1.00R / 0.10R`, `1.25R / 0.10R`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Strong allocation without protection | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Lower lock 1.00R / 0.05R | +$784.58 | +$638.99 | +$741.50 | +$2,276.59 | 22.77% | 1.8%/yr | 1.88 | 414 | 1.15% | 17.0212 | 19.8 |
| Center 1.00R / 0.10R | +$793.76 | +$640.19 | +$744.30 | +$2,289.77 | 22.9% | 1.8%/yr | 1.88 | 414 | 1.15% | 17.1198 | 19.913 |
| Later trigger 1.25R / 0.10R | +$793.76 | +$640.19 | +$682.60 | +$2,236.83 | 22.37% | 1.77%/yr | 1.85 | 414 | 1.23% | 15.4884 | 18.187 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center and both neighbors no worse in every era | `False` | FAIL |
| Protection changes at least one frozen report | `True` | PASS |
| Continuous net at least control +5% | `4.29%` | FAIL |
| Continuous net retains at least 97% of strong-only | `95.73%` | FAIL |
| CAGR >=control +0.10 point and >=strong-only -0.03 point | `1.8%` | FAIL |
| PF no worse than strong-only | `1.88` vs `1.89` | FAIL |
| DD <=1.25% and no worse than strong-only | `1.15%` vs `1.21%` | PASS |
| Recovery no worse than strong-only | `17.1198` vs `16.562` | PASS |
| Return/DD no worse than strong-only | `19.913` vs `19.7686` | PASS |
| At least 400 continuous trades | `414` | PASS |
| 1.00R / 0.05R neighbor independently passes | net `+$2,276.59`; CAGR `1.8%`; recovery `17.0212` | PASS |
| 1.25R / 0.10R neighbor independently passes | net `+$2,236.83`; CAGR `1.77%`; recovery `15.4884` | FAIL |

## Interpretation

The branch keeps the completed-H1 body 0.25 / risk 0.70% allocation and evaluates one tightening-only stop path on every executable tick. The center changed behavior and improved strong-only drawdown from `1.21%` to `1.15%` and recovery from `16.562` to `17.1198`, but net fell to `+$2,289.77` and CAGR to `1.8%`.

The center improved risk efficiency but failed the frozen growth and strong-only retention gates; the 1.25R neighbor also failed its independent support gate. No threshold is substituted inside this observed contract. Model 4 stays closed and ATB150 remains the historical champion. Center recovery difference versus strong-only: `0.5578`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
