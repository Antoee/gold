# Reversion Break-Even Discovery Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Change only the optional reversion break-even stop manager; keep entries, initial stops, VWAP targets, and both trend lanes unchanged.
- Evaluate once per new H1 bar and only tighten an exact-ticket owned stop; never widen risk or add a close path.
- Never add to a position and never use prior outcomes, drawdown, or loss streaks to size a trade.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.
- Require every disjoint era profitable, continuous CAGR at least 0.15 points above control, PF at least 1.85, drawdown no worse than control, no loss of recovery or return/drawdown, and at least 400 continuous trades.
- Require support from an adjacent trigger or lock setting; reject an isolated winner, a losing era, identity mismatch, compiler warning, or safety failure.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
