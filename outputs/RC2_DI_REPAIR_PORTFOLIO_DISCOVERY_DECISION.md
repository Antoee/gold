# RC2 DI-Repair Portfolio Discovery Decision

Decision date: 2026-07-17

**Verdict: rejected at the frozen pre-2021 Model 1 gate. No post-2020 holdout or Model 4 configuration was opened, no new best was promoted, and the registered candidate remains unchanged.**

## Evidence Boundary

- Exact RC2 source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Identity-valid reports parsed: `24 / 24`
- Profiles: `6`
- Latest data used: `2020-12-31`
- Post-2020 holdout runs: `0`
- Model 4 runs: `0`
- Real-account trading: disabled

One initial portable row hit a source-identity startup race. Only that exact frozen rank was rerun; it passed, and the canonical run contains one valid result per queue rank.

## Results

| Profile | MO risk | DI | 2015-2018 | 2019 | PF | 2020 | PF | 2019+2020 | Continuous | PF | Trades | DD | Return/DD | Base gate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `dir_mo015_di12_control` | `0.15%` | `-12` | `+$814.70` | `-$4.98` | `0.98` | `-$100.47` | `0.77` | `-$105.45` | `+$694.13` | `1.42` | `225` | `2.77%` | `2.51` | `False` |
| `dir_mo015_di10_center` | `0.15%` | `-10` | `+$663.37` | `-$4.98` | `0.98` | `+$66.30` | `1.25` | `+$61.32` | `+$719.25` | `1.51` | `216` | `1.49%` | `4.83` | `True` |
| `dir_mo015_di08_strict` | `0.15%` | `-8` | `+$566.94` | `+$26.32` | `1.13` | `+$163.81` | `1.90` | `+$190.13` | `+$736.17` | `1.57` | `210` | `1.11%` | `6.63` | `True` |
| `dir_mo020_di12_control` | `0.20%` | `-12` | `+$936.30` | `-$2.17` | `0.99` | `-$82.98` | `0.84` | `-$85.15` | `+$889.12` | `1.41` | `225` | `3.05%` | `2.92` | `False` |
| `dir_mo020_di10_center` | `0.20%` | `-10` | `+$816.88` | `-$2.17` | `0.99` | `+$83.79` | `1.24` | `+$81.62` | `+$954.80` | `1.49` | `216` | `1.74%` | `5.49` | `False` |
| `dir_mo020_di08_strict` | `0.20%` | `-8` | `+$707.08` | `+$29.13` | `1.10` | `+$179.59` | `1.66` | `+$208.72` | `+$939.03` | `1.52` | `210` | `1.44%` | `6.52` | `True` |

## Interpretation

The intervention materially repaired the targeted weakness. At `0.20%` momentum risk, DI `-10` changed 2020 from `-$82.98` to `+$83.79`, increased continuous pre-2021 net from `+$889.12` to `+$954.80`, and reduced drawdown from `3.05%` to `1.74%`.

The primary center nevertheless reported PF `1.49` against the frozen `1.50` floor. The stricter DI `-8` neighbor passed at both risk allocations, including `+$939.03` and PF `1.52` at `0.20%`, but the contract required both nominated DI `-10` centers to pass. Replacing the center after seeing results would be threshold selection, so the family stops here.

## Decision

- Do not use post-2020 data to rescue or choose a different DI threshold.
- Skip Model 4, annual restarts, cost stress, and Monte Carlo for this branch.
- Do not alter the current historical best or frozen forward candidate.
- Preserve the account contract, evidence identities, and real-account hard lock.

## Evidence

- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_CONTRACT.md`
- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv`
- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_DECISION.csv`
