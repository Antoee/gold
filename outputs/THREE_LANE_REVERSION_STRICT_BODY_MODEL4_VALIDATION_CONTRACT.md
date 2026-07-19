# Reversion Strict-Body Model 4 Validation Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- This is a separate fixed-profile execution validation and cannot amend the rejected Model 1 discovery or ladder contracts.
- Compare only the disabled-feature control with body ratio 0.25 and requested risk 0.70%; do not add a new threshold or risk rung.
- Change only the requested risk of an already-valid reversion entry when the completed H1 directional body ratio meets a frozen threshold; keep entry eligibility, initial stops, VWAP targets, exits, and both trend lanes unchanged.
- Use only completed signal-bar OHLC data. Never use current-bar data, future data, prior outcomes, drawdown, loss streaks, account profit, or calendar exclusions to qualify stronger risk.
- Never add to a position. Keep exact-ticket ownership, broker-valued sizing, maximum-lot refusal, exposure refusal, and post-fill reconciliation.
- Keep the 0.75% account-wide open-risk cap, 5% equity-drawdown cap, daily/weekly/monthly limits, initial stops, and post-fill reconciliation unchanged.
- Require all three disjoint eras and continuous 2015-2026 profitable, with candidate net no lower than control in any window.
- Require continuous candidate net at least 5% above control, CAGR at least 0.10 points above control, PF no lower than control, drawdown at most 1.35% and no more than 0.10 points above control, recovery and return/drawdown no lower than control, and at least 400 trades.
- Only a full pass may open annual restart, cost, and Monte Carlo validation. Reject any identity mismatch, compiler warning, missing report, safety failure, or post-result retuning.
- Reject an isolated winner, losing era, identity mismatch, compiler warning, safety failure, or any candidate that qualifies by relaxing these gates after results.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
