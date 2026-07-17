# Two-Bar Confirmation Portfolio Discovery Contract

**Frozen before any post-2020 test.**

- Research source: `work/Professional_XAUUSD_Two_Bar_Confirmation_Portfolio.mq5`
- Source SHA-256: `A5462DA021E57A8FB42BA6344D89BE366204130DE1A47957F5EF988861DAD133`
- Binary SHA-256: `DA290BEF0CC72B2F1947C9EF98710189D1021A570BEC6E9CB4B8D6E79CA4BD11`
- Compile: `0 errors, 0 warnings`
- Released source/profile remain unchanged.
- Risk sizing, stops, targets, position management, and portfolio guards remain identical to the released portfolio.
- Reversion confirmation requires a completed prior-bar band extension followed by a completed reclaim bar.
- Momentum confirmation requires a completed channel breakout followed by a second completed close that remains beyond the same channel.
- Optional progress settings require the confirmation close to advance beyond the first setup close.

## Discovery Data

- Model: MT5 Model 1
- Symbol/timeframe: XAUUSD H1
- Starting balance: `$10,000`
- Older era: `2015-01-01` through `2018-12-31`
- Later discovery era: `2019-01-01` through `2020-12-31`
- Continuous discovery: `2015-01-01` through `2020-12-31`
- No post-2020 data may be opened unless the gate below passes.

## Frozen Gate

1. All 24 reports must match the frozen source and profile identities.
2. Both disjoint eras must be profitable for a confirmation profile; the unchanged control is diagnostic only.
3. Continuous PF must be at least `1.45`, trades at least `180`, and max equity drawdown no more than `2.80%`.
4. A profile must improve fixed-control return/drawdown by at least `5%`, or improve net by at least `5%` with PF and drawdown no worse than control.
5. At least one adjacent confirmation setting must independently pass the same quality gate.
6. Any loss in 2019-2020 closes holdout and Model 4 for that profile.

Passing discovery would authorize an untouched `2021-2026 YTD` Model 1 holdout only. It would not authorize promotion, live trading, or changes to the frozen forward candidate.
