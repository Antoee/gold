# Reversion Strong-Signal Tick Protection Model 1 Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- This is a new data-informed code follow-up and cannot amend or reverse any rejected strong-signal or break-even contract.
- Freeze completed-H1 directional body ratio at 0.25 and requested strong risk at 0.70%. Test only disabled control, strong-only control, and protection rows 1.00R/0.05R, 1.00R/0.10R, and 1.25R/0.10R.
- Use only completed signal-bar OHLC at entry, exact stored initial risk, and current executable bid/ask on every management tick. Never use future data, prior outcomes, drawdown, loss streaks, account profit, or calendar exclusions.
- Never add to a position. Keep exact-ticket ownership, broker-valued sizing, maximum-lot refusal, exposure refusal, and post-fill reconciliation.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.
- Require the 1.00R/0.10R center to change at least one trading metric, match or beat disabled control net in every era, produce continuous net at least 5% above disabled control and at least 97% of strong-only, keep CAGR at least 0.10 points above disabled control and no more than 0.03 points below strong-only, keep PF/recovery/return-drawdown no worse than strong-only, drawdown no worse than strong-only and at most 1.25%, and at least 400 continuous trades.
- Require both protection neighbors to change at least one trading metric, match or beat disabled control in every era, produce continuous net at least 3% above disabled control, CAGR at least 0.05 points above disabled control, PF/recovery/return-drawdown no worse than disabled control, drawdown at most 1.25%, and at least 400 trades.
- Reject an isolated winner, losing era, identity mismatch, compiler warning, safety failure, or any candidate that qualifies by relaxing these gates after results.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
