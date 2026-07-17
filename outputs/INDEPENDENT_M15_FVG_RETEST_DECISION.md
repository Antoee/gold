# Independent M15 FVG Retest Decision

Decision date: 2026-07-16

**Verdict: rejected during discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Strategy Contract

The standalone strategy looked for an M15 break of structure with a displacement candle that created a classic three-candle fair value gap. It deferred entry until a later touch-and-hold retest, used an optional H1 EMA regime filter, placed the stop behind the gap or retest structure, enforced a hard `$10` maximum stop-price distance, and used broker-native `OrderCalcProfit` sizing at `0.10%` risk on `$10,000`. It never forces the broker minimum lot.

- Source: `work/Independent_XAUUSD_M15_FVG_Retest.mq5`
- Source SHA-256: `E46DB3A2E01435B83D68349BB1F40CA279723813FD34DBBD81D7A9CAFFE6751C`
- Compile: `0 errors, 0 warnings`
- Discovery only: 2015-01-01 through 2020-12-31
- Discovery configurations: `30 / 30` full reports
- Candidate shapes: `10`
- Recent holdout configurations generated or run: `0`
- Model 4 configurations run: `0`

## Discovery Evidence

Every neighboring variant lost in both disjoint discovery eras. The continuous runs ranged from `-$477.65` to `-$507.19`, with PF from `0.24` to `0.59` and `102-196` trades. All continuous curves reached approximately the predeclared `5%` drawdown review lock.

| Candidate | 2015-2018 | PF | Trades | 2019-2020 | PF | Trades | Continuous 2015-2020 | PF | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `m15fvg_b20_tp15` | `-$477.65` | `0.35` | `111` | `-$251.81` | `0.78` | `225` | `-$477.65` | `0.35` | `111` | `5.03%` |
| `m15fvg_b20_a4_tp20` | `-$482.21` | `0.45` | `142` | `-$158.92` | `0.83` | `180` | `-$482.21` | `0.45` | `142` | `5.00%` |
| `m15fvg_b20_hold75` | `-$482.98` | `0.30` | `102` | `-$209.83` | `0.81` | `210` | `-$482.98` | `0.30` | `102` | `5.02%` |
| `m15fvg_b20_gap10` | `-$483.65` | `0.28` | `103` | `-$205.73` | `0.81` | `211` | `-$483.65` | `0.28` | `103` | `5.02%` |
| `m15fvg_b32_a8_tp20` | `-$486.94` | `0.59` | `196` | `-$176.30` | `0.81` | `178` | `-$486.94` | `0.59` | `196` | `5.06%` |
| `m15fvg_b12_a8_tp20` | `-$487.74` | `0.38` | `122` | `-$28.72` | `0.98` | `248` | `-$487.74` | `0.38` | `122` | `5.06%` |
| `m15fvg_b20_a8_tp20` | `-$488.39` | `0.30` | `107` | `-$265.95` | `0.76` | `216` | `-$488.39` | `0.30` | `107` | `5.07%` |
| `m15fvg_b20_a12_tp20` | `-$489.19` | `0.32` | `112` | `-$208.85` | `0.82` | `228` | `-$489.19` | `0.32` | `112` | `5.08%` |
| `m15fvg_b20_imp15` | `-$490.16` | `0.56` | `187` | `-$426.90` | `0.57` | `186` | `-$490.16` | `0.56` | `187` | `5.09%` |
| `m15fvg_b20_tp25` | `-$507.19` | `0.24` | `102` | `-$278.76` | `0.75` | `218` | `-$507.19` | `0.24` | `102` | `5.30%` |

Some later disjoint-era runs contain more trades than their corresponding continuous run because the continuous account reached its drawdown lock during 2015-2018. This is expected and reinforces the rejection; it is not missing-report evidence.

## Decision

- Reject all ten variants and the current BOS/displacement/FVG-retest hypothesis.
- Do not open the frozen 2021-2026 strategy-specific holdout.
- Skip Model 4 because Model 1 discovery failed profit, PF, drawdown, and both-era consistency.
- Do not rescue the family by tuning its thresholds against the failed discovery rows.
- Retain the source and reports as negative research evidence.
- Require the next family to change the economic hypothesis rather than rename or lightly filter this entry pattern.
- Keep the frozen three-lane benchmark and its post-2026-07-12 forward registration unchanged.

## Evidence

- `outputs/INDEPENDENT_M15_FVG_RETEST_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_FVG_RETEST_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/INDEPENDENT_M15_FVG_RETEST_DISCOVERY_MODEL1_METRICS.md`
- `outputs/INDEPENDENT_M15_FVG_RETEST_DECISION.csv`
