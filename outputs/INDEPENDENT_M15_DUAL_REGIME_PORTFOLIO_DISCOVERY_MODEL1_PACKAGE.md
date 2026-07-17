# Independent M15 Dual-Regime Portfolio Discovery Package

Date-independent portfolio combining a trend-phase volatility-squeeze continuation lane with a range-phase volume-climax VWAP-reversion lane. No configuration includes data after 2020.

- Source SHA-256: `DEA3B16FB2D14E4A1253B422CCE80AEC4CB49DCF03067EDBCE96008F694FA5E1`
- Variants: `15`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `45`

The lanes share one position, daily-loss, drawdown, loss-streak, spread, and account-wide exposure manager. Lane-specific comments preserve lane-specific exits: VWAP-cross/mean-reversion management applies only to climax trades, while squeeze trades retain fixed-R/trend-failure management. Every stop rejects distances above `$6`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.

Frozen gate: Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and at least two adjacent dual-engine profiles must pass before opening 2021-2026. Engine-only controls are diagnostic and cannot be promoted.
