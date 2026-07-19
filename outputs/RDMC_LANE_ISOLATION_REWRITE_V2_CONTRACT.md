# RDMC Lane Isolation Rewrite v2 Contract

**NEW RESEARCH IDENTITY. ZERO INHERITED PROFIT, ZERO FORWARD EVIDENCE, AND NO REAL-MONEY APPROVAL.**

## Frozen Identity

- Source SHA-256: `1376E383DBB4A040DBC14337EA736DBFA4417C3B5D36DD629205665B9B81E569`
- Profile SHA-256: `6C01552D24702869C9E950846D96A74469E958B08E5D176FA34792D44D9224F0`
- Binary SHA-256: `818A94C0CAEF9A9C438297134CD15B97DD3FCEAEAA9367C756A2A8C34A2A1868`
- Manifest SHA-256: `24F5B32D6F12740E763DC3BA4B14F0BBA5E892381D46EE33190C4C0F320756F7`
- Explicit profile inputs: `600`
- Starting capital: `$10,000 USD`
- First admissible tests: Model1 2019 and 2022 only

## Mechanism Rewrite

The rejected v1 identity isolated MTSM from primary soft-loss state but still let isolated RRO and DDB exits feed primary soft performance and loss-streak sizing. Shared basket-profit and partial-harvest logic also included those positions before lane-specific management checks.

This identity changes those ownership boundaries without weakening account-wide protection:

- RRO and DDB bypass primary soft loss gates and loss-streak lot scaling.
- Proven RRO/DDB entry comments are excluded from primary recent-performance, direction/hour, profit-factor, and consecutive-loss samples.
- Shared basket-profit and partial-harvest logic excludes isolated RRO/DDB positions.
- Daily, weekly, monthly, drawdown, margin, spread, exposure, funding, dedicated-account, persistence, and real-account locks remain portfolio-wide.
- The v1 fast-momentum, breakout-candle, and tick-volume filters are disabled because they reduced MTSM to 4/5 trades in the critical years without positive economics.
- MTSM requested risk is reduced from `0.15%` to `0.10%`; primary risk remains unchanged.

## Fail-Closed Gate

Both 2019 and 2022 must have positive net, PF at least `1.05`, meet the frozen 15/20-trade activity floors, and remain below `3%` drawdown. A hard economic failure terminally rejects the exact identity and requires another code rewrite.
