# Independent M15 ADR-Exhaustion Reversion Discovery Package

Frozen pre-2021 screen of an intraday ADR-exhaustion and daily-VWAP reversion hypothesis. No configuration includes data after 2020.

- Source SHA-256: `3965C11212CC615675F13118E711F6D62805218124FC0A707EBE838DD446E281`
- Variants: `11`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `33`

The matrix changes one factor at a time around the center: day-range exhaustion, directional extension, volume confirmation, ADX ceiling, wick shape, or minimum payoff. The target is the pre-signal daily VWAP capped by R. Stops remain beyond the rejection wick, capped at `$8`, broker-sized at `0.10%` risk, with minimum-lot overflow refused and real-account trading disabled.

Frozen gate: Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 80, DD <= 3%, positive payoff and return/DD >= 1.0, with an adjacent one-factor shape passing before opening 2021-2026.
