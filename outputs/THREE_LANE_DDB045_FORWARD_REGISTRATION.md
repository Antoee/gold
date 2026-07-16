# Three-Lane DDB 0.45 Forward Registration

Date: 2026-07-16

Status: **REGISTERED / INSUFFICIENT EVIDENCE. NOT MONEY-READY.**

## Frozen boundary

- Strategy-selection data ends: `2026-07-12`
- Forward evaluation starts: `2026-07-13`
- EA source SHA-256: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- Profile SHA-256: `2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312`
- Starting balance: `$10,000`
- Primary feed: `MetaQuotes-Demo`; this does not satisfy the second-broker gate

No source, profile, or decision threshold may be changed inside this evaluation stream. A changed source or profile starts a new registration rather than rewriting this one.

## First checkpoint

| Window | Tick quality | Bars | Ticks | Net | Trades | Max DD | Evidence status |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `2026-07-13` through `2026-07-16` | `100%` real ticks | `264` | `1,797,592` | `$0.00` | `0` | `0.00%` | **INSUFFICIENT** |

The valid Model4 report returned from MetaQuotes-Demo Build 5989. Zero trades provide no estimate of profit factor, expectancy, execution quality, or future drawdown. This checkpoint only proves that the frozen evaluation clock has started.

- Compact parsed result: `outputs/THREE_LANE_DDB045_POSTFREEZE_MODEL4_RESULTS.csv`
- Append-only checkpoint table: `outputs/THREE_LANE_DDB045_FORWARD_CHECKPOINTS.csv`
- Exact exported report: `outputs/three_lane_ddb045_postfreeze_evidence/three_lane_ddb045_postfreeze_20260713_20260716_model4.htm`
- Returned report SHA-256: `A7F05C85CFC1071F33099E4230A78B16B8749265EFFC67AC5B6E9BC1708EE674`

## Forward gate

Do not classify this stream as passed until all of the following are available:

1. At least `90` unseen calendar days.
2. At least `20` closed trades.
3. Positive net profit and expected payoff.
4. Profit factor at least `1.20`.
5. Maximum equity drawdown no more than `3.00%`.
6. No more than `4` consecutive losses.
7. No source/profile changes during the measured stream.
8. Separate actual second-broker evidence; same-broker proxies do not count.

Monthly cumulative checkpoints may be appended without tuning. A zero-trade checkpoint advances calendar time but does not advance the trade-sample gate.
