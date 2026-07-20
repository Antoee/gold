# Momentum Breakout-Failure Exit Discovery Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Use only the frozen disabled control, center (3 bars/0.05 ATR), timing neighbors (2 and 4 bars), and buffer neighbors (0.00 and 0.10 ATR).
- Require every report to remain profitable. Require the center to be no worse than control in both disjoint eras; continuous net at least 5% above control; CAGR at least 0.08 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.20% and no more than 0.08 point above control; trades at least control; and changed behavior.
- Require every neighbor to be no worse than control in both disjoint eras; continuous net at least 2% above control; CAGR at least 0.03 point above control; PF, recovery, and return/drawdown no worse than control; drawdown at most 1.25%; and changed behavior.
- Reject a losing window, inactive feature, isolated center, identity mismatch, compiler warning, safety failure, or any result needing post-result timing or buffer adjustment. Only the exact center may open a separately frozen 2021-2026 holdout.
- Exit decisions use completed H1 bars, exact-ticket ownership, the stored pre-break channel, and entry ATR. The exit cannot add risk or widen protection.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, period loss limits, lot refusal, post-fill reconciliation, and real-account lock unchanged.
- No martingale, grid, averaging down, recovery sizing, funding change, forward-candidate change, or real-account trading.
