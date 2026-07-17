# Independent H1 Reversion Scheduling Decision

Decision date: 2026-07-16

**Verdict: rejected during Model 1 discovery. No 2021-2026 implementation-validation run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Hypothesis

The frozen three-lane EA already contains the validated H1 Band/VWAP reversion lane, but normally considers it only when the primary lane is idle. This experiment added a default-off scheduling switch that could attempt the same reversion signal independently under the shared open-risk cap, with at most two EA positions. It changed scheduling rather than inventing a fourth signal family.

- Experimental source: `work/Professional_XAUUSD_EA_REVERSION_INDEPENDENT.mq5`
- Experimental source SHA-256: `2108099D19EBF2E8D86709FFAA37331559EDA745794E1B01A1A4DA0C6C38CEEB`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Configurations returned and parsed: `45 / 45`
- Candidate variants: `4` plus one exact control
- Recent implementation-validation configurations run: `0`
- Model 4 configurations run: `0`

## Discovery Evidence

The exact control reproduced its established broad-window values. All four independent variants remained positive continuously and increased trade count, but every variant failed the predeclared robustness gate:

- neither disjoint broad era improved over control;
- 2017 and 2019 remained red and became more negative;
- continuous profit factor fell from `4.76` to `2.87-3.43`;
- continuous maximum drawdown rose from `0.77%` to `1.06-1.09%`;
- the largest continuous-profit gain was only `$34.11` over six years and came with worse risk quality.

| Candidate | 2015-2018 | 2019-2020 | Continuous 2015-2020 | PF | Max DD | Trades | Red years | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `ri_control` | `+$184.32` | `+$108.33` | `+$252.65` | `4.76` | `0.77%` | `15` | 2017, 2019 | control confirmed |
| `ri_m12_r30` | `+$181.36` | `+$92.02` | `+$272.49` | `3.08` | `1.09%` | `24` | 2017, 2019 | rejected |
| `ri_m12_r40` | `+$183.65` | `+$88.48` | `+$266.92` | `2.87` | `1.06%` | `25` | 2017, 2019 | rejected |
| `ri_m10_r30` | `+$181.36` | `+$104.88` | `+$286.76` | `3.43` | `1.09%` | `22` | 2017, 2019 | rejected |
| `ri_m10_r40` | `+$183.65` | `+$102.75` | `+$281.19` | `3.16` | `1.06%` | `23` | 2017, 2019 | rejected |

The annual restart checks were sparse, but they were used exactly as registered: inactive 2016 was allowed, while active losing years were not. Independent scheduling magnified the control's small 2017 and 2019 losses instead of diversifying them.

## Decision

- Reject independent H1 reversion scheduling at the tested DI/risk neighborhood.
- Do not spend real-tick Model 4 time on a candidate that failed both broad-period improvement and red-year gates.
- Do not inspect 2021-2026 as a rescue set. Those years are already research-observed and would only provide retrospective implementation validation, not untouched out-of-sample evidence.
- Keep `InpBandVWAPReversionIndependentAttempt` default off in the experimental source and do not merge the change into the frozen EA.
- Preserve the frozen three-lane benchmark, its installed binary, and the post-2026-07-12 forward boundary unchanged.

## Evidence

- `outputs/REVERSION_INDEPENDENT_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/REVERSION_INDEPENDENT_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/REVERSION_INDEPENDENT_DISCOVERY_MODEL1_METRICS.md`
- `outputs/REVERSION_INDEPENDENT_DISCOVERY_MODEL1_RUN.csv`
- `outputs/REVERSION_INDEPENDENT_DISCOVERY_DECISION.csv`
