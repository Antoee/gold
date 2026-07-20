# Three-Lane Momentum Ridge-Quality Offline Contract

Frozen before running the score on `2026-07-19`.

- Evidence input: exact pre-2023 momentum telemetry matched to the ATB150 Model 4 trade ledger.
- Telemetry SHA-256: `EA2A0DB1C38E890291785BB0B474B80586D71352C32EA7C55E7A11D1B698365C`.
- ATB150 trade-ledger SHA-256: `D784E3F4289E989DDA2E6C686C80A20086825A6586355AFA8556021486373E69`.
- Features: channel width/ATR, breakout/ATR, H1 efficiency, D1 efficiency, absolute D1 momentum percent, ATR percent, body ratio, close location, range/ATR, volume ratio, and stop/ATR.
- Target: exact ATB150 realized `R` for the matched momentum trade.
- Model: standardized linear ridge regression with an unpenalized intercept and fixed penalty `25.0`.
- Chronology: train 2015-2016/test 2017-2018; train 2015-2018/test 2019-2020; train 2015-2020/test 2021-2022.
- Center rule: retain scores at or above the training-score 25th percentile.
- Frozen neighbors: training-score 20th and 30th percentiles.
- The score may only suppress an otherwise valid momentum entry. It cannot add a trade, raise risk, alter a stop/target/exit, or inspect current-bar, future, calendar-exception, account-profit, or prior-outcome data.

## Offline Gate

The center must:

1. Retain at least 65% of matched momentum trades in every validation fold.
2. Rank retained momentum trades above removed trades by average realized R in every fold.
3. Keep the complete portfolio profitable in every validation fold and every validation year.
4. Produce portfolio net no worse than control in each fold and at least 5% better in aggregate.
5. Produce aggregate portfolio PF no worse than control.
6. Leave 2019 and 2022 portfolio net no worse than control.

Each neighbor must retain at least 60% in every fold, keep every validation fold/year profitable, retain at least 98% of control net in each fold, improve aggregate net by at least 2%, and produce PF no worse than control.

Every center and neighbor gate must pass before an MQL implementation is permitted. Passing this offline screen would authorize only a default-off implementation and compile/static audit. It would not open 2023-2026, Model 4, promotion, forward substitution, or real-account trading.

No ridge penalty, feature, percentile, fold, or gate may be changed after seeing the result. If the screen fails, this score family is rejected without an alternate model or threshold search on these trades.
