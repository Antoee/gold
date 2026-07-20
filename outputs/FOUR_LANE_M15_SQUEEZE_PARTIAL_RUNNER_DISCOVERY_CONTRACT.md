# Four-Lane M15 Squeeze Partial-Runner Discovery Contract

**Status: PREREGISTERED PRE-2021 CODE RESEARCH. THE PUBLISHED LEADER AND FROZEN FORWARD CANDIDATE ARE UNCHANGED.**

- Research source SHA-256: `1E05D5E8A9283EC34EC9F8116E21C363E4D100BE782065E87DDDC90CCC3E6005`
- Exact leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Integrated squeeze reference decision SHA-256: `8263EE47CA4BD74160BBE93B28BCF695DF641C9E60AF296C7B7FD6CEDD8A03DF`
- Manifest SHA-256: `A6BA5855A67F090B20CC9E895EC81070402DE75F3E01D6011FE32663F6FD266E`

- Frozen center: eligible squeeze positions bank 80% at +1.50R only after locking the remainder at +1.25R; the remainder targets +4.00R. Unsplittable positions retain the original +1.50R target.
- Frozen one-factor neighborhood: close 70/90%, runner target +3.00/+5.00R, and stop lock +1.00/+1.40R. Trigger, entries, stops, initial risk, portfolio limits, and all other settings remain fixed.
- State is persisted by owned position identifier. A restart cannot replay the partial close. Stop protection is confirmed before any partial close; state or execution ambiguity fails closed.
- Pre-2021 discovery only. Exact leader control and active 1.50R squeeze reference must reproduce prior results. Every report must be profitable. Fixed 80%/4R/+1.25R center must be no worse than the active reference in both disjoint eras, improve continuous net >=3% and CAGR >=0.08 point, retain PF >=98% of leader control, recovery and return/drawdown >=active reference, keep DD <=1.30% and <=reference+0.15 point, and produce 380-450 report trades. At least three of six one-factor neighbors must retain >=98% of reference net in both eras, improve continuous net >=1%, retain PF >=98% of leader control and recovery/return-DD >=98% of reference, and meet the same DD/activity limits. No alternate center, threshold rescue, or post-result parameter selection.
- Reject identity mismatch, compiler warning, losing broad window, inactive runner, efficiency failure, isolated center, or any result needing a changed threshold. Only the exact frozen center may open a separately frozen post-2020 gate.
- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, capital change, forward substitution, or real-account trading.
