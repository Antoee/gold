# RC2 DI-Repair Portfolio Discovery Contract

Frozen on 2026-07-17 before any new MT5 report for this experiment was run or inspected.

## Purpose

Test whether the already implemented and independently validated reversion directional-imbalance gate can repair the RC2 portfolio's weak 2019-2020 sequence without sacrificing its broad-history profitability or worsening tail risk.

This is a separate research lane. It cannot modify the registered forward candidate, forward registration, source/profile/binary identity, run label, evidence logs, account contract, or real-account lock.

## Prior Evidence And Limitation

The continuous RC2 Model4 ledger is research-seen. Diagnostic segmentation shows that 2020 weakness came mainly from the reversion lane, while a prior standalone reversion study found that tightening the directional-imbalance threshold from `-12` to `-10` changed 2020 from negative to positive. That prior study rejected `-10` as a standalone strategy because other years weakened.

This contract asks a different preregistered question: can the unchanged momentum lane absorb those later-year weaknesses when both lanes are tested as one account portfolio? The result is retrospective robustness evidence, not pristine out-of-sample proof.

## Frozen Identity

- RC2 source: `work/Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5`
- Source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Frozen base profile SHA-256: `5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827`
- Starting balance: `$10,000 USD`
- Symbol/timeframe: `XAUUSD M15`
- Reversion risk: `0.45%`
- Shared open-risk cap: `0.75%`
- Real-account trading: disabled

No entry, stop, target, exit, schedule, or risk-manager code changes are allowed in this screen.

## Frozen Neighborhood

| Profile | Momentum risk | Reversion DI edge | Role |
|---|---:|---:|---|
| `dir_mo015_di12_control` | 0.15% | -12 | forward-risk control |
| `dir_mo015_di10_center` | 0.15% | -10 | repair center |
| `dir_mo015_di08_strict` | 0.15% | -8 | strict neighbor |
| `dir_mo020_di12_control` | 0.20% | -12 | historical-best control |
| `dir_mo020_di10_center` | 0.20% | -10 | primary repair center |
| `dir_mo020_di08_strict` | 0.20% | -8 | strict neighbor |

No threshold or risk allocation may be added after results are visible.

## Locked Discovery Data

Model 1 is a fast rejection screen using only:

- `older_2015_2018`: 2015-01-01 through 2018-12-31.
- `repair_2019`: 2019-01-01 through 2019-12-31.
- `repair_2020`: 2020-01-01 through 2020-12-31.
- `continuous_2015_2020`: 2015-01-01 through 2020-12-31.

No configuration containing data after 2020 may run until the discovery gate passes.

## Frozen Discovery Gate

A profile passes the base gate only if all conditions hold:

1. Source, profile, run-label, and report identities match exactly.
2. The 2015-2018 net is positive.
3. Both 2019 and 2020 net are at least `-$25` and each active-year PF is at least `0.85`.
4. The summed 2019 plus 2020 net is at least `-$25`.
5. Continuous 2015-2020 net is positive, PF is at least `1.50`, and expected payoff is positive.
6. Continuous trades are at least `190`.
7. Continuous relative equity drawdown is at most `3.00%`.
8. Continuous return percentage divided by drawdown percentage is at least `2.00`.

The family advances only if both `DI -10` centers pass at their respective momentum risks and, at each risk level, at least one adjacent threshold (`-12` or `-8`) also passes the base gate. A lone center, a single risk allocation, or an isolated threshold is rejected.

## Holdout And Precision Policy

Only exact discovery survivors may run Model 1 on 2021-2023, 2024-2026 YTD, and continuous 2015-2026 YTD. Both later eras must be profitable; full PF must be at least `1.50`, full trades at least `340`, full DD at most `3.75%`, and neither DI center may be dominated by its same-risk control on both net and drawdown.

Only a passing DI center plus its passing same-risk neighbors may enter Model 4. Model 4 must include continuous, all calendar-year restarts, deterministic cost stress, and the same seeded Monte Carlo scenarios used by the RC2 money-readiness audit.

The primary `0.20% / DI -10` profile may replace the historical research best only if it:

1. retains at least `95%` of the `+$1,812.42` current Model4 net;
2. has PF at least `1.50`, at least `340` trades, DD at most `3.50%`, and recovery at least `5.0`;
3. passes every frozen annual-restart gate from the RC2 money-readiness contract;
4. passes deterministic moderate and severe cost gates;
5. passes both standard and severe Monte Carlo gates;
6. is supported by the `0.15% / DI -10` profile and at least one same-risk DI neighbor.

Passing historical evidence still does not authorize real-money trading. A correctly capitalized forward demo and second-broker validation remain mandatory.
