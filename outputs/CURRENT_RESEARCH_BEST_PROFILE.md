# Current Research Best Profile

Last updated: 2026-07-12.

## Profile

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Profile file:

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

## Model4 Evidence

Sampled probe:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+271.42` | `1` | `-44.64` |
| `islp_lowatr_of` | `7` | `+316.06` | `0` | `0.00` |

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

Promoted as the current stability-best research profile.

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

- MT5 report export still returns `NO_REPORT`; results are parsed from tester logs.
- Monthly and quarterly tester-stat reruns are complete, but they show a high worst equity drawdown reading of `30.9408%`.
- Hold-time stats still need richer extraction.
- Model1 and Model2 have not yet been rerun on this LowATR OrderFlow candidate.
- Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source and contains the new optional guard.

Adaptive Reverse remains disabled.

## Latest Rejected Probe

Flat-month FSD efficiency relaxation was tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fsd_relaxed_48h` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fsd_relaxed_24h` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |

Decision:

Do not promote. The relaxation did not add active windows, reduce zero-trade windows, or improve net profit.

Research note:

`research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`
