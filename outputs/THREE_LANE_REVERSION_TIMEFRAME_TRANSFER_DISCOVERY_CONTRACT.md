# Reversion Timeframe-Transfer Discovery Contract

**Status: PREREGISTERED PRE-2021 RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**

- Source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- Leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Manifest SHA-256: `F691742DDFC5AA980F0395D8D9B41B77B3F676977CD3C6B99E6648672A206F10`

- The exact leader source is used with momentum and adaptive-trend lanes disabled so only band/VWAP reversion is measured.
- H1 is the isolated control. M30 and H2 each have fixed local-bar, midpoint, and elapsed-duration-normalized interpretations.
- Requested reversion risk remains 0.45%, portfolio open risk remains capped at 0.75%, and untradable minimum volume is refused.
- Discovery only. A timeframe family may open post-2020 holdout only when at least two of its three fixed horizon interpretations are profitable in both disjoint eras, continuous PF >= 1.50, at least 24 trades, DD <= 1.50%, recovery >= 2.0, and at least one supported row improves isolated-H1 continuous net by >= 10% and CAGR by >= 0.10 point without fewer trades. No threshold rescue, risk increase, minimum-lot forcing, or Model 4 run after failure.
- No martingale, grid, averaging down, recovery sizing, outcome-conditioned behavior, capital change, forward substitution, or real-account trading.
