# Independent H1 Previous-Week Break-And-Retest Decision

Decision date: 2026-07-16

**Verdict: rejected during Model 1 discovery. No 2021-2026 retrospective run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

This standalone strategy records an H1 close beyond the prior W1 high or low, then requires a later bounded retest and reclaim before entry. The fourteen-variant neighborhood changes breakout quality, setup lifetime, retest depth, volume, trend/ADX, session timing, and payoff without calendar fitting.

- Source: `work/Independent_XAUUSD_H1_PrevWeek_Break_Retest.mq5`
- Source SHA-256: `1A5799C5829D0E7108F60CBB331EB98BE39DACD0422C592020B6973C17147F26`
- Compile: `0 errors, 0 warnings`
- Source/profile input contract: `77` inputs matched
- Discovery data only: 2015-01-01 through 2020-12-31
- Clean reports returned and parsed: `42 / 42`
- Candidate variants: `14`
- Risk per trade: `0.10%`
- 2021-2026 retrospective configurations run: `0`
- Model 4 configurations run: `0`

## Discovery Evidence

Every tested variant lost money in 2015-2018 and every continuous 2015-2020 row was negative. No continuous profit factor reached 1.00, so the family failed before sample-size or drawdown could rescue it.

| Candidate | 2015-2018 | 2019-2020 | Continuous 2015-2020 | PF | Max DD | Trades | Win rate | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `pwbr_adx18` | `-$57.20` | `+$33.05` | `-$24.15` | `0.81` | `0.73%` | `24` | `37.50%` | rejected |
| `pwbr_volume_both` | `-$33.75` | `+$0.00` | `-$33.75` | `0.00` | `0.43%` | `4` | `0.00%` | rejected |
| `pwbr_retest_tight` | `-$54.73` | `+$19.63` | `-$35.10` | `0.36` | `0.69%` | `8` | `25.00%` | rejected |
| `pwbr_retest_loose` | `-$54.15` | `+$17.80` | `-$36.35` | `0.87` | `1.56%` | `59` | `42.37%` | rejected |
| `pwbr_break_strict` | `-$64.10` | `+$19.21` | `-$44.89` | `0.63` | `0.88%` | `21` | `33.33%` | rejected |
| `pwbr_rr25` | `-$87.07` | `+$31.19` | `-$55.88` | `0.68` | `1.15%` | `30` | `33.33%` | rejected |
| `pwbr_age12` | `-$92.77` | `+$33.05` | `-$59.72` | `0.68` | `1.07%` | `32` | `34.38%` | rejected |
| `pwbr_age4` | `-$83.57` | `+$23.10` | `-$60.47` | `0.59` | `1.07%` | `25` | `32.00%` | rejected |
| `pwbr_base` | `-$101.04` | `+$33.05` | `-$67.99` | `0.61` | `1.24%` | `30` | `33.33%` | rejected |
| `pwbr_rr15` | `-$101.38` | `+$32.41` | `-$68.97` | `0.60` | `1.17%` | `30` | `33.33%` | rejected |
| `pwbr_buffer15` | `-$91.38` | `+$21.75` | `-$69.63` | `0.58` | `1.15%` | `28` | `32.14%` | rejected |
| `pwbr_break_loose` | `-$115.53` | `+$34.21` | `-$81.32` | `0.63` | `1.31%` | `37` | `32.43%` | rejected |
| `pwbr_no_trend` | `-$111.19` | `+$24.73` | `-$86.46` | `0.59` | `1.25%` | `35` | `31.43%` | rejected |
| `pwbr_session_off` | `-$103.79` | `+$15.19` | `-$88.60` | `0.65` | `1.24%` | `42` | `30.95%` | rejected |

The least-bad continuous row was `pwbr_adx18` at `-$24.15`, PF `0.81`, and only `24` trades. It still lost `-$57.20` in the older era. Broad/strict shapes, age, retest depth, volume, trend, session, and payoff variants all failed, so there is no stable neighborhood to escalate.

## Decision

- Reject H1 previous-week break-and-retest continuation at the tested structure/risk neighborhood.
- Do not use 2021-2026 to rescue a family that failed discovery.
- Skip Model 4 because every continuous Model 1 candidate lost money.
- Do not merge this standalone engine into the frozen EA.
- Preserve the frozen three-lane benchmark, exact installed binary, and forward boundary unchanged.

## Evidence

- `outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_METRICS.md`
- `outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_DECISION.csv`
