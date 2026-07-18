# Reversion Shock-Guard Portfolio Discovery Decision

Decision date: 2026-07-17

**Verdict: rejected at the frozen pre-2021 Model 1 gate. No post-2020 holdout or Model 4 configuration was opened, no new best was promoted, and the registered candidate remains unchanged.**

## Evidence Boundary

- Research source SHA-256: `A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9`
- Compiled binary SHA-256: `7B6386477A6205F77AB91484A585E27B88517B3BE288F700AC911A5B7C8BFABB`
- Compile result: `0 errors, 0 warnings`
- Identity-valid reports parsed: `56 / 56`
- Profiles: `14`
- Latest data used: `2020-12-31`
- Post-2020 holdout runs: `0`
- Model 4 runs: `0`
- Real-account trading: disabled

Five initial portable rows hit source-identity startup races. Only those exact frozen ranks were rerun; all five passed, and the canonical run contains one valid result per queue rank.

## Results

| Profile | MO risk | DI | Body gate/min | 2015-2018 | 2019 / PF | 2020 / PF | 2019+2020 | Continuous / PF | Trades | DD | Return/DD | Base gate | Failed gates |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `rsg_mo015_body25` | `0.15%` | `-12` | `25%` | `+$591.58` | `-$4.98 / 0.98` | `+$64.31 / 1.24` | `+$59.33` | `+$645.20 / 1.47` | `211` | `1.40%` | `4.61` | `False` | `2019-net;2019-pf;continuous-pf` |
| `rsg_mo015_combo20` | `0.15%` | `-10` | `20%` | `+$599.56` | `-$4.98 / 0.98` | `+$66.30 / 1.25` | `+$61.32` | `+$655.17 / 1.48` | `211` | `1.49%` | `4.40` | `False` | `2019-net;2019-pf;continuous-pf` |
| `rsg_mo015_combo25` | `0.15%` | `-10` | `25%` | `+$547.52` | `-$4.98 / 0.98` | `+$109.32 / 1.49` | `+$104.34` | `+$650.10 / 1.51` | `208` | `1.41%` | `4.61` | `False` | `2019-net;2019-pf` |
| `rsg_mo015_combo25_di08` | `0.15%` | `-8` | `25%` | `+$505.25` | `+$26.32 / 1.13` | `+$163.81 / 1.90` | `+$190.13` | `+$678.43 / 1.56` | `205` | `1.12%` | `6.06` | `True` | `` |
| `rsg_mo015_combo30` | `0.15%` | `-10` | `30%` | `+$614.32` | `-$4.98 / 0.98` | `+$59.98 / 1.33` | `+$55.00` | `+$663.61 / 1.56` | `204` | `1.40%` | `4.74` | `False` | `2019-net;2019-pf` |
| `rsg_mo015_control` | `0.15%` | `-12` | `off` | `+$814.70` | `-$4.98 / 0.98` | `-$100.47 / 0.77` | `-$105.45` | `+$694.13 / 1.42` | `225` | `2.77%` | `2.51` | `False` | `2019-net;2019-pf;2020-net;2020-pf;repair-sum;continuous-pf` |
| `rsg_mo015_di10` | `0.15%` | `-10` | `off` | `+$663.37` | `-$4.98 / 0.98` | `+$66.30 / 1.25` | `+$61.32` | `+$719.25 / 1.51` | `216` | `1.49%` | `4.83` | `False` | `2019-net;2019-pf` |
| `rsg_mo020_body25` | `0.20%` | `-12` | `25%` | `+$743.65` | `-$2.17 / 0.99` | `+$81.80 / 1.23` | `+$79.63` | `+$859.99 / 1.46` | `211` | `1.69%` | `5.09` | `False` | `2019-net;2019-pf;continuous-pf` |
| `rsg_mo020_combo20` | `0.20%` | `-10` | `20%` | `+$761.80` | `-$2.17 / 0.99` | `+$83.79 / 1.24` | `+$81.62` | `+$880.13 / 1.47` | `211` | `1.75%` | `5.03` | `False` | `2019-net;2019-pf;continuous-pf` |
| `rsg_mo020_combo25` | `0.20%` | `-10` | `25%` | `+$683.43` | `-$2.17 / 0.99` | `+$126.81 / 1.41` | `+$124.64` | `+$836.21 / 1.47` | `208` | `1.70%` | `4.92` | `False` | `2019-net;2019-pf;continuous-pf` |
| `rsg_mo020_combo25_di08` | `0.20%` | `-8` | `25%` | `+$644.31` | `+$29.13 / 1.10` | `+$179.59 / 1.66` | `+$208.72` | `+$867.69 / 1.51` | `205` | `1.41%` | `6.15` | `True` | `` |
| `rsg_mo020_combo30` | `0.20%` | `-10` | `30%` | `+$781.47` | `-$2.17 / 0.99` | `+$77.47 / 1.29` | `+$75.30` | `+$893.48 / 1.53` | `204` | `1.68%` | `5.32` | `False` | `2019-net;2019-pf` |
| `rsg_mo020_control` | `0.20%` | `-12` | `off` | `+$936.30` | `-$2.17 / 0.99` | `-$82.98 / 0.84` | `-$85.15` | `+$889.12 / 1.41` | `225` | `3.05%` | `2.92` | `False` | `2019-net;2019-pf;2020-net;2020-pf;repair-sum;continuous-pf;drawdown` |
| `rsg_mo020_di10` | `0.20%` | `-10` | `off` | `+$816.88` | `-$2.17 / 0.99` | `+$83.79 / 1.24` | `+$81.62` | `+$954.80 / 1.49` | `216` | `1.74%` | `5.49` | `False` | `2019-net;2019-pf;continuous-pf` |

## Interpretation

The mechanism repaired the targeted 2020 weakness. At `0.15%` momentum risk, the nominated body-25 center changed 2020 from `-$100.47` to `+$109.32`. At `0.20%`, it changed 2020 from `-$82.98` to `+$126.81`.

It did not repair both weak years. The `0.15%` center still returned `-$4.98` with PF `0.98` in 2019. The `0.20%` center returned `-$2.17` with PF `0.99`, and its continuous PF was `1.47` against the frozen `1.50` floor.

The stricter DI `-8` rows were the only two base-gate passes: `+$678.43` at `0.15%` and `+$867.69` at `0.20%`. The contract explicitly required both nominated DI `-10` centers plus body-threshold neighbors. Substituting the isolated stricter-DI rows after seeing results would be threshold selection, so the family stops here.

## Decision

- Do not use post-2020 data to rescue or choose another threshold.
- Skip Model 4, annual restarts, cost stress, and Monte Carlo for this branch.
- Do not alter the current historical best or frozen forward candidate.
- Preserve the account contract, evidence identities, and real-account hard lock.

## Evidence

- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_CONTRACT.md`
- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_COMPILE_EVIDENCE.csv`
- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv`
- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_DECISION.csv`
