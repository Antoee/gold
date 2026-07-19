# RDMC Hard Lane Risk v4 Contract

**NEW RESEARCH IDENTITY. ZERO INHERITED PROFIT, ZERO FORWARD EVIDENCE, AND NO REAL-MONEY APPROVAL.**

## Frozen Identity

- Source SHA-256: `7A6CA3C9E9644656A0CDC64A6D078B446FB1A9981B16CDE727E65B13A5C06831`
- Profile SHA-256: `224801DB7A02F2C54C3070ABB190187EA8C73FC7181CDD07BA33040025A2922B`
- Binary SHA-256: `7E354482E8D69F1E0F878DB4AF34943C04EF3D911FAC48CCC6104BD8B17E5D7C`
- Manifest SHA-256: `636CCDBB66A43BFEDA99BBE7007A363CF666E92FB8AF2B5CB8B23A9B0C024E1C`
- Explicit profile inputs: `601`
- Starting capital: `$10,000 USD`
- First admissible tests: Model1 2019 and 2022 only

## Mechanism Rewrite

This identity closes the v3 risk leak with a broker-valued lot ceiling applied after shared dynamic sizing and reapplied after each primary margin adjustment. The cap never forces the broker minimum lot when that minimum would exceed the ceiling.

- MTSM absolute ceiling: `0.10%` of current equity.
- Shared primary-lane absolute ceiling: `0.25%` of current equity.
- RRO and DDB ceiling: base `0.50%` risk multiplied by their bounded signal-specific risk multiplier.
- Primary feasibility multiplier: `0.50`, chosen so the smallest XAUUSD lot can fit the August/no-cushion DGF budget while remaining bounded by the `0.25%` hard ceiling.
- Portfolio-wide exposure, daily/weekly/monthly loss, drawdown, margin, spread, funding, dedicated-account, persistence, and real-account locks are unchanged.

## Fail-Closed Gate

Both 2019 and 2022 must have positive net, PF at least `1.05`, meet the frozen 15/20-trade activity floors, and remain below `3%` drawdown. One failed row terminally rejects the exact identity and prohibits later Model1 or Model4 waves.
