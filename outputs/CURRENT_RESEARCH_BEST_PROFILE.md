# Current Research Best Profile

Last updated: 2026-07-12.

## Profile

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Classification:

`Provisional stability-best research profile, not live-ready`

Local generated profile file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

Research note:

`research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

Stats export note:

`research/2026-07-12-lowatr-tester-stats-export-note.md`

Latest stats summaries:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`

## Change

The current best keeps the Dec-ISLP-Off profile and adds a smarter low-volatility ISLP guard:

- `InpInSessionLiquidityPullbackMinATR=0.00`
- `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`
- `InpInSessionLiquidityPullbackLowATRThreshold=5.00`

Meaning:

Low-ATR ISLP trades are still allowed, but only when order flow confirms.

## Why It Replaced Dec-ISLP-Off

The blunt MinATR5 guard was rejected because it removed the October 2024 loser but also deleted a larger June 2024 winner.

The LowATR OrderFlow guard fixed that tradeoff:

- It kept the June 2024 low-ATR ISLP winner because order flow confirmed.
- It blocked the October 2024 low-ATR ISLP loser because order flow did not confirm.

## Provisional Caution

The Dec-ISLP-Off component remains an overfit risk because the original December improvement came from a very small number of December observations. Keep it as a risk-control candidate, not a proven permanent market rule.

The LowATR OrderFlow addition is stronger than the blunt MinATR filter because it preserved a known winner while removing a known loser, but it still needs wider out-of-sample validation.

The new tester-stat reruns add important risk context: both monthly and quarterly summaries show a `30.9408%` worst equity drawdown reading. That is too high to treat this as live-ready.

## Model4 Evidence

Sampled probe:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+271.42` | `1` | `-44.64` |
| `islp_lowatr_of` | `7` | `+316.06` | `0` | `0.00` |

Tester-stat probe smoke:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7 / 7` | `+271.42` | `12` | `7.3344` | `1` |
| `islp_lowatr_of` | `7 / 7` | `+316.06` | `11` | `7.3344` | `0` |

Monthly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31` | `+3,637.53` | `1` | `-44.64` |
| `islp_lowatr_of` | `31` | `+3,682.17` | `0` | `0.00` |

Monthly tester-stat rerun:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Nonzero PF Samples | Min Nonzero PF |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31 / 31` | `+3,637.53` | `39` | `30.9408` | `7` | `1.4914` |
| `islp_lowatr_of` | `31 / 31` | `+3,682.17` | `38` | `30.9408` | `7` | `1.4914` |

Quarterly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11` | `+3,421.49` | `1` | `-44.64` |
| `islp_lowatr_of` | `11` | `+3,435.65` | `1` | `-30.48` |

Quarterly tester-stat rerun:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Min Recovery Factor | Avg Sharpe |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11 / 11` | `+3,421.49` | `34` | `30.9408` | `-0.9789` | `3.2935` |
| `islp_lowatr_of` | `11 / 11` | `+3,435.65` | `34` | `30.9408` | `-0.5184` | `3.2828` |

Decision:

Promoted as the current stability-best research profile, but only provisionally.

## Evidence Files

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`
- `research/2026-07-12-lowatr-tester-stats-export-note.md`

## Caveats

This is not a live-ready production profile.

Remaining gaps:

- Monthly and quarterly tester-stat reruns are complete, but they show a high worst equity drawdown reading of `30.9408%`.
- Model1 and Model2 have not yet been rerun on this LowATR OrderFlow candidate.
- Older-data, walk-forward, Monte Carlo, and broker-variation testing are still missing.
- Hold-time, average winner/loser, largest loss, consecutive loss, exposure, spread, swap, commission, and slippage evidence are still incomplete.
- Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source and contains the new optional guard.

Adaptive Reverse remains disabled.
