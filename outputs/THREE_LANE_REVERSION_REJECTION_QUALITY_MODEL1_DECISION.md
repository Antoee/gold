# Three-Lane Reversion Rejection-Quality Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `16 / 16` parsed and exact source/binary identity valid
- Attempts: `17`; identity-only retries: `1`
- Exact source SHA-256: `BD1E4035A144127BF8120B7A3C31F0A6585CC30CB508F4D353C45BD7E87ED563`
- Exact EX5 SHA-256: `1E0FC0682515FF0E8230E849462BD96B7CA1A5F4C2E8F16170641906E0CE1707`
- Candidate profile SHA-256: `7CFFDC3F5DDB489D47EBC29DF60FA2203AB87CA50887E8693C266FAD4FBF737E`
- Fixed allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Fixed directional rejection-wick neighborhood: `20% / 25% / 30%`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Lower neighbor wick 20% | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Center wick 25% | +$860.86 | +$694.54 | +$682.60 | +$2,321.32 | 23.21% | 1.83%/yr | 1.87 | 415 | 1.22% | 16.0734 | 19.0246 |
| Upper neighbor wick 30% | +$860.86 | +$694.54 | +$682.60 | +$2,321.32 | 23.21% | 1.83%/yr | 1.87 | 415 | 1.22% | 16.0734 | 19.0246 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center and both neighbors no worse in every era | `True` | PASS |
| Continuous net at least control +5% | `5.73%` | PASS |
| CAGR at least control +0.10 point | `0.0900000000000001` point | FAIL |
| PF no worse than control | `1.87` vs `1.83` | PASS |
| DD <=1.25% and <=control +0.08 point | `1.22%` vs `1.17%` | PASS |
| Recovery no worse than control | `16.0734` vs `15.8168` | PASS |
| Return/DD no worse than control | `19.0246` vs `18.7692` | PASS |
| At least 400 continuous trades | `415` | PASS |
| Wick 20% lower neighbor independently passes | net `+$2,391.89`; CAGR `1.88%`; recovery `16.562` | PASS |
| Wick 30% upper neighbor independently passes | net `+$2,321.32`; CAGR `1.83%`; recovery `16.0734` | PASS |

## Interpretation

The center changes no entry or exit rule. It allocates extra risk only when the already-valid completed-H1 reversion meets body ratio 0.25 and has a directional rejection wick of at least 25%. Continuous Model 1 net improved by `5.73%` and both efficiency measures improved, but CAGR rose by only `0.0900000000000001` point versus the frozen 0.10-point requirement.

The 20% lower neighbor reproduced the prior body-only allocation, while the 25% and 30% rows removed part of that improvement. The center missed the frozen CAGR gate by 0.01 point. The gate is not relaxed after observation; Model 4 stays closed and ATB150 remains the historical champion. Center recovery difference versus control: `0.2566`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
