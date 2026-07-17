# Market Phase Portfolio Discovery Contract

**Frozen before any post-2020 test.**

- Research source: `work/Professional_XAUUSD_Market_Phase_Portfolio.mq5`
- Source SHA-256: `78F43A8281B213FBE82AF592F9876FBC4545BAA1DA62D61565CA0AA56375E8BF`
- Binary SHA-256: `122E9ECFDA1A7EC4B883B3EE4AFDFCF3CC729D99071D16F6749C3209F9DE83D6`
- Compile: `0 errors, 0 warnings`
- Released source/profile remain unchanged.
- Entry and exit rules remain identical to the released Band/VWAP reversion plus E20 momentum portfolio.
- The only behavioral change is a closed-H1-bar efficiency-ratio controller that can reduce, but never increase, hostile-phase lane risk.
- Base lane risks remain `0.45%` reversion and `0.15%` momentum; the shared open-risk cap remains `0.75%`.

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
2. Both disjoint eras must be profitable for an adaptive profile; the fixed-risk control is diagnostic only.
3. Continuous PF must be at least `1.45`, trades at least `180`, and max equity drawdown no more than `2.80%`.
4. The adaptive profile must improve fixed-control return/drawdown by at least `5%`, or improve net by at least `5%` with PF and drawdown no worse than control.
5. At least one adjacent adaptive setting must independently pass the same quality gate.
6. Any loss in 2019-2020 closes holdout and Model 4 for that profile.

Passing discovery would authorize an untouched `2021-2026 YTD` Model 1 holdout only. It would not authorize promotion, live trading, or changes to the frozen forward candidate.
