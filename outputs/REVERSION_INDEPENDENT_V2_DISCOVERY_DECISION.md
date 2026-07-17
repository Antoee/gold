# Corrected Independent H1 Reversion Scheduling Decision

Decision date: 2026-07-16

**Verdict: rejected during corrected Model 1 discovery. No 2021-2026 retrospective implementation run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Why V2 Was Required

The first independent-scheduling implementation raised `InpMaxSimultaneousPositions` from one to two. Trade-level inspection showed that this global change also allowed five additional primary-lane entries, including repeated daily Donchian positions, so V1 did not isolate the intended H1 scheduling hypothesis. Its published rejection remains correct for that implementation, but it is not the final strategy test.

V2 reserves separate one-position slots for the primary strategies and H1 Band/VWAP reversion while retaining the two-position global limit and the existing `0.75%` account-wide open-risk cap.

- Corrected source: `work/Professional_XAUUSD_EA_REVERSION_INDEPENDENT_V2.mq5`
- Corrected source SHA-256: `55E2AA9750880146B07A821CC773C8F4C71F21981F41E03EB4D1121602410363`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Clean configurations returned and parsed: `45 / 45`
- Candidate variants: `4` plus one exact control
- Interrupted lock-race artifacts admitted: `0`
- 2021-2026 retrospective configurations run: `0`
- Model 4 configurations run: `0`

## Isolation Check

The V1 lead contained `15` primary-lane trades versus `12` in control, including five entry times not present in control. The corrected V2 lead contains exactly the same `12` primary entry times as control and adds only six Band/VWAP reversion entries. This proves that the corrected comparison isolates H1 scheduling rather than globally increasing primary-lane capacity.

## Discovery Evidence

All four corrected candidates improved the older 2015-2018 headline, but every one reduced the separate 2019-2020 result and worsened the active losing years 2017 and 2019. The strongest continuous row was `ri2_m10_r30`, but its `$27.25` six-year improvement came with lower PF and materially worse annual restart losses.

| Candidate | 2015-2018 | 2019-2020 | Continuous 2015-2020 | PF | Max DD | Trades | 2017 | 2019 | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `ri2_control` | `+$184.32` | `+$108.33` | `+$252.65` | `4.76` | `0.77%` | `15` | `-$3.29` | `-$3.13` | control confirmed |
| `ri2_m12_r30` | `+$191.47` | `+$92.02` | `+$265.63` | `3.17` | `0.72%` | `23` | `-$17.15` | `-$12.52` | rejected |
| `ri2_m12_r40` | `+$196.33` | `+$88.48` | `+$262.63` | `2.87` | `0.78%` | `23` | `-$24.42` | `-$15.65` | rejected |
| `ri2_m10_r30` | `+$191.47` | `+$104.88` | `+$279.90` | `3.56` | `0.72%` | `21` | `-$17.15` | `-$12.52` | rejected |
| `ri2_m10_r40` | `+$196.33` | `+$102.75` | `+$276.90` | `3.16` | `0.78%` | `21` | `-$24.42` | `-$15.65` | rejected |

The predeclared gates required each candidate broad era to be at least control and no active annual result to be worse than control. Every candidate failed both conditions. The corrected lead passed the numeric PF and drawdown floors but failed cross-era and annual robustness, which take priority over its higher continuous net.

## Decision

- Reject independent H1 Band/VWAP scheduling at the tested DI/risk neighborhood.
- Do not use 2021-2026 to rescue the branch; those years are already research-observed and would not be untouched out-of-sample evidence.
- Skip Model 4 because the clean Model 1 discovery gate failed.
- Keep the scheduling switch default off and do not merge V1 or V2 into the frozen EA.
- Preserve the frozen three-lane benchmark, exact installed binary, and post-2026-07-12 forward boundary unchanged.

## Evidence

- `outputs/REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_METRICS.md`
- `outputs/REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_RUN.csv`
- `outputs/REVERSION_INDEPENDENT_V2_M10_R30_MODEL1_TRADES.csv`
- `outputs/REVERSION_INDEPENDENT_V2_DISCOVERY_DECISION.csv`
