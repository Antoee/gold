# Four-Lane M15 Squeeze Target Interaction Contract

**Status: PREREGISTERED PRE-2021 SETTINGS INTERACTION. THE PUBLISHED LEADER AND FORWARD CANDIDATE ARE UNCHANGED.**

- Research source SHA-256: `5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6`
- Exact leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Prior integration decision SHA-256: `8263EE47CA4BD74160BBE93B28BCF695DF641C9E60AF296C7B7FD6CEDD8A03DF`
- Exact integrated trade ledger SHA-256: `402216282F464C9E1BA5DFC4A81DBF94CAD44D56C74985D852FE6D634B0C84CC`
- Independent squeeze decision SHA-256: `FA92B99DE4AF5F6F8E2357CECD89893E50DD0156B696D5714DEAAE3EBDD8E821`
- Manifest SHA-256: `770B30C810054928F02E04ECE6FA8ADA3279D71D7DBD32C57F3B9608CC33695E`

- The prior integrated 1.50R lane added 88 pre-2021 trades, +$209.91, PF 1.4954, and positive net in both eras, but portfolio PF retained only 94.68% of control. Separately, the original one-factor standalone matrix found 2.00R improved net and PF over its 1.50R center. Their eight-bar plus 2.00R interaction has not been tested before this freeze.
- Entry, squeeze, trend, stop, break-even, session, risk, lot, account-cap, loss-limit, capital-contract, and real-account settings are unchanged. Only the fixed squeeze target is bracketed.
- Discovery only. Both disabled controls and the enabled 1.50R reference must exactly reproduce their prior identities. Fixed 2.00R center must be profitable and no worse than leader control in each disjoint era, improve continuous net >=10% and CAGR >=0.20 point, retain PF >=98% of control, recovery and return/drawdown >=control, keep DD <=1.30% and <=control+0.15 point, and retain >=300 trades. At least one 1.75R or 2.25R neighbor must be no worse than control in both eras, improve net >=8% and CAGR >=0.15 point, retain PF/recovery/return-DD >=98% of control, meet the same DD and activity limits, and differ from the 1.50R reference. No alternate target selection or threshold rescue after observation.
- Reject any identity mismatch, control/reference mismatch, losing era, efficiency failure, isolated center, or result needing a new target after observation. Only the exact 2.00R center may open a separately frozen post-2020 gate.
- No martingale, grid, averaging down, recovery sizing, capital change, forward substitution, or real-account trading.
