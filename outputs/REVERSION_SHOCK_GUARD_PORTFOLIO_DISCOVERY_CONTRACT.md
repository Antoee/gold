# Reversion Shock-Guard Portfolio Discovery Contract

Frozen on 2026-07-17 before any MT5 report from this source or profile family was run or inspected.

## Purpose

Test whether a simple, date-independent rejection-body confirmation can complement the already validated reversion DI-imbalance gate and repair both weak 2019 and 2020 portfolio outcomes without discarding too many profitable reversion trades.

This is a research fork of Operational Hardening rc2. The reversion and momentum entries, stops, targets, exits, schedules, shared risk manager, account contract, and hard real-account lock are unchanged except for one optional reversion entry gate. It cannot modify the registered forward candidate, registration, source/profile/binary identity, run label, or evidence logs.

## Prior Evidence And Limitation

The exact RC2 Model4 ledger and earlier feature diagnostics are research-seen. DI-only tightening repaired 2020 but could not address the separate 2019 failure, and its nominated `0.20% / DI -10` center missed the frozen pre-2021 PF floor at `1.49` versus `1.50`. An older 41-trade, non-RC2-exact feature study found that rejection-candle body size had an interpretable quality relationship, but no one-factor gate passed all requirements.

This contract therefore asks a new two-feature question on locked pre-2021 data. It is retrospective robustness research, not pristine out-of-sample proof.

## Frozen Identity

- Base RC2 source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Research source: `work/Professional_XAUUSD_Reversion_Shock_Guard_Portfolio.mq5`
- Research source SHA-256: `A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9`
- Compiled binary SHA-256: `7B6386477A6205F77AB91484A585E27B88517B3BE288F700AC911A5B7C8BFABB`
- Compile: `0 errors, 0 warnings`
- Frozen base profile SHA-256: `5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827`
- Starting balance: `$10,000 USD`
- Symbol/timeframe: `XAUUSD M15`
- Reversion risk: `0.45%`
- Momentum risk allocations: `0.15%` and `0.20%`
- Shared open-risk cap: `0.75%`
- Real-account trading: disabled

The new inputs are independently controlled and default off:

- `InpRVUseMinimumBodyGate=false`
- `InpRVMinimumBodyPercent=25.0`

## Frozen Neighborhood

Seven profiles are tested at each momentum-risk allocation:

| Suffix | DI floor | Body gate | Minimum body | Role |
| --- | ---: | --- | ---: | --- |
| `control` | `-12` | off | `25%` | exact behavioral control |
| `di10` | `-10` | off | `25%` | DI-only control |
| `body25` | `-12` | on | `25%` | body-only control |
| `combo20` | `-10` | on | `20%` | lower body neighbor |
| `combo25` | `-10` | on | `25%` | nominated center |
| `combo30` | `-10` | on | `30%` | upper body neighbor |
| `combo25_di08` | `-8` | on | `25%` | stricter-DI neighbor |

No body threshold, DI threshold, risk allocation, or other parameter may be added after results are visible.

## Locked Discovery Data

Model 1 is a fast rejection screen using only:

- `older_2015_2018`: 2015-01-01 through 2018-12-31.
- `repair_2019`: 2019-01-01 through 2019-12-31.
- `repair_2020`: 2020-01-01 through 2020-12-31.
- `continuous_2015_2020`: 2015-01-01 through 2020-12-31.

No configuration containing post-2020 data may run until the complete discovery family gate passes.

## Frozen Discovery Gate

A profile passes its base gate only when all conditions hold:

1. Source, profile, run-label, and report identities match exactly.
2. The 2015-2018 net is positive.
3. Both 2019 and 2020 net are nonnegative and each active-year PF is at least `1.00`.
4. The summed 2019 plus 2020 net is positive.
5. Continuous net and expected payoff are positive, with PF at least `1.50`.
6. Continuous trades are at least `190`.
7. Continuous relative equity drawdown is at most `3.00%`.
8. Continuous return percentage divided by drawdown percentage is at least `2.00`.

The family advances only if both `combo25` centers pass and, at each momentum-risk allocation, at least one body-threshold neighbor (`combo20` or `combo30`) also passes. A lone center, one risk allocation, body-only row, DI-only row, or isolated stricter-DI result is rejected.

## Holdout And Model 4 Policy

Only exact discovery survivors may run Model 1 on 2021-2023, 2024-2026 YTD, and continuous 2015-2026 YTD. Both later eras must be profitable, full PF must be at least `1.50`, full trades at least `330`, full drawdown at most `3.75%`, and the center must remain supported at both risk allocations.

Only passing centers and their frozen supporting neighbors may enter Model 4. Model 4 must include continuous and broad restarts, every calendar-year restart, exact trade-ledger comparison, deterministic moderate/severe cost stress, and the same seeded standard/severe Monte Carlo scenarios used by the RC2 money-readiness audit.

A historical promotion requires at least `95%` of the current `+$1,812.42` Model4 net, PF at least `1.50`, at least `330` trades, drawdown at most `3.25%`, recovery at least `5.0`, every annual-restart gate passing, both cost gates passing, and both Monte Carlo gates passing. Passing history still cannot authorize real-money trading; a correctly capitalized frozen forward demo and second-broker validation remain mandatory.
