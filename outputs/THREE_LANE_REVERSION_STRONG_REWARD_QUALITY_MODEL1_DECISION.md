# Three-Lane Reversion Strong-Reward Quality Model 1 Decision

**Decision: MODEL 1 GATE PASSED. The fixed center and neighbors may open Model 4 real-tick validation; no promotion or forward change is authorized.**

- Reports: `20 / 20` parsed and exact source/binary identity valid
- Attempts: `22`; identity-only retries: `2`
- Exact source SHA-256: `0AF69BFE66200C6CB6F1D4C83A3F4BF3989DFA79E15596A27F384787991A3186`
- Exact EX5 SHA-256: `730E3A347B4A1C8D2C724E7B5A124137AD50F0B91F200BC3D848CBDAECB9EF03`
- Candidate profile SHA-256: `75ADBEE281412F3BF8CDB1A4C3B4C3C90EBAE4E39E7FEF72E20D5D8B8A13F2F1`
- Fixed allocation: completed H1 body ratio `0.25` and requested risk `0.70%`
- Fixed adjusted reward/risk neighborhood: `1.35 / 1.50 / 1.65`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$860.86 | +$694.54 | +$601.99 | +$2,195.53 | 21.96% | 1.74%/yr | 1.83 | 415 | 1.17% | 15.8168 | 18.7692 |
| Body-only unfiltered diagnostic | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Lower neighbor RR 1.35 | +$860.86 | +$752.95 | +$682.60 | +$2,391.89 | 23.92% | 1.88%/yr | 1.89 | 415 | 1.21% | 16.562 | 19.7686 |
| Center RR 1.50 | +$860.86 | +$752.95 | +$631.16 | +$2,342.63 | 23.43% | 1.84%/yr | 1.88 | 415 | 1.21% | 16.221 | 19.3636 |
| Upper neighbor RR 1.65 | +$860.86 | +$752.95 | +$631.16 | +$2,342.63 | 23.43% | 1.84%/yr | 1.88 | 415 | 1.21% | 16.221 | 19.3636 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every tested era profitable | `True` | PASS |
| Center and both neighbors no worse in every era | `True` | PASS |
| Continuous net at least control +5% | `6.70%` | PASS |
| CAGR at least control +0.10 point | `0.1` point | PASS |
| PF no worse than control | `1.88` vs `1.83` | PASS |
| DD <=1.25% and <=control +0.08 point | `1.21%` vs `1.17%` | PASS |
| Recovery no worse than control | `16.221` vs `15.8168` | PASS |
| Return/DD no worse than control | `19.3636` vs `18.7692` | PASS |
| At least 400 continuous trades | `415` | PASS |
| RR 1.35 lower neighbor independently passes | net `+$2,391.89`; CAGR `1.88%`; recovery `16.562` | PASS |
| RR 1.65 upper neighbor independently passes | net `+$2,342.63`; CAGR `1.84%`; recovery `16.221` | PASS |

## Interpretation

The center changes no entry or exit rule. It allocates extra risk only when the already-valid completed-bar reversion also has spread-adjusted reward/risk of at least 1.50. Continuous Model 1 net improved by `6.70%` and CAGR by `0.1` point while both efficiency measures improved.

The center and both reward-quality neighbors passed the preregistered Model 1 growth and efficiency gates. A fixed Model 4 real-tick comparison may open, but this is not a promotion and the forward candidate remains unchanged.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
