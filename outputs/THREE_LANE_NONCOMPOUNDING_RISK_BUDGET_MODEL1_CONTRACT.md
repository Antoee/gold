# Three-Lane Noncompounding Risk-Budget Model 1 Contract

**Status: RESEARCH ONLY. NO PROMOTION OR REAL TRADING IS AUTHORIZED.**

- Test exactly four fixed profiles: champion control, budget only, strong risk only, and strong risk plus budget.
- Freeze strong-signal body ratio at 0.25 and requested risk at 0.70%; do not add another threshold or risk rung.
- The budget may only replace sizing equity with min(current equity, expected initial balance). It may never increase risk after profit or loss.
- Keep signals, entries, initial stops, targets, exits, lot caps, exact-ticket ownership, minimum-lot refusal, post-fill reconciliation, and all account-wide limits unchanged.
- Require every profile/window profitable and strong+budget net no lower than control in any disjoint era.
- Require strong+budget continuous net at least 5% above control, CAGR at least 0.08 points above control, PF no lower than control, DD at most 1.25% and no more than 0.05 points above control, recovery and return/drawdown no lower than control, and at least 400 trades.
- Only a full Model 1 pass may open the same fixed profiles on Model 4 real ticks.
- Reject identity mismatch, compiler warning, missing report, losing era, isolated growth, or any post-result retuning.
- No martingale, grid, averaging down, recovery sizing, funding changes, forward-candidate changes, or real-account trading.
