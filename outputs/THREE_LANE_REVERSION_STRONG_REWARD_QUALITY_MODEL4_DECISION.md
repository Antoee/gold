# Three-Lane Reversion Strong-Reward Quality Model 4 Decision

**Decision: REJECTED IN MODEL 4. No annual, cost, Monte Carlo, promotion, forward change, or live approval is permitted.**

- Reports: `16 / 16` parsed and exact source/binary identity valid
- Attempts: `16`; identity-only retries: `0`
- Exact source SHA-256: `0AF69BFE66200C6CB6F1D4C83A3F4BF3989DFA79E15596A27F384787991A3186`
- Exact EX5 SHA-256: `730E3A347B4A1C8D2C724E7B5A124137AD50F0B91F200BC3D848CBDAECB9EF03`
- Candidate profile SHA-256: `C3914CB56C50AF43D0F289CBA626E740DA0E840BEA0B61A584EF3AD9F0C5CABC`
- Fixed allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Fixed adjusted reward/risk neighborhood: `1.35 / 1.50 / 1.65`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$856.18 | +$572.09 | +$602.11 | +$2,105.08 | 21.05% | 1.67%/yr | 1.81 | 404 | 1.15% | 15.6686 | 18.3043 |
| Lower neighbor RR 1.35 | +$856.18 | +$633.49 | +$682.79 | +$2,284.81 | 22.85% | 1.8%/yr | 1.87 | 404 | 1.23% | 15.6666 | 18.5772 |
| Center RR 1.50 | +$856.18 | +$633.49 | +$631.23 | +$2,236.41 | 22.36% | 1.77%/yr | 1.85 | 404 | 1.24% | 15.3347 | 18.0323 |
| Upper neighbor RR 1.65 | +$856.18 | +$633.49 | +$631.23 | +$2,236.41 | 22.36% | 1.77%/yr | 1.85 | 404 | 1.24% | 15.3347 | 18.0323 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center and both neighbors no worse in every era | `True` | PASS |
| Continuous net at least control +5% | `6.24%` | PASS |
| CAGR at least control +0.10 point | `0.1` point | PASS |
| PF no worse than control | `1.85` vs `1.81` | PASS |
| DD <=1.25% and <=control +0.08 point | `1.24%` vs `1.15%` | FAIL |
| Recovery no worse than control | `15.3347` vs `15.6686` | FAIL |
| Return/DD no worse than control | `18.0323` vs `18.3043` | FAIL |
| At least 400 continuous trades | `404` | PASS |
| RR 1.35 lower neighbor independently passes | net `+$2,284.81`; CAGR `1.8%`; recovery `15.6666` | FAIL |
| RR 1.65 upper neighbor independently passes | net `+$2,236.41`; CAGR `1.77%`; recovery `15.3347` | FAIL |

## Interpretation

The center changes no entry or exit rule. It allocates extra risk only when the already-valid completed-bar reversion also has spread-adjusted reward/risk of at least 1.50. Continuous real-tick Model 4 net improved by `6.24%` and CAGR by `0.1` point, but recovery, return-to-drawdown, and relative drawdown failed their frozen gates.

The center added reward, but failed recovery, return-to-drawdown, and relative-drawdown requirements. The RR 1.35 lower neighbor retained higher return-to-drawdown but missed the no-worse recovery gate by `0.0020`. The frozen gate is not relaxed after observation; annual and stress testing stay closed, and ATB150 remains the historical champion. Center recovery difference versus control: `-0.3339`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
