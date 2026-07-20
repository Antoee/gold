# Three-Lane Strong-Reversion / ATB Session Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `20 / 20` parsed and exact source/binary identity valid
- Attempts: `21`; identity-only retries: `1`
- Exact source SHA-256: `096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248`
- Exact EX5 SHA-256: `C8F436B0474D166020B210731EF553E64F9BC49700C99FB25F2AA69972ECFBC2`
- Strong-reversion allocation: completed-H1 body ratio `0.25`, requested risk `0.70%`; adaptive-trend risk `0.15%`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| ATB150 champion control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Strong-reversion control | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Session 12-1 | +$780.50 | +$766.18 | +$682.60 | +$2,332.93 | 23.33% | 1.84%/yr | 1.91 | 392 | 1.21% | 16.1538 | 19.281 |
| Session 16-1 center | +$799.29 | +$760.45 | +$682.60 | +$2,344.44 | 23.44% | 1.84%/yr | 1.93 | 384 | 1.21% | 16.2335 | 19.3719 |
| Session 16-9 | +$884.46 | +$747.59 | +$682.60 | +$2,398.19 | 23.98% | 1.88%/yr | 1.9 | 408 | 1.21% | 16.6057 | 19.8182 |

## Frozen Gate

- Every report profitable: `True` (PASS)
- Center beats champion in every era: `False` (FAIL)
- Center beats strong control in every era: `False` (FAIL)
- Center growth gate: `False` (FAIL)
- Center CAGR gate: `False` (FAIL)
- Center PF/recovery/return-DD gate: `False` (FAIL)
- Center drawdown/activity gate: `True` (PASS)
- Session 12-1 neighbor gate: `False` (FAIL)
- Session 16-9 neighbor gate: `False` (FAIL)

## Interpretation

The 16-1 center reduced continuous net from strong control at `+$2,391.89` to `+$2,344.44` and reduced trades from `415` to `384`. Its older-era net fell from `+$860.86` to `+$799.29`. The 12-1 neighbor was weaker, while 16-9 added only `+$6.30` and did not improve CAGR.

The ledger-hour pattern did not transfer into a robust portfolio improvement. The session family is rejected without another hour search, Model 4 stays closed, and ATB150 remains the historical champion.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
