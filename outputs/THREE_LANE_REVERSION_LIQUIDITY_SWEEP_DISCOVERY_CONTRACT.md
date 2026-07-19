# Reversion Liquidity-Sweep Discovery Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Change only the optional reversion liquidity-sweep confirmation; keep every exit and both trend-lane entries unchanged.
- Use the completed H1 signal bar and bars beginning at shift 2; no current-bar data, future data, or outcome-dependent inputs.
- Never add to a position and never use prior outcomes, drawdown, or loss streaks to size a trade.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.
- Require every disjoint era profitable, continuous CAGR at least 0.15 points above control, PF at least 1.85, drawdown at most 1.20%, no loss of recovery or return/drawdown, and at least 390 continuous trades.
- Require support from a neighboring lookback or sweep threshold; reject an isolated winner, a losing era, identity mismatch, compiler warning, or safety failure.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
