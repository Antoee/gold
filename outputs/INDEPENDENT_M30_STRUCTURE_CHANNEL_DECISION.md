# Independent M30 Structure-Channel Decision

Decision date: 2026-07-16

**Verdict: rejected after the frozen strategy-specific holdout. No new best was promoted, Model 4 was skipped, and real-account trading remains disabled.**

## Strategy Contract

The standalone strategy used M30 fresh channel breakouts, an optional H4 EMA regime filter, a recent-swing stop with an ATR floor/buffer, a hard `$10` maximum stop-price distance, and broker-native `OrderCalcProfit` sizing at `0.10%` risk on `$10,000`. It never forces the broker minimum lot.

- Source: `work/Independent_XAUUSD_M30_Structure_Channel.mq5`
- Source SHA-256: `4A524A8C6565B669FE9D68E84B4EE9B8C2AEAB49E0A7173FE6750A930B4594BB`
- Compile: `0 errors, 0 warnings`
- Discovery: 2015-01-01 through 2020-12-31
- Frozen holdout: 2021-01-01 through 2026-07-12
- Discovery configurations: `30 / 30` full reports
- Holdout configurations: `36 / 36` full reports

## Discovery Evidence

Six neighboring variants were positive in both disjoint discovery eras. Four distinct shapes were frozen before any strategy-specific holdout result was generated:

| Frozen candidate | 2015-2020 net | PF | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: |
| `m30sc_72_36_tp20` | `+$547.52` | `1.49` | `239` | `2.34%` |
| `m30sc_48_24_channel` | `+$379.99` | `1.29` | `289` | `2.62%` |
| `m30sc_48_24_tp25` | `+$374.64` | `1.28` | `291` | `2.62%` |
| `m30sc_48_24_stop5` | `+$306.61` | `1.32` | `226` | `1.69%` |

This was a real active plateau, not a one-trade or minimum-lot artifact.

## Frozen Holdout

Every candidate failed the requirement that both broad holdout eras and the continuous holdout remain positive:

| Candidate | 2021-2023 | PF | Trades | 2024-2026 YTD | PF | Trades | Continuous 2021-2026 | PF | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `m30sc_72_36_tp20` | `-$296.23` | `0.60` | `153` | `+$160.76` | `1.44` | `94` | `-$144.49` | `0.87` | `247` | `4.45%` |
| `m30sc_48_24_channel` | `-$231.05` | `0.71` | `175` | `+$2.95` | `1.01` | `101` | `-$217.49` | `0.81` | `274` | `5.06%` |
| `m30sc_48_24_tp25` | `-$227.51` | `0.71` | `176` | `+$26.66` | `1.07` | `102` | `-$185.28` | `0.84` | `276` | `4.87%` |
| `m30sc_48_24_stop5` | `-$119.00` | `0.79` | `137` | `+$53.08` | `1.21` | `60` | `-$64.28` | `0.92` | `197` | `2.95%` |

The family was active enough to make the failure meaningful. The entire 2021-2023 broad era lost for every profile. All four also lost continuously through July 2026, with PF below `1.0`.

The positive 2025 and mostly positive 2024-2026 aggregate cannot be used to add a date filter or retune the profiles. Those years are now inspected holdout data. Doing so would turn a failed frozen test into a fitted recent-regime strategy.

## Decision

- Reject all four frozen candidates and the current M30 structure-channel family.
- Skip Model 4 because the faster holdout failed on profit, PF, and broad-era consistency.
- Do not tune channel lengths, exits, or date filters against 2021-2026.
- Retain the source and results as evidence that the capital-feasibility problem was solved but the trading edge did not generalize.
- Require the next independent family to change the economic hypothesis, not merely adjust this family's thresholds.
- Keep the frozen three-lane benchmark and its post-2026-07-12 forward registration unchanged.

## Evidence

- `outputs/INDEPENDENT_M30_STRUCTURE_CHANNEL_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_REGISTRATION.md`
- `outputs/INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M30_STRUCTURE_CHANNEL_DECISION.csv`

