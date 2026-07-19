# Residual-Risk V2 Reversion-Focus Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Keep entry and exit signals unchanged.
- Never add to an existing position and never use prior outcomes, drawdown, or loss streaks to size a trade.
- Compute expansion only from current broker-valued account-wide protected risk, a fixed reserve, and a fixed per-lane ceiling.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.
- Require every disjoint era profitable, CAGR at least 0.25 points above control, PF at least 1.75, drawdown at most 1.50%, no loss of recovery or return/drawdown, and at least three adjacent supporting ceilings.
- Reject any profile with a changed trade universe, losing broad era, weak PF, poor return/drawdown, identity mismatch, compiler warning, or safety failure.
- Pre-parse clarification: the generated queue's `404-or-fewer` wording copied the Model 4 control count. For this Model 1 screen, `unchanged trade universe` means no additional trades versus the exact Model 1 control; this correction was recorded before performance reports were parsed.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
