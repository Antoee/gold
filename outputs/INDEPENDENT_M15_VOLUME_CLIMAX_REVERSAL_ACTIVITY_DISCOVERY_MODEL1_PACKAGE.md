# Independent M15 Volume-Climax Reversal Activity Discovery Package

Final pre-holdout activity extension around the 1.30x volume lead. No configuration includes data after 2020.

- Source SHA-256: `914C5F3832D61DFD3AD2E4F885C70EFBF35E35B6CFFFFE1B8387EDA96AC56A36`
- Variants: `15`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `45`

The exact source is unchanged. This screen varies only volume activity, minimum range, local-extreme strictness, session width, per-day activity, and one ADX neighbor around the first-screen lead. The target remains the pre-signal daily VWAP capped by R and rejected below minimum RR. Stops remain beyond the climax wick, capped at `$6`, broker-sized at `0.10%` risk, with no forced minimum volume and real-account trading disabled.

Frozen gate: Final activity discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and an adjacent activity shape must pass before opening 2021-2026.
