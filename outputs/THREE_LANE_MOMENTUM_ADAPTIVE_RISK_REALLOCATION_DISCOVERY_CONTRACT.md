# Momentum-Adaptive Risk Reallocation Discovery Contract

**Status: PREREGISTERED PRE-2021 RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**

- Source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- Leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Manifest SHA-256: `1A22157C6C27F4DF07B7FF82B4AC8100A5D785DC212169EBD9A8E3137D1CC938`

- Frozen ladder moves risk only between momentum and adaptive-breakout lanes. Reversion remains 0.45% and the account-wide cap remains 0.75%.
- Control is the exact published leader allocation: momentum 0.15%, adaptive 0.15%. Center is momentum 0.20%, adaptive 0.10%.
- Frozen pre-2021 settings-only risk reallocation. Every row and both disjoint eras must remain profitable. Center must be no worse than control in both eras; continuous net >=control +5%; CAGR >=control +0.08 point; PF/recovery/return-DD >=97% control; DD <=min(1.30%, control +0.20 point); trades >=98% control. At least 2 of 3 lower rungs must retain both era controls, improve continuous net >=2%, retain 97% efficiency, meet the same drawdown ceiling, retain 98% of trades, and change behavior. No post-result rescue.
- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, capital change, forward substitution, or real-account trading.
