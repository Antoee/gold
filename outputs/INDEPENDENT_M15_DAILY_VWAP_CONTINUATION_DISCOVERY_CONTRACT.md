# Independent M15 Daily-VWAP Continuation Discovery Contract

Frozen before any discovery result was available on 2026-07-17.

## Hypothesis

A liquid-session M15 pullback through the current trading day's tick-volume-weighted anchored VWAP, followed by a directional reclaim candle, may provide a return source that is distinct from the released Band/VWAP reversion and E20 momentum lanes. Entries must agree with a bounded-ADX H1 50/200 EMA trend regime. Signals use completed bars only.

## Discovery data

- Model: MT5 Model 1 for fast screening only.
- Starting deposit: $10,000.
- Older era: 2015-01-01 through 2018-12-31.
- Later era: 2019-01-01 through 2020-12-31.
- Continuous era: 2015-01-01 through 2020-12-31.
- No data after 2020 may be opened unless the full neighborhood gate passes.

## Frozen promotion gate

All conditions are required:

- Net profit above $0 in both disjoint eras.
- Continuous net profit above $0.
- Continuous profit factor at least 1.30.
- At least 120 continuous trades.
- Continuous relative equity drawdown no more than 3.00%.
- At least two adjacent parameter variants pass the same broad-era direction gate.
- The winning result must not depend on one isolated side, session, or extreme parameter.

Any profile with a losing broad window is rejected. Passing discovery only permits a frozen 2021-2026 holdout and Model 4 validation; it does not permit promotion or live trading.

## Safety contract

- Risk per trade: 0.10%.
- No forced minimum lot when broker minimum would exceed the risk budget.
- Broker-native `OrderCalcProfit` sizing.
- Structure stop with ATR and absolute-distance caps.
- Daily loss, equity drawdown, consecutive-loss, cooldown, spread, position-count, and account-wide exposure controls remain enabled.
- Real-account trading remains disabled by default and requires an explicit source-specific acknowledgement.
- No martingale, grid, averaging down, or recovery sizing.
