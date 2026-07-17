# Early Failure Portfolio Discovery Contract

**Frozen before any post-2020 test.**

- Research source: `work/Professional_XAUUSD_Early_Failure_Portfolio.mq5`
- Source SHA-256: `2613BDF5BFCE4DB9220961540F851E2444F14AF17B690CAAE0AC4BE59C8C1342`
- Binary SHA-256: `1223D7AD626587B4F61EDD6FE7DDF705E98642CBE0733A48F02A83CED507D117`
- Compile: `0 errors, 0 warnings`
- Released source/profile remain unchanged.
- Entries, initial stops, targets, base risk, and portfolio guards remain identical to the released portfolio.
- New logic may only close a position after a configured number of completed H1 bars when current profit has not exceeded a configured R threshold.
- No exit may widen risk, add size, or raise the shared `0.75%` open-risk cap.

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
2. Both disjoint eras must be profitable for an exit profile; the unchanged control is diagnostic only.
3. Continuous PF must be at least `1.45`, trades at least `180`, and max equity drawdown no more than `2.80%`.
4. A profile must improve fixed-control return/drawdown by at least `5%`, or improve net by at least `5%` with PF and drawdown no worse than control.
5. At least one adjacent exit setting must independently pass the same quality gate.
6. Any loss in 2019-2020 closes holdout and Model 4 for that profile.

Passing discovery would authorize an untouched `2021-2026 YTD` Model 1 holdout only. It would not authorize promotion, live trading, or changes to the frozen forward candidate.
