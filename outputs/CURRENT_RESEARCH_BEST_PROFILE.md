# Current Research Best Profile

Last updated: 2026-07-14 UTC.

## Profile

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Status: current research best, not live-ready.

There is no newly validated better profile yet. The latest FMLR and conservative trade-ready work is prepared for testing, but it has not produced validated broad-window MT5 evidence that beats this profile.

## Why This Is Still The Best

LowATR OrderFlow kept the Dec-ISLP-Off profile and added a smarter low-volatility ISLP guard:

- `InpInSessionLiquidityPullbackMinATR=0.00`
- `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`
- `InpInSessionLiquidityPullbackLowATRThreshold=5.00`

The blunt MinATR5 guard was rejected because it removed an October 2024 loser but also deleted a larger June 2024 winner. LowATR OrderFlow kept the June winner and blocked the October loser.

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

Quarterly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11` | `+3,421.49` | `1` | `-44.64` |
| `islp_lowatr_of` | `11` | `+3,435.65` | `1` | `-30.48` |

## Fresh Continuous Same-Source Check

Return math uses a `$1,000` starting balance and CAGR over `2024.01.01` to `2026.07.12`, about `2.53` years.

| Profile | Model | Window | Net | Total Return | CAGR/yr |
| --- | ---: | --- | ---: | ---: | ---: |
| `islp_lowatr_of` | `4` | `2024.01.01` to `2026.07.12` | `+1,195.69` | `+119.57%` | `+36.51%/yr` |
| `dec_islp_off` | `4` | `2024.01.01` to `2026.07.12` | `+1,195.04` | `+119.50%` | `+36.49%/yr` |

The older `+4,507.51` Dec-ISLP-Off Model4 continuous result equals `+450.75%` total and about `+96.43%/yr` CAGR from a `$1,000` start, but it is now treated as historical/stale until reproduced on the current local source and compact tester path.

## Conservative Trade-Ready Candidate

Current safest test candidate:

`outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`

SHA-256:

`621F54A4BFE61761577D87DB212CF024163F25066209C205090E72227FE584A6`

This candidate does not replace the research-best profile. It is a stricter paper/demo candidate with lower risk, tighter loss caps, one position, `0.01` max lots, and real-account approval disabled.

## Current Gaps

The project remains research-only until these are proven:

- current-source compile proof
- first-pass MT5 report exports
- full conservative validation reports
- broker-proxy reports
- trade-quality logs
- Monte Carlo trade stress
- forward/demo evidence
- second-broker evidence
- reproducible source/profile publication sync

Bottom line: no new best yet; LowATR OrderFlow remains the current promoted research profile.
