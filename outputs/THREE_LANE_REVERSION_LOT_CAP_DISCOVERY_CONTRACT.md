# Three-Lane Reversion Lot-Cap Discovery Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Freeze exact ATB150 source/profile identity and the 0.10 / 0.12 / 0.15 / 0.18 / 0.20 lot-cap ladder before testing.
- The 0.15 center must be no worse than control in both disjoint eras; improve continuous net by at least 6% and CAGR by at least 0.10 point; retain at least 95% of control PF, recovery, and return/drawdown; keep drawdown at or below 1.35% and no more than 0.20 point above control; keep at least control trades minus two; and change behavior.
- Both 0.12 and 0.18 neighbors must be no worse than control in both disjoint eras; improve continuous net by at least 3% and CAGR by at least 0.05 point; retain at least 93% of control PF, recovery, and return/drawdown; keep drawdown at or below 1.35%; and change behavior.
- The 0.20 stress row must remain profitable in every window, retain at least 85% of control recovery and return/drawdown, and keep drawdown at or below 1.50%.
- Reject any losing window, isolated center, identity mismatch, compiler warning, safety failure, or result needing a different cap after observation. Only the exact frozen center may advance to a separately frozen recent-data gate.
- Change only InpRVMaximumPositionLots. Keep requested reversion risk at 0.45%, momentum and adaptive-trend risk at 0.15%, total open risk at 0.75%, expected capital at $10,000, minimum-lot refusal, post-fill reconciliation, initial stops, targets, exits, period loss limits, and the 5% equity guard unchanged.
- No martingale, grid, averaging down, recovery sizing, account-profit sizing, funding change, forward-candidate change, or real-account trading.
