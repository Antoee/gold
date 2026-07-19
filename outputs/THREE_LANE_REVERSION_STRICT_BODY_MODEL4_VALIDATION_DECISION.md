# Three-Lane Reversion Strict-Body Model4 Validation Decision

**Decision: REJECTED IN MODEL4. No research promotion, annual/stress expansion, forward change, or live approval is permitted.**

- Reports: `8 / 8` parsed and exact source/binary identity valid
- Exact source SHA-256: `36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF`
- Exact EX5 SHA-256: `975976F6FEB7659B75B073B93B69D3964A09A82EDF077A87F1CF2348A26A4E1B`
- Candidate profile SHA-256: `12C0F7C82697DEC779083B09D18244C4D4E56A3C624221DA0F11B2E30E95E57C`
- Fixed candidate: completed H1 body ratio `0.25` and strong-signal requested risk `0.70%`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$856.18 | +$572.09 | +$602.11 | +$2,105.08 | 21.05% | 1.67%/yr | 1.81 | 404 | 1.15% | 15.6686 | 18.3043 |
| Fixed body 0.25 / risk 0.70% | +$856.18 | +$633.49 | +$682.79 | +$2,284.81 | 22.85% | 1.8%/yr | 1.87 | 404 | 1.23% | 15.6666 | 18.5772 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every control/candidate era profitable | `True` | PASS |
| Candidate net no worse in every era | `True` | PASS |
| Continuous net at least control +5% | `8.54%` | PASS |
| CAGR at least control +0.10 point | `0.13` point | PASS |
| PF no worse than control | `1.87` vs `1.81` | PASS |
| DD <=1.35% and <=control +0.10 point | `1.23%` vs `1.15%` | PASS |
| Recovery no worse than control | `15.6666` vs `15.6686` | FAIL |
| Return/DD no worse than control | `18.5772` vs `18.3043` | PASS |
| At least 400 continuous trades | `404` | PASS |

## Interpretation

The fixed candidate increased continuous real-tick net by `8.54%` and CAGR by `0.13` point while PF improved and drawdown stayed inside its absolute and relative ceilings. It also matched or beat control net in all three disjoint eras.

It nevertheless failed the preregistered recovery requirement: `15.6666` versus control at `15.6686`, a difference of `-0.0020`. The gate is not rounded away or relaxed after observing the result. The candidate is rejected, annual/cost/Monte Carlo expansion stays closed, and ATB150 remains the historical champion.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
