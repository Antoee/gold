# RDMC Money-Ready Gate Repair Equivalence

**PASS.** The candidate source normalizes byte-for-byte to the frozen source after reversing only the version marker and the readiness predicate.

- Source identity: `104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8`
- Static readiness: `63/63` pass
- Adversarial Band/VWAP bounds rejected: `13/13`
- Loss-state truth-table rows: `21`
- Valid timestamp states changed: `0`
- Previously blocked states newly allowed: `0`
- Missing-timestamp states made stricter: `2`

The threshold change from four to two is behaviorally equal whenever the frozen loss timestamp is present because the same 240-minute generic cooldown runs after every loss. At missing timestamps with streaks two or three, the new profile blocks instead of allowing another trade.

Every conditional Band/VWAP safety input was perturbed across its boundary one at a time. All 13 negative cases were refused by `band-vwap-reversion-safety-contract`; disabling the lane remained valid. This is static equivalence and fail-closed admission evidence only, not MT5 performance evidence.
