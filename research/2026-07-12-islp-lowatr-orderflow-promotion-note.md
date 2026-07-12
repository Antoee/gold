# ISLP Low-ATR Order-Flow Promotion Note

Date: 2026-07-12

## Purpose

Promote the strongest stability candidate found after diagnosing the weak October 2024 ISLP trade.

The blunt ISLP MinATR5 filter removed the October 2024 loss, but it also removed a larger June 2024 winner. The better discriminator was not raw ATR alone:

- June 2024 winner: low ATR, but `ISLP order flow` confirmed.
- October 2024 loser: low ATR, no `ISLP order flow` confirmation.

## Change

Added optional ISLP guard:

- `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`
- `InpInSessionLiquidityPullbackLowATRThreshold=5.00`
- `InpInSessionLiquidityPullbackMinATR=0.00`

Interpretation:

Low-ATR ISLP trades are still allowed, but only when order flow confirms. This preserves the June 2024 winner while blocking the October 2024 loser.

## Candidate

Profile:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

## Evidence

Sampled Model4 probe:

| Profile | Parsed | Total | Losing Windows | Worst | Best |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+271.42` | `1` | `-44.64` | `+107.82` |
| `islp_lowatr_of` | `7` | `+316.06` | `0` | `0.00` | `+107.82` |

Monthly Model4 gate:

| Profile | Parsed | Total | Losing Windows | Worst | Best |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31` | `+3,637.53` | `1` | `-44.64` | `+1,497.84` |
| `islp_lowatr_of` | `31` | `+3,682.17` | `0` | `0.00` | `+1,497.84` |

Quarterly Model4 gate:

| Profile | Parsed | Total | Losing Windows | Worst | Best |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11` | `+3,421.49` | `1` | `-44.64` | `+1,497.84` |
| `islp_lowatr_of` | `11` | `+3,435.65` | `1` | `-30.48` | `+1,497.84` |

Quarterly caveat:

The new profile improves the worst quarter from `-44.64` to `-30.48`, but it does not fully eliminate the weak Q4 2024 quarter.

## Decision

Promote as the current stability-best research profile.

Reason:

- Sampled Model4 gate improved profit and removed the losing sampled window.
- Monthly Model4 gate improved profit and removed the losing month.
- Quarterly Model4 gate improved profit and improved worst quarter.
- No tested window was made worse.

Still not live-ready:

- Full report export is still failing with `NO_REPORT`.
- Drawdown, profit factor, trade count, and hold-time stats still need richer extraction.
- Model1 and Model2 have not yet been rerun on the LowATR OrderFlow candidate.

Current classification:

`Stability-best research profile, not production/live-ready`
