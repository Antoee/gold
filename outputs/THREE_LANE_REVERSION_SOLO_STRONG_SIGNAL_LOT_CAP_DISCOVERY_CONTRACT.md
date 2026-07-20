# Portfolio-Solo Strong Reversion Lot-Cap Discovery Contract

**Status: PREREGISTERED PRE-2021 CODE RESEARCH. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**

- Research source SHA-256: `726BCABFA64C25FA3D22E78B41AB4868EA8D5235609294F7ED68DC3DB9088EEE`
- Exact leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Manifest SHA-256: `43CD328E044F37AFEB51A0021F0119F60910C6AABB455C269580D68D218EE509`

- Nomination used only the pre-2021 leader ledger: five current 0.15-lot strong reversion trades entered without another managed lane open; aggregate +$402.42, with positive older and discovery eras. This is weak sample support, not proof.
- The switch is disabled by default. Enabled rows may raise only the existing strong-signal lot cap when no momentum or adaptive-trend position is open. Entry, stop, target, signal threshold, requested risk, trade count logic, and exits are unchanged.
- Requested reversion risk remains 0.45%; account open risk remains capped at 0.75%. The 0.17 / fixed 0.18 / 0.19 neighborhood and 0.20 boundary were frozen before testing.
- Discovery only. Fixed 0.18 solo cap must be profitable, improve both disjoint eras by at least 3%, improve continuous net by at least 4.5% and CAGR by 0.08 point, keep exact trade count, keep PF/recovery/return-to-drawdown no worse, and keep DD <=1.25% and <=control+0.10 point. At least one 0.17 or 0.19 neighbor must improve both eras, continuous net >=3%, CAGR >=0.05 point, retain PF/recovery/return-DD >=98%, exact trades, and the same DD limit. No alternate-center selection or threshold rescue after observation.
- Reject losing broad windows, identity mismatch, compiler warning, safety failure, isolated center, or any result needing a new cap/threshold after observation. Only the exact 0.18 center may open a separately frozen post-2020 gate.
- No martingale, grid, averaging down, recovery sizing, capital change, forward substitution, or real-account trading.
