# Residual-Risk Allocation Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Keep entry and exit signals unchanged.
- Never add to an existing position and never use prior outcomes, drawdown, or loss streaks to size a trade.
- Compute expansion only from current broker-valued account-wide protected risk, a fixed reserve, and a fixed per-lane ceiling.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.
- Reject any profile with a losing broad era, weak PF, poor return/drawdown, identity mismatch, compiler warning, or safety failure.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
