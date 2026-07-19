# Three-Lane Reversion Strict-Body Real-Tick Plateau Decision

**Decision: REJECTED IN MODEL4. No research promotion, annual/stress expansion, forward change, or live approval is permitted.**

- Reports: `12 / 12` parsed and exact source/binary identity valid
- Exact source SHA-256: `36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF`
- Exact EX5 SHA-256: `1B86001F62CE3AC4FDB29FF1E9D4DA34120FEFB37E1540A952186553E2D9845F`
- Candidate profile SHA-256: `F56A63DFC8C9C214EB7F2A3E66F85231CE0E1DB5ACE152E21871312769750704`
- Fixed center: completed H1 body ratio `0.25` and strong-signal requested risk `0.65%`
- Fixed upper neighbor: completed H1 body ratio `0.25` and requested risk `0.675%`
- Real-account trading: disabled

| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled-feature control | +$856.18 | +$572.09 | +$602.11 | +$2,105.08 | 21.05% | 1.67%/yr | 1.81 | 404 | 1.15% | 15.6686 | 18.3043 |
| Center body 0.25 / risk 0.65% | +$856.18 | +$620.19 | +$671.88 | +$2,271.52 | 22.72% | 1.79%/yr | 1.87 | 404 | 1.23% | 15.5754 | 18.4715 |
| Neighbor body 0.25 / risk 0.675% | +$856.18 | +$633.49 | +$682.79 | +$2,271.52 | 22.72% | 1.79%/yr | 1.87 | 404 | 1.23% | 15.5754 | 18.4715 |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Every control/center/neighbor era profitable | `True` | PASS |
| Center and neighbor net no worse in every era | `True` | PASS |
| Continuous net at least control +5% | `7.91%` | PASS |
| CAGR at least control +0.10 point | `0.12` point | PASS |
| PF no worse than control | `1.87` vs `1.81` | PASS |
| DD <=1.30% and <=control +0.10 point | `1.23%` vs `1.15%` | PASS |
| Recovery no worse than control | `15.5754` vs `15.6686` | FAIL |
| Return/DD no worse than control | `18.4715` vs `18.3043` | PASS |
| At least 400 continuous trades | `404` | PASS |
| 0.675% upper neighbor independently passes | net `+$2,271.52`; CAGR `1.79%`; recovery `15.5754` | FAIL |

## Interpretation

The center changed no entry or exit rule. It only applies the already-audited completed-bar strong-signal allocation and increased continuous real-tick net by `7.91%` with a CAGR change of `0.12` point.

At least one preregistered center or plateau gate failed. The gate is not rounded away or relaxed after observing the result; annual/cost/Monte Carlo expansion stays closed and ATB150 remains the historical champion. Center recovery difference versus control: `-0.0932`.

The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
