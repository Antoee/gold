# Trend-Liquidity Reclaim Discovery Contract

Frozen on 2026-07-17 before any MT5 performance report from this source or profile family was run or inspected.

## Purpose

Test a clean, independent session return stream inspired by the strongest mechanism in the earlier session research without importing its monolithic source, month-risk multipliers, month-specific exits, date blocks, or large tuned input surface.

The engine trades only a fresh M15 sweep and close back through a rolling liquidity extreme when the completed H1 EMA-200 level and slope agree with the trade, H1/M15 trend strength is sufficient, and the rejection candle has directional body and close-location confirmation. It uses a structure stop beyond the sweep, a fixed `2.0R` target, broker-native `OrderCalcProfit` sizing, and no more than one entry per day.

## Frozen Identity

- Source: `work/Independent_XAUUSD_M15_Trend_Liquidity_Reclaim.mq5`
- Source SHA-256: `67167ACC0BFEA04357EE17195C30320342DEE0D566F2C94E01CC1BF521F26002`
- Compiled binary SHA-256: `4C994BED00F214361978D7585B4813FE22DCD0AEA4646235D049F91DBEC8226B`
- Compile: `0 errors, 0 warnings`
- Starting balance: `$10,000 USD`
- Symbol/timeframe: `XAUUSD M15`
- Risk per trade: `0.10%`
- Entry session: `09:00-11:00` broker time
- Maximum simultaneous managed positions: `1`
- Maximum entries per day: `1`
- Real-account trading: disabled

## Frozen Neighborhood

All rows keep EMA-200 trend alignment, four-H1-bar EMA slope, minimum ADX `20`, minimum sweep `0.05 ATR` and `20` points, maximum sweep `0.75 ATR`, minimum reclaim `0.02 ATR`, minimum wick/body `0.50`, close location `0.60`, stop buffer `0.18 ATR`, and target `2.0R`.

| Profile | Liquidity lookback | Minimum body | Post-loss quarantine | Role |
| --- | ---: | ---: | ---: | --- |
| `tlr_control_q0` | 12 bars | 20% | off | behavioral control |
| `tlr_center_q14` | 12 bars | 20% | 14 days | nominated center |
| `tlr_q07` | 12 bars | 20% | 7 days | quarantine neighbor |
| `tlr_q21` | 12 bars | 20% | 21 days | quarantine neighbor |
| `tlr_body30` | 12 bars | 30% | 14 days | candle-quality neighbor |
| `tlr_lookback08` | 8 bars | 20% | 14 days | shorter-structure neighbor |
| `tlr_lookback20` | 20 bars | 20% | 14 days | longer-structure neighbor |

No threshold, session, stop, target, direction, risk, or filter may be added after results become visible.

## Locked Discovery Data

Model 1 is a fast rejection screen using only:

- `older_2015_2018`: 2015-01-01 through 2018-12-31.
- `repair_2019`: 2019-01-01 through 2019-12-31.
- `repair_2020`: 2020-01-01 through 2020-12-31.
- `continuous_2015_2020`: 2015-01-01 through 2020-12-31.

No configuration containing post-2020 data may run until the complete discovery family gate passes.

## Frozen Discovery Gate

A profile passes only when all conditions hold:

1. Source, profile, run-label, and report identities match exactly.
2. The 2015-2018 net is positive with PF at least `1.05`.
3. Both 2019 and 2020 net are nonnegative, and each active-year PF is at least `1.00`.
4. Continuous net and expected payoff are positive, with PF at least `1.25`.
5. Continuous trades are at least `60`.
6. Continuous relative equity drawdown is at most `2.00%`.
7. Continuous return percentage divided by drawdown percentage is at least `1.50`.

The family advances only if the nominated 14-day center passes, at least one 7/21-day quarantine neighbor passes, and at least one body/lookback structural neighbor passes. The control or a lone isolated row cannot open recent data.

## Holdout And Model 4 Policy

Only exact discovery survivors may run Model 1 on 2021-2023, 2024-2026 YTD, and continuous 2015-2026 YTD. Both later eras must be profitable; full PF must be at least `1.30`, full trades at least `110`, full drawdown at most `2.50%`, and the center must retain both quarantine and structural-neighbor support.

Only that frozen supported family may enter Model 4. Model 4 must include continuous and broad restarts, calendar-year restarts, deterministic moderate/severe added-cost stress, and the same seeded standard/severe Monte Carlo assumptions used by the RC2 money-readiness audit.

Historical success cannot authorize real-money trading. The frozen `$10,000` forward demo contract, minimum forward sample, second-broker validation, and real-account hard lock remain mandatory and unchanged.
