# Protected Momentum Winner Add-On Contract

**Status: RESEARCH ONLY. ATB150 AND THE FROZEN FORWARD CANDIDATE ARE UNCHANGED.**

- Never add to a losing or unprotected position.
- Require exactly one primary momentum position and zero existing add-ons.
- Require same-direction fresh H1 continuation plus unchanged D1 momentum agreement.
- Move the primary stop into profit before entry and require broker-valued locked profit to cover the add-on risk by the configured multiple.
- Use broker-aware risk sizing with minimum-lot refusal, a unique magic number, post-fill reconciliation, and the unchanged 0.75% portfolio open-risk cap.
- Permit one add-on maximum. No martingale, grid, averaging down, recovery sizing, or real-account trading.
- Reject on a losing discovery era, weak return/drawdown, missing adjacent support, identity mismatch, compiler warning, or safety violation.
