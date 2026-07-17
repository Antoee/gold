# Independent H4 Channel-Trend Decision

Decision date: 2026-07-16

**Verdict: rejected after the frozen strategy-specific holdout. No new best was promoted, Model 4 was not opened, and real-account trading remains disabled.**

## What Was Tested

A standalone H4 Donchian channel-breakout EA was implemented with broker-accurate `OrderCalcProfit` sizing, a `0.10%` risk budget, a two-ATR initial stop, Chandelier trailing, account-wide exposure control, daily/equity loss locks, and no martingale, grid, averaging down, or recovery sizing.

- Source: `work/Independent_XAUUSD_H4_Channel_Trend.mq5`
- Source SHA-256: `C27025A3605EEBBA54C5B88D564CE641D00634E2C42C8BAC6D127751ABF58F4A`
- Compile result: `0 errors, 0 warnings`
- Discovery data: 2015-01-01 through 2020-12-31
- Frozen holdout: 2021-01-01 through 2026-07-12
- Starting balance: `$10,000`

The 2015-2020 Model 1 discovery neighborhood looked promising. Seven of eight trailing variants were positive in both discovery eras. The four candidates frozen before holdout inspection produced the following continuous discovery results:

| Candidate | 2015-2020 net | PF | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: |
| `h4ct_trail_40_20_l20_a25` | `+$268.97` | `1.73` | `101` | `0.89%` |
| `h4ct_trail_55_20_l20_a25` | `+$264.96` | `1.94` | `81` | `0.70%` |
| `h4ct_trail_55_20_l20_a30` | `+$328.77` | `2.12` | `76` | `0.76%` |
| `h4ct_trail_80_40_l20_a30` | `+$314.57` | `2.54` | `61` | `0.62%` |

## Frozen Holdout Result

All `36 / 36` full Model 1 reports completed. Every candidate failed the predeclared minimum-activity gate:

| Candidate | 2021-2023 | Trades | 2024-2026 YTD | Trades | Continuous holdout | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `h4ct_trail_40_20_l20_a25` | `+$23.95` | `1` | `$0.00` | `0` | `+$23.95` | `1` | `0.16%` |
| `h4ct_trail_55_20_l20_a25` | `+$26.84` | `1` | `$0.00` | `0` | `+$26.84` | `1` | `0.16%` |
| `h4ct_trail_55_20_l20_a30` | `+$23.67` | `1` | `$0.00` | `0` | `+$23.67` | `1` | `0.19%` |
| `h4ct_trail_80_40_l20_a30` | `+$23.67` | `1` | `$0.00` | `0` | `+$23.67` | `1` | `0.19%` |

There were zero trades in 2021, 2022, 2024, 2025, and 2026 YTD. The only holdout trade occurred in 2023. A one-trade result cannot establish profitability, profit factor, regime coverage, or future reliability. The required continuous holdout minimum was 40 trades.

## Broker-Native Sizing Diagnosis

The EA deliberately returns zero volume when the risk-sized order is below the broker's `0.01`-lot minimum. At `0.10%` risk on `$10,000`, the risk budget is only `$10`.

A subsequent no-trading diagnostic reproduced the 40, 55, and 80-bar breakout signals and called the broker's own `OrderCalcProfit` function for each two-ATR stop. It confirmed that this risk/account contract is structurally infeasible for the strategy:

| Lookback | All eligible signals | Feasible at `$10,000 / 0.10%` | 2021+ signals | 2021+ feasible | Latest required equity min / median / p95 |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 40 | `970` | `19.69%` | `477` | `0.42%` | `$64,280 / $87,310 / $137,848` in 2026 |
| 55 | `815` | `19.63%` | `394` | `0.76%` | `$19,770 / $39,630 / $73,921.50` in 2025 |
| 80 | `687` | `18.49%` | `348` | `0.86%` | `$64,280 / $87,310 / $123,672` in 2026 |

The diagnostic had zero `OrderCalcProfit` failures and placed zero orders. It measures sizing feasibility only; it does not reopen the consumed holdout or promote strategy performance.

That behavior is correct. Forcing `0.01` lot would exceed the declared risk budget and would make the backtest look active by weakening risk management. Raising risk or capital after inspecting holdout activity would also create a new, holdout-informed experiment rather than rescue the frozen result.

## Decision

- Reject all four frozen H4 channel-trend candidates.
- Do not spend Model 4 time on a family that failed the faster holdout activity gate.
- Do not force the broker minimum lot, widen the risk limit, or tune channel/trailing parameters against 2021-2026.
- Retain the source and results as capital-feasibility research only, not as a current candidate.
- Add a pre-test minimum-tradable-risk diagnostic so future wide-stop strategies are screened before expensive validation.
- Prefer the next independent strategy family to use tighter, structure-defined stops that can honor the target account and risk budget under current XAUUSD conditions.

The frozen three-lane profile remains the project benchmark. Its post-2026-07-12 forward registration is unchanged.

## Evidence

- `outputs/INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_REGISTRATION.md`
- `outputs/INDEPENDENT_H4_CHANNEL_TREND_TRAIL_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_H4_CHANNEL_TREND_DECISION.csv`
- `outputs/XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY.csv`
- `outputs/XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_GATE.md`
