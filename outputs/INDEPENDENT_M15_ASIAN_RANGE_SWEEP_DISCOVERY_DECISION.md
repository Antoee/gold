# Independent M15 Asian-Range Sweep Decision

Decision date: 2026-07-17

**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

- Source: `work/Independent_XAUUSD_M15_Asian_Range_Sweep.mq5`
- Source SHA-256: `C757E57C98EFABE7C9A84EEE912D181539AF346DCDCD0B6758F9F0AE22C71EFB`
- Compiled binary SHA-256: `FFFE1D0EB792FFDF16F32B976DD58D298E818CF5ACDD26DE1348D7B7C5354B01`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Identity-valid reports parsed: `30 / 30`
- Candidate variants: `10`
- Risk per trade: `0.10%`
- 2021-2026 holdout configurations run: `0`
- Model 4 configurations run: `0`

Two initial portable rows hit startup identity races. Only their exact frozen configurations were rerun; both passed source identity on retry, and the canonical run evidence contains one identity-valid result per queue rank.

## Discovery Evidence

The frozen gate required both disjoint eras to be profitable with PF at least 1.05, continuous PF at least 1.20, at least 100 trades, DD no greater than 3.00%, positive expected payoff, return/DD at least 1.00, and support from the center plus two one-factor neighbors. No row passed the base gate.

| Candidate | 2015-2018 | PF | 2019-2020 | PF | Continuous | PF | Payoff | Trades | DD | Return/DD | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `ars_adx24` | `-$32.94` | `0.83` | `-$32.22` | `0.56` | `-$65.16` | `0.76` | `-1.63` | `40` | `1.24%` | `-0.53` | rejected |
| `ars_volume105` | `-$78.59` | `0.67` | `-$26.56` | `0.81` | `-$110.05` | `0.71` | `-1.80` | `61` | `1.76%` | `-0.63` | rejected |
| `ars_midpoint` | `-$97.86` | `0.57` | `-$22.60` | `0.86` | `-$121.21` | `0.69` | `-1.92` | `63` | `2.01%` | `-0.60` | rejected |
| `ars_entry10` | `-$137.09` | `0.48` | `-$12.06` | `0.92` | `-$160.25` | `0.62` | `-2.26` | `71` | `2.05%` | `-0.78` | rejected |
| `ars_rr20` | `-$224.06` | `0.46` | `-$33.20` | `0.85` | `-$262.00` | `0.59` | `-2.54` | `103` | `3.20%` | `-0.82` | rejected |
| `ars_sweep05` | `-$212.61` | `0.49` | `-$42.57` | `0.80` | `-$263.39` | `0.59` | `-2.56` | `103` | `3.17%` | `-0.83` | rejected |
| `ars_reclaim05` | `-$212.61` | `0.49` | `-$42.57` | `0.80` | `-$263.39` | `0.59` | `-2.56` | `103` | `3.17%` | `-0.83` | rejected |
| `ars_center` | `-$212.61` | `0.49` | `-$42.57` | `0.80` | `-$263.39` | `0.59` | `-2.56` | `103` | `3.17%` | `-0.83` | rejected |
| `ars_wick15` | `-$306.67` | `0.11` | `+$27.17` | `1.21` | `-$295.16` | `0.39` | `-3.74` | `79` | `3.88%` | `-0.76` | rejected |
| `ars_sweep15` | `-$220.69` | `0.48` | `-$79.71` | `0.64` | `-$305.79` | `0.53` | `-2.94` | `104` | `3.57%` | `-0.86` | rejected |

The center placed 103 continuous trades but lost $263.39 at PF 0.59, with losses in both disjoint eras. The least-bad ADX-filtered row still lost $65.16 continuously at PF 0.76 and produced only 40 trades. Tick-volume, midpoint-target, earlier-session, deeper-sweep, and higher-payoff variants also remained negative. The session-transition false-break hypothesis has no broad pre-2021 edge at the frozen geometry.

## Decision

- Reject this Asian-range sweep/reclaim neighborhood; do not tune it on recent data.
- Skip holdout and Model 4 because the broad pre-2021 gate failed.
- Do not merge the engine into the frozen forward candidate.
- Preserve the registered source/profile/binary identity, evidence logs, and hard real-account lock unchanged.

## Evidence

- `outputs/INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_CONTRACT.md`
- `outputs/INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_M15_ASIAN_RANGE_SWEEP_DISCOVERY_DECISION.csv`
