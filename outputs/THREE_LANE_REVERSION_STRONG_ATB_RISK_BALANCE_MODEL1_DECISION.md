# Three-Lane Reversion Strong-Signal / ATB Risk-Balance Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `16 / 16` parsed and exact source/binary identity valid
- Attempts: `17`; identity-only retries: `1`
- Exact source SHA-256: `096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248`
- Exact EX5 SHA-256: `C8F436B0474D166020B210731EF553E64F9BC49700C99FB25F2AA69972ECFBC2`
- Candidate profile SHA-256: `71782EF34D9FFC8792D7C863C02151F72B1218B741E5788D3D51490AEC5517F7`
- Fixed strong-reversion allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Tested adaptive-trend risk neighborhood: `0.13% / 0.14% / 0.15%`; disabled-feature control remains `0.15%`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control / ATB 0.15% | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Lower neighbor ATB 0.13% | +$857.94 | +$720.39 | +$682.60 | +$2,311.33 | 23.11% | 1.82%/yr | 1.9 | 396 | 1.25% | 15.4936 | 18.488 |
| Center ATB 0.14% | +$846.12 | +$725.81 | +$682.60 | +$2,367.32 | 23.67% | 1.86%/yr | 1.9 | 407 | 1.21% | 16.3919 | 19.562 |
| Upper neighbor ATB 0.15% | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center no worse than control in every era | `False` | FAIL |
| ATB 0.13% lower neighbor no worse in every era | `False` | FAIL |
| ATB 0.15% upper neighbor no worse in every era | `True` | PASS |
| Continuous net at least control +5% | `7.82%` | PASS |
| CAGR at least control +0.10 point | `0.12` point | PASS |
| PF no worse than control | `1.9` vs `1.83` | PASS |
| DD <=1.25% and <=control +0.08 point | `1.21%` vs `1.17%` | PASS |
| Recovery no worse than control | `16.3919` vs `15.8168` | PASS |
| Return/DD no worse than control | `19.562` vs `18.7692` | PASS |
| At least 400 continuous trades | `407` | PASS |
| ATB 0.13% lower neighbor independently passes | net `+$2,311.33`; CAGR `1.82%`; recovery `15.4936`; trades `396` | FAIL |
| ATB 0.15% upper neighbor independently passes | net `+$2,391.89`; CAGR `1.88%`; recovery `16.562`; trades `415` | PASS |

## Interpretation

The center changes no entry or exit rule. It holds the strong-reversion body threshold and risk fixed while reducing only the weaker adaptive-trend lane from 0.15% to 0.14%. Continuous Model 1 net improved by `7.82%`; CAGR improved by `0.12` point, and PF, recovery, return/DD, drawdown, and trade count passed. However, its 2015-2018 net was `+$846.12` versus `+$860.86` for control, so the required every-era gate failed.

The 0.14% center failed the older-era gate. The 0.13% lower neighbor also failed its older-era, recovery, return/DD, and 400-trade requirements; only the 0.15% upper neighbor passed independently. The broad neighborhood is rejected without relaxing its contract and Model 4 stays closed. A separately frozen narrow 0.135% / 0.140% / 0.145% plateau may be tested as a new follow-up; ATB150 remains the historical champion. Center recovery difference versus control: `0.5751`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
