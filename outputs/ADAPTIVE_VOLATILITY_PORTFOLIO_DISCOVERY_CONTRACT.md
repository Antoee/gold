# Adaptive Volatility Portfolio Discovery Contract

Frozen before any strategy-tester result for this source was inspected.

- Source: `work/Professional_XAUUSD_Adaptive_Volatility_Portfolio.mq5`
- Source SHA-256: `EE792939C2E50CED18DA0F5B2E885FB30F14ED58CA97AFB92CA553F6AC4C1229`
- Compile: `0 errors, 0 warnings`
- Starting balance: `$10,000`
- Tester model: Model 1 discovery only
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Post-2020 strategy data remains closed until the discovery decision is frozen.
- The released transferable portfolio and its forward-demo identities remain unchanged.

## Architecture

The fork retains the exact H1 Band/VWAP-reversion and E20 multiscale-momentum entry and exit rules. Requested lane risk is multiplied by the ratio of prior average ATR/price to the last closed-bar ATR/price. Scaling uses closed H1 data only and is bounded. The center range is `0.75x-1.25x`; base lane risk totals `0.60%`, so maximum requested risk remains inside the existing `0.75%` portfolio open-risk cap.

The fixed-risk profile is a diagnostic control and cannot be promoted as a new strategy.

## Frozen Gate

An adaptive profile may open the untouched holdout only if:

1. Both disjoint discovery eras are profitable.
2. Continuous PF is at least `1.35`, trades are at least `180`, and maximum equity drawdown is at most `5%`.
3. It improves continuous return/drawdown efficiency over the fixed-risk control by at least `5%`, or improves net profit by at least `5%` while drawdown is no more than `10%` worse and PF falls by no more than `0.05`.
4. At least one adjacent adaptive profile passes the same broad-era, PF, activity, and drawdown gates.
5. No real-account lock, minimum-lot rejection, daily-loss guard, equity guard, or account-wide exposure guard is weakened.

If no adaptive profile passes, the branch is rejected before holdout and Model 4. No threshold may be moved after results are seen.
