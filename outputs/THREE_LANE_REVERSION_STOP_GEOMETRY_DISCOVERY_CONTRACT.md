# Reversion Stop-Geometry Discovery Contract

**Status: PREREGISTERED PRE-2021 SETTINGS RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**

- Exact leader source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- Exact leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Manifest SHA-256: `46D835F3DB082AEA00A7B79374F289D7AB8FFE31018049896241EAA49F4155DC`

- Only the reversion structural-stop lookback changes. The signal, stop buffer, VWAP target, requested risk, selective lot cap, other lanes, and every account protection remain exact leader settings.
- The fixed center uses the signal candle plus two prior completed H1 bars; 2 and 4 bars are adjacent support rows; 5 bars is exact control; 6 bars is a wider boundary.
- Discovery only. The 3-bar center must be positive and retain at least 98% of exact-control net in both disjoint eras, improve continuous net by at least 5% and CAGR by 0.10 point, keep PF/recovery/return-to-drawdown no worse, keep drawdown <=1.25% and <=control+0.10 point, and retain at least 98% of control trades. At least one adjacent 2- or 4-bar row must independently retain both eras and trades, improve net >=3% and CAGR >=0.05 point, and keep efficiency no worse. No alternate-center selection, threshold rescue, holdout, or Model 4 after failure.
- No martingale, grid, averaging down, recovery sizing, outcome conditioning, capital change, forward substitution, or real-account trading.
