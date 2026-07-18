# Independent M15 Asian-Range Sweep Discovery Contract

Frozen on 2026-07-17 before any MT5 report from this source or profile family was run or inspected.

## Purpose

Test a genuinely separate XAUUSD return source: a fresh M15 liquidity sweep beyond the completed 00:00-06:00 broker-time range, followed by a directional close back inside the range during 06:00-12:00. The hypothesis is that session-transition false breaks can add activity that is not dependent on the RC2 Band/VWAP reversion or multiscale momentum entries.

This is a research-only lane. It cannot modify the registered forward candidate, account contract, source/profile/binary identity, run label, evidence logs, or real-account lock.

## Frozen Identity

- Source: `work/Independent_XAUUSD_M15_Asian_Range_Sweep.mq5`
- Source SHA-256: `C757E57C98EFABE7C9A84EEE912D181539AF346DCDCD0B6758F9F0AE22C71EFB`
- Compiled binary SHA-256: `FFFE1D0EB792FFDF16F32B976DD58D298E818CF5ACDD26DE1348D7B7C5354B01`
- Compile: `0 errors, 0 warnings`
- Starting balance: `$10,000 USD`
- Symbol/timeframe: `XAUUSD M15`
- Requested risk: `0.10%` per trade
- Maximum trades per day: `1`
- Maximum research equity drawdown: `5.00%`
- Real-account trading: disabled

The EA uses broker-native `OrderCalcProfit` sizing, never forces the broker minimum lot, allows only one managed position, checks account-wide protected exposure, and places a structure stop beyond the sweep candle.

## Frozen Neighborhood

The center uses a `0.10 ATR` minimum sweep, no additional reclaim distance, wick/body ratio `1.00`, fixed `1.50R` target, no volume or ADX filter, and entries through 12:00. Nine one-factor neighbors test sweep depth, reclaim depth, wick shape, tick volume, maximum ADX, payoff, midpoint target, and an earlier session close.

| Profile | One change from center |
| --- | --- |
| `ars_center` | none |
| `ars_sweep05` | minimum sweep `0.05 ATR` |
| `ars_sweep15` | minimum sweep `0.15 ATR` |
| `ars_reclaim05` | close at least `0.05 ATR` back inside |
| `ars_wick15` | wick/body at least `1.50` |
| `ars_volume105` | tick volume at least `1.05x` lookback mean |
| `ars_adx24` | M15 ADX at most `24` |
| `ars_rr20` | fixed target `2.00R` |
| `ars_midpoint` | target Asian-range midpoint, minimum `1.00R` |
| `ars_entry10` | entry window ends at 10:00 |

No profile, threshold, or session may be added after results are visible.

## Locked Discovery Data

Model 1 is a fast rejection screen using only:

- `older_2015_2018`: 2015-01-01 through 2018-12-31.
- `repair_2019_2020`: 2019-01-01 through 2020-12-31.
- `continuous_2015_2020`: 2015-01-01 through 2020-12-31.

No configuration containing data after 2020 may run until the entire discovery family gate passes.

## Frozen Discovery Gate

A profile passes its base gate only when all conditions hold:

1. Source, profile, run-label, and report identities match exactly.
2. Both disjoint era nets are positive and each active-era PF is at least `1.05`.
3. Continuous net and expected payoff are positive.
4. Continuous PF is at least `1.20`.
5. Continuous trades are at least `100`.
6. Continuous relative equity drawdown is at most `3.00%`.
7. Continuous return percentage divided by drawdown percentage is at least `1.00`.

The family advances only if `ars_center` passes and at least two one-factor neighbors also pass. An isolated parameter row is rejected.

## Holdout And Model 4 Policy

Only exact discovery survivors may run Model 1 on 2021-2023, 2024-2026 YTD, and continuous 2015-2026 YTD. Both later eras must be profitable with active PF at least `1.05`; full PF must be at least `1.20`, full trades at least `200`, and full drawdown at most `3.50%`. The center must remain supported by at least two frozen neighbors.

Only a passing center and its supporting neighbors may enter Model 4. Model 4 must reproduce positive net in 2015-2018, 2019-2022, and 2023-2026 YTD, continuous PF at least `1.20`, at least `180` trades, drawdown at most `4.00%`, positive deterministic cost stress, and acceptable seeded Monte Carlo tails.

Before any portfolio integration, exact trade streams must show that adding this lane to RC2 improves risk-adjusted performance, does not create duplicate exposure, does not worsen the weak annual sequence, and remains under the shared `0.75%` open-risk cap. Passing historical evidence still cannot authorize real-money trading; a valid frozen forward demo and second-broker test remain mandatory.
